const db = require('../config/db');

/* -------------------------- helpers -------------------------- */

// Round to 2 decimal places using banker's rounding (like Excel)
function to2(n) {
  return Math.round((Number(n) || 0) * 100) / 100;
}

// Truncate to integer (for penalty calculations)
function toInt(n) {
  return Math.floor(Number(n) || 0);
}

function normalizeFuel(f) {
  if (f == null) return null;
  const x = String(f).trim().toUpperCase();
  if (x === 'DIEDEL' || x === 'DEISEL') return 'DIESEL';
  if (x === 'DIESEL AUTO') return 'DIESEL';
  if (x === 'PETROL 92') return 'PETROL';
  return x;
}

function normalizeServiceType(rateType, serviceType) {
  if (!serviceType) return serviceType;
  const s = String(serviceType).trim();
  if (String(rateType).toUpperCase() === 'DAILY') {
    if (!s.startsWith('Short Term_')) return `Short Term_${s}`;
  }
  return s;
}

function parseNominalBounds(kmSlab) {
  const s = String(kmSlab || '').toLowerCase().trim();

  if (s.includes('daily')) {
    const m = s.match(/(\d+)/);
    return { type: 'DAILY', lower: 0, upper: m ? Number(m[1]) : 100 };
  }

  if (s.includes('upto') || s.includes('up to')) {
    const m = s.match(/(\d+)/);
    return { type: 'UPTO', lower: 0, upper: m ? Number(m[1]) : Infinity };
  }

  if (s.includes('above')) {
    const m = s.match(/(\d+)/);
    const base = m ? Number(m[1]) : 0;
    return { type: 'ABOVE', lower: base + 1, upper: Infinity };
  }

  const r = s.match(/(\d+)\s*-\s*(\d+)/);
  if (r) return { type: 'RANGE', lower: Number(r[1]), upper: Number(r[2]) };

  return { type: 'UNKNOWN', lower: 0, upper: Infinity };
}

function buildOrdered(slabs) {
  return slabs
    .map(s => ({ ...s, nominal: parseNominalBounds(s.km_slab) }))
    .sort((a, b) => {
      const au = a.nominal.upper === Infinity ? Number.MAX_SAFE_INTEGER : a.nominal.upper;
      const bu = b.nominal.upper === Infinity ? Number.MAX_SAFE_INTEGER : b.nominal.upper;
      return au - bu;
    });
}

function allowedUpper(nominalUpper) {
  if (!isFinite(nominalUpper)) return Infinity;
  return Number(nominalUpper) + Math.round(Number(nominalUpper) * 15 / 100);
}

/* --------------------------- DB ------------------------------ */

async function getSlabs(calculatedCardId, categoryCode, yomCategory, serviceType, fuelType, rateType = 'Monthly') {
  const rt = String(rateType || 'Monthly');
  const ft = normalizeFuel(fuelType);
  const st = normalizeServiceType(rt, serviceType);

  const runQuery = async ({ useFuel = true, customServiceType = st }) => {
    let sql = `
      SELECT id, calculated_card_id, category_code, yom_category, km_slab, max_distance,
             monthly_rental, additional_km_rate, overtime_rate, night_allowance,
             rate_type, service_type, fuel_type, created_at
      FROM calculated_rate_slabs
      WHERE calculated_card_id = ?
        AND category_code = ?
        AND yom_category = ?
        AND service_type = ?
        AND rate_type = ?`;
    const params = [calculatedCardId, categoryCode, yomCategory, customServiceType, rt];

    if (useFuel) {
      if (ft == null) {
        sql += ` AND (fuel_type IS NULL OR fuel_type = '')`;
      } else {
        sql += ` AND UPPER(fuel_type) = ?`;
        params.push(ft);
      }
    }

    sql += ` ORDER BY max_distance ASC`;
    const [rows] = await db.execute(sql, params);
    return rows;
  };

  let rows = await runQuery({ useFuel: true, customServiceType: st });

  if ((!rows || rows.length === 0) && String(rt).toUpperCase() === 'DAILY' && st.startsWith('Short Term_')) {
    const st2 = st.replace(/^Short Term_/, '');
    rows = await runQuery({ useFuel: true, customServiceType: st2 });
  }

  if (!rows || rows.length === 0) {
    rows = await runQuery({ useFuel: false, customServiceType: st });
    if ((!rows || rows.length === 0) && String(rt).toUpperCase() === 'DAILY' && st.startsWith('Short Term_')) {
      const st2 = st.replace(/^Short Term_/, '');
      rows = await runQuery({ useFuel: false, customServiceType: st2 });
    }
  }

  return (rows || []).map(r => ({
    ...r,
    max_distance: Number(r.max_distance),
    monthly_rental: Number(r.monthly_rental),
    additional_km_rate: Number(r.additional_km_rate),
    overtime_rate: Number(r.overtime_rate),
    night_allowance: Number(r.night_allowance),
  }));
}

/* ------------------------ core compute ------------------------ */

function monthlyCostForSlab(
  kmRun,
  billingDays,
  workingDays,
  overtimeHours,
  overnightStays,
  absentDays,
  absentDayRate,
  absencePenaltyThreshold,
  absencePenaltyPercent,
  ordered,
  i
) {
  const slab = ordered[i];
  const up = slab.nominal.upper;
  const cap = allowedUpper(up);

  // Check eligibility: km run must be within allowed upper bound
  if (isFinite(up) && kmRun > cap) return null;

  // Calculate extra km within +15% limit
  let extraKm = 0;
  if (isFinite(up)) {
    if (kmRun > up) extraKm = kmRun - up;
  } else if (slab.nominal.type === 'ABOVE') {
    const prev = ordered.slice(0, i).reverse().find(s => isFinite(s.nominal.upper));
    const prevUp = prev ? prev.nominal.upper : 0;
    extraKm = Math.max(0, kmRun - prevUp);
  }

  // Calculate base rental with full precision
  const baseRentalFull = Number(slab.monthly_rental);
  const bd = Number(billingDays) || 30;
  const wd = Number(workingDays) || bd;
  const prorateFactor = Math.min(Math.max(wd / bd, 0), 1);
  const baseRental = baseRentalFull * prorateFactor;

  // Calculate other components with full precision
  const extraCharge = extraKm * Number(slab.additional_km_rate);
  const overtimeCost = Number(slab.overtime_rate) * Number(overtimeHours);
  const overnightCost = Number(slab.night_allowance) * Number(overnightStays);

  // Absent deduction: ONLY penalty OR flat rate, never both
  let absentDeduction = 0;
  let absencePenalty = 0;

  if (absencePenaltyPercent > 0 && absentDays > absencePenaltyThreshold) {
    // Apply penalty: truncate to integer (Excel style)
    absencePenalty = toInt(baseRentalFull * (absencePenaltyPercent / 100));
    absentDeduction = absencePenalty;
  } else if (absentDayRate > 0) {
    // Apply flat rate per day
    absentDeduction = absentDayRate * Number(absentDays);
  }

  // Calculate total with full precision
  const total = baseRental + extraCharge + overtimeCost + overnightCost - absentDeduction;

  // Round only the final output values (Excel matches this approach)
  return {
    slab,
    nominalUpperKm: isFinite(up) ? up : null,
    allowedUpperKm: isFinite(cap) ? cap : null,
    extraKm,
    baseRental: to2(baseRental),
    baseRentalFull: to2(baseRentalFull),
    prorateFactor: to2(prorateFactor),
    extraCharge: to2(extraCharge),
    overtimeCost: to2(overtimeCost),
    overnightCost: to2(overnightCost),
    absentDeduction: to2(absentDeduction),
    overtimeHours: Number(overtimeHours),
    overnightStays: Number(overnightStays),
    absentDays: Number(absentDays),
    absentDayRate: Number(absentDayRate),
    absencePenalty,
    absencePenaltyThreshold,
    absencePenaltyPercent,
    absencePenaltyAppliedTo: 'baseRentalFull',
    total: to2(total),
    billingDays: bd,
    workingDays: wd,
  };
}

function computeMonthly(input, slabs) {
  const {
    kmRun,
    billingDays = 30,
    workingDays = null,
    overtimeHours = 0,
    overnightStays = 0,
    absentDays = 0,
    absentDayRate = 0,
    absencePenaltyThreshold = 5,
    absencePenaltyPercent = 0,
    otherAdditions = 0,
    otherDeductions = 0,
    includeVAT = false,
    vatPercent = null,
  } = input;

  const ordered = buildOrdered(slabs);
  const candidates = [];

  for (let i = 0; i < ordered.length; i++) {
    const c = monthlyCostForSlab(
      kmRun,
      billingDays,
      (workingDays ?? billingDays),
      overtimeHours,
      overnightStays,
      absentDays,
      absentDayRate,
      absencePenaltyThreshold,
      absencePenaltyPercent,
      ordered,
      i
    );
    if (c) candidates.push({ i, ...c });
  }

  if (candidates.length === 0) {
    const last = ordered[ordered.length - 1];
    const up = last.nominal.upper;
    const cap = allowedUpper(up);
    
    // Calculate with full precision
    const baseRentalFull = Number(last.monthly_rental);
    const baseRental = baseRentalFull * (Number(workingDays ?? billingDays) / (Number(billingDays) || 30));
    
    return {
      ...input,
      rateType: 'Monthly',
      slabLabel: last.km_slab,
      nominalUpperKm: isFinite(up) ? up : null,
      allowedUpperKm: isFinite(cap) ? cap : null,
      agreedKm: isFinite(cap) ? cap : null,
      baseRental: to2(baseRental),
      baseRentalFull: to2(baseRentalFull),
      extraKm: 0,
      extraCharge: 0,
      overtimeCost: 0,
      overnightCost: 0,
      absentDeduction: 0,
      absencePenalty: 0,
      absencePenaltyThreshold,
      absencePenaltyPercent,
      total: to2(baseRental),
    };
  }

  // Sort by total cost (tie-breaker: lower base rental)
  candidates.sort((a, b) => (a.total - b.total) || (a.baseRental - b.baseRental));
  const best = candidates[0];

  // Apply optional adjustments
  const adjustedTotal = to2(best.total + otherAdditions - otherDeductions);

  // Apply VAT if requested
  let finalVatPercent = null;
  let vat = null;
  let grandTotal = null;
  
  if (includeVAT) {
    finalVatPercent = Number(vatPercent ?? process.env.VAT_PERCENT ?? 0);
    vat = to2(adjustedTotal * finalVatPercent / 100);
    grandTotal = to2(adjustedTotal + vat);
  }

  return {
    ...input,
    rateType: 'Monthly',
    slabLabel: best.slab.km_slab,
    nominalUpperKm: best.nominalUpperKm,
    allowedUpperKm: best.allowedUpperKm,
    agreedKm: best.allowedUpperKm,
    billingDays: best.billingDays,
    workingDays: best.workingDays,
    prorateFactor: best.prorateFactor,
    baseRental: best.baseRental,
    baseRentalFull: best.baseRentalFull,
    extraKm: best.extraKm,
    extraCharge: best.extraCharge,
    overtimeCost: best.overtimeCost,
    overnightCost: best.overnightCost,
    absentDeduction: best.absentDeduction,
    absencePenalty: best.absencePenalty,
    absencePenaltyThreshold: best.absencePenaltyThreshold,
    absencePenaltyPercent: best.absencePenaltyPercent,
    absencePenaltyAppliedTo: best.absencePenaltyAppliedTo,
    total: best.total,
    otherAdditions: to2(otherAdditions),
    otherDeductions: to2(otherDeductions),
    adjustedTotal,
    ...(includeVAT ? { vatPercent: finalVatPercent, vat, grandTotal } : {}),
  };
}

function computeDaily(input, slabs) {
  const {
    kmRun,
    workingDays = 1,
    overtimeHours = 0,
    overnightStays = 0,
    otherAdditions = 0,
    otherDeductions = 0,
    includeVAT = false,
    vatPercent = null,
  } = input;

  const ordered = buildOrdered(slabs);
  const s = ordered.find(x => x.nominal.type === 'DAILY') || slabs[0];
  const dailyCap = s?.nominal?.upper ?? 100;

  // Calculate with full precision
  const dailyRate = Number(s.monthly_rental);
  const extraKm = Math.max(0, kmRun - dailyCap);
  const extraCharge = extraKm * Number(s.additional_km_rate);
  const overtimeCost = Number(s.overtime_rate) * Number(overtimeHours);
  const overnightCost = Number(s.night_allowance) * Number(overnightStays);
  const total = dailyRate * (Number(workingDays) || 1) + extraCharge + overtimeCost + overnightCost;

  // Apply optional adjustments
  const adjustedTotal = to2(total + otherAdditions - otherDeductions);

  // Apply VAT if requested
  let finalVatPercent = null;
  let vat = null;
  let grandTotal = null;
  
  if (includeVAT) {
    finalVatPercent = Number(vatPercent ?? process.env.VAT_PERCENT ?? 0);
    vat = to2(adjustedTotal * finalVatPercent / 100);
    grandTotal = to2(adjustedTotal + vat);
  }

  return {
    ...input,
    rateType: 'Daily',
    slabLabel: s.km_slab,
    dailyCapKm: dailyCap,
    dailyRate: to2(dailyRate),
    extraKm,
    extraCharge: to2(extraCharge),
    overtimeCost: to2(overtimeCost),
    overnightCost: to2(overnightCost),
    total: to2(total),
    otherAdditions: to2(otherAdditions),
    otherDeductions: to2(otherDeductions),
    adjustedTotal,
    ...(includeVAT ? { vatPercent: finalVatPercent, vat, grandTotal } : {}),
  };
}

function calculateForInput(input, slabs) {
  if (!slabs || slabs.length === 0) {
    return { error: 'No rate slabs found for the specified criteria', ...input };
  }
  
  const rt = String(input.rateType || 'Monthly').toUpperCase();
  
  if (rt === 'MONTHLY') return computeMonthly(input, slabs);
  if (rt === 'DAILY') return computeDaily(input, slabs);
  
  return { error: `Unsupported rateType: ${input.rateType}`, ...input };
}

async function calculateBatch(inputs) {
  const results = [];
  for (const input of inputs) {
    const slabs = await getSlabs(
      input.calculatedCardId,
      input.categoryCode,
      input.yomCategory,
      input.serviceType,
      input.fuelType ?? null,
      input.rateType || 'Monthly'
    );
    results.push(calculateForInput(input, slabs));
  }
  return results;
}

module.exports = { calculateBatch };