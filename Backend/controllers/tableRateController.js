const db = require("../config/db");

// ==================== USER CONFIGURATION ====================
const USER_CONFIG = {
  billingDays: 30,
  absentDayRate: 2000,
  absentCapPercent: 10,
  absencePenaltyThreshold: 5,
  absencePenaltyPercent: 0,
  includeVAT: true,
  vatPercent: 18,
  rateType: "Monthly",
  vehicleTable: "vehicle_records",
  categoryTable: "vehicle_categories"
};

// ==================== UTILITY FUNCTIONS ====================
function safeTableName(name) {
  const n = String(name || "");
  if (!/^[a-zA-Z0-9_]+$/.test(n)) throw new Error("Invalid table name: " + n);
  return n;
}

function toNum(x, fallback = 0) {
  const n = Number(x);
  return Number.isFinite(n) ? n : fallback;
}

function norm(s) {
  return String(s ?? "").toUpperCase().replace(/\s+/g, " ").trim();
}

function looksLikeCategoryCode(s) {
  const x = String(s || "").trim();
  return /^[A-Z0-9_-]{3,12}$/.test(x);
}

function normalizeFuel(f) {
  if (f == null) return null;
  const X = String(f).trim().toUpperCase();
  if (X === "DIEDEL" || X === "DEISEL") return "DIESEL";
  if (X === "DIESEL AUTO") return "DIESEL";
  if (X === "PETROL 92") return "PETROL";
  return X;
}

function round2(n) { 
  return Math.round((Number(n || 0) + Number.EPSILON) * 100) / 100; 
}

// ==================== AUTO-PICK YOM ====================
function autoPickYomCategory(manufactureYear) {
  const year = toNum(manufactureYear);
  if (!year) return "UNKNOWN";
  if (year < 2000) return "BEFORE_2000";
  return "AFTER_2000";
}

// ==================== AUTO-PICK SERVICE TYPE ====================
function autoPickServiceType(rateCategory) {
  const rc = norm(rateCategory || "");
  if (rc.includes("WITH_DRIVER_FUEL")) return "WITH_DRIVER_FUEL";
  if (rc.includes("WITHOUT_DRIVER_FUEL") || rc.includes("SELF")) return "WITHOUT_DRIVER_FUEL";
  return "WITH_DRIVER_FUEL";
}

// ==================== INTENTION LOGIC ====================
function intendedFromRow(row) {
  const intended = {
    rateType: USER_CONFIG.rateType,
    serviceBucket: null,
    yomYear: toNum(row.manufacture_year ?? row.manuf_year ?? row.v_manuf_year)
  };
  
  const rc = (row.rate_category ?? "").toString();
  if (/\bWITH(_DRIVER)?_FUEL\b/i.test(rc)) intended.serviceBucket = "WITH";
  else if (/\bWITHOUT(_DRIVER)?_FUEL\b/i.test(rc) || /\bSELF\b/i.test(rc)) {
    intended.serviceBucket = "WITHOUT";
  }
  
  const rp = (row.rate_period ?? "").toString().toLowerCase();
  if (rp) intended.rateType = rp.includes("daily") ? "Daily" : "Monthly";
  
  intended.yomCategory = autoPickYomCategory(intended.yomYear);
  return intended;
}

function scoreYomLabel(label, yomYear) {
  if (!yomYear) return 0;
  const L = norm(label);
  const m = L.match(/(BEFORE|AFTER)\s*_?\s*(\d{4})/);
  if (m) {
    const dir = m[1]; const y = Number(m[2]);
    if (dir === "BEFORE") return yomYear < y ? 6 + (y - yomYear) * 0.001 : 0;
    if (dir === "AFTER") return yomYear >= y ? 6 + (yomYear - y) * 0.001 : 0;
  }
  if (L.includes("BEFORE 2000") && yomYear < 2000) return 4;
  if (L.includes("AFTER 2000") && yomYear >= 2000) return 4;
  return 0;
}

// ==================== LOAD CATEGORY MAP ====================
async function loadCategoryMap(conn, categoryTable) {
  const ct = safeTableName(categoryTable);
  const [cats] = await conn.execute(`SELECT category_code, category_name FROM ${ct}`);
  const byName = new Map();
  const byCode = new Set();
  for (const c of cats) {
    const code = String(c.category_code).trim();
    byName.set(norm(c.category_name), code);
    byCode.add(code.toUpperCase());
  }
  return { byName, byCode };
}

// ==================== RESOLVE SLAB LABELS ====================
async function resolveLabelsFromSlabs(conn, props) {
  const { calculatedCardId, categoryCode, yomCategory, intendedServiceBucket, intendedRateType, signals } = props;
  const [rows] = await conn.execute(
    `SELECT yom_category, service_type, rate_type,
            MAX(overtime_rate IS NOT NULL AND overtime_rate > 0) AS has_ot,
            MAX(night_allowance IS NOT NULL AND night_allowance > 0) AS has_night,
            MAX(additional_km_rate IS NOT NULL AND additional_km_rate > 0) AS has_extra
     FROM calculated_rate_slabs
     WHERE calculated_card_id = ? AND category_code = ?
     GROUP BY yom_category, service_type, rate_type`,
    [calculatedCardId, categoryCode]
  );
  
  if (!rows || rows.length === 0) return { error: "No slabs for this card/category" };

  const needOT = !!(signals && signals.hasOT);
  const needNight = !!(signals && signals.hasNight);
  const needExtra = !!(signals && Number(signals.kmRun) > 2500);

  const isPlainWith = (svc) => norm(svc) === "WITH_DRIVER_FUEL";
  const isPlainWithout = (svc) => norm(svc) === "WITHOUT_DRIVER_FUEL";
  const mentionsGen = (svc) => /GENERATOR/i.test(svc);

  let candidates = rows.filter(r =>
    (!needOT || Number(r.has_ot)) &&
    (!needNight || Number(r.has_night)) &&
    (!needExtra || Number(r.has_extra))
  );
  
  if (candidates.length === 0) candidates = rows;

  let best = null, bestScore = -1;
  for (const r of candidates) {
    const svc = String(r.service_type || "");
    const rt = String(r.rate_type || "");
    const svcIsWith = /\bWITH\b/i.test(svc) && !/\bWITHOUT\b/i.test(svc);
    const svcIsWithout = /\bWITHOUT\b/i.test(svc) || /\bSELF\b/i.test(svc);
    
    let score = 0;
    if (rt === intendedRateType) score += 6;
    score += scoreYomLabel(r.yom_category, signals.yomYear);
    if (isPlainWith(svc)) score += 6;
    if (isPlainWithout(svc)) score += 6;
    if (mentionsGen(svc)) score -= 8;
    if (intendedServiceBucket === "WITH" && svcIsWith) score += 2;
    if (intendedServiceBucket === "WITHOUT" && svcIsWithout) score += 2;
    if (needOT && Number(r.has_ot)) score += 5;
    if (needNight && Number(r.has_night)) score += 3;
    if (needExtra && Number(r.has_extra)) score += 4;
    
    if (score > bestScore) { bestScore = score; best = r; }
  }
  
  if (best && /GENERATOR/i.test(best.service_type)) {
    const plainAlt = candidates.find(x =>
      x.rate_type === best.rate_type &&
      norm(x.yom_category) === norm(best.yom_category) &&
      (norm(x.service_type) === "WITH_DRIVER_FUEL" || norm(x.service_type) === "WITHOUT_DRIVER_FUEL")
    );
    if (plainAlt) best = plainAlt;
  }
  
  if (!best) best = candidates[0];
  
  return {
    yom_category: best.yom_category,
    service_type: best.service_type,
    rate_type: best.rate_type
  };
}

// ==================== SLAB PARSING ====================
function parseNominalBounds(kmSlab) {
  const s = String(kmSlab || '').toLowerCase().trim();
  if (s.includes('daily')) {
    const m = s.match(/(\d+)/);
    return { type: 'DAILY', lower: 0, upper: m ? Number(m[1]) : 100 };
  }
  if (s.includes('upto') || s.includes('up to')) {
    const m = s.match(/(\d+)/);
    return { type: 'UPTO', lower: 0, upper: m ? Number(m[1]) : 999999 };
  }
  if (s.includes('above')) {
    const m = s.match(/(\d+)/);
    const base = m ? Number(m[1]) : 0;
    return { type: 'ABOVE', lower: base + 1, upper: Infinity };
  }
  const r = s.match(/(\d+)\s*-\s*(\d+)/);
  if (r) return { type: 'RANGE', lower: Number(r[1]), upper: Number(r[2]) };
  return { type: 'UNKNOWN', lower: 0, upper: 999999 };
}

function buildOrderedSlabs(slabs) {
  return slabs
    .map(s => ({ ...s, nominal: parseNominalBounds(s.km_slab) }))
    .sort((a, b) => {
      const au = a.nominal.upper === Infinity ? Number.MAX_SAFE_INTEGER : a.nominal.upper;
      const bu = b.nominal.upper === Infinity ? Number.MAX_SAFE_INTEGER : b.nominal.upper;
      return au - bu;
    });
}

function allowedUpperBound(nominalUpper) {
  if (!isFinite(nominalUpper)) return Infinity;
  return Number(nominalUpper) + Math.round(Number(nominalUpper) * 15 / 100);
}

// ==================== FETCH SLABS ====================
async function getSlabs(conn, calculatedCardId, categoryCode, yomCategory, serviceType, fuelType, rateType) {
  const rt = String(rateType || 'Monthly');
  const ft = normalizeFuel(fuelType);
  const st = (String(rt).toUpperCase() === 'DAILY' && !serviceType.startsWith('Short Term_')) 
    ? `Short Term_${serviceType}` 
    : serviceType;

  const runQuery = async ({ useFuel = true, customServiceType = st }) => {
    let sql = `
      SELECT id, calculated_card_id, category_code, yom_category, km_slab, max_distance,
             monthly_rental, additional_km_rate, overtime_rate, night_allowance,
             rate_type, service_type, fuel_type
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
    const [rows] = await conn.execute(sql, params);
    return rows;
  };

  let rows = await runQuery({ useFuel: true });
  if (!rows || rows.length === 0) {
    rows = await runQuery({ useFuel: false });
    if ((!rows || rows.length === 0) && String(rt).toUpperCase() === 'DAILY') {
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

// ==================== CORE CALCULATION ====================
function calculateMonthlyCost(input, slabs) {
  const { kmRun, billingDays = 30, workingDays = null, overtimeHours = 0, overnightStays = 0 } = input;
  const ordered = buildOrderedSlabs(slabs);
  const candidates = [];

  for (let i = 0; i < ordered.length; i++) {
    const slab = ordered[i];
    const up = slab.nominal.upper;
    const cap = allowedUpperBound(up);
    if (isFinite(up) && kmRun > cap) continue;

    let extraKm = 0;
    if (isFinite(up) && kmRun > up) {
      extraKm = kmRun - up;
    } else if (slab.nominal.type === 'ABOVE') {
      const prev = ordered.slice(0, i).reverse().find(s => isFinite(s.nominal.upper));
      const prevUp = prev ? prev.nominal.upper : 0;
      extraKm = Math.max(0, kmRun - prevUp);
    }

    const baseRentalFull = Number(slab.monthly_rental);
    const bd = Number(billingDays) || 30;
    const wd = Number(workingDays ?? billingDays);
    const prorateFactor = Math.min(Math.max(wd / bd, 0), 1);
    const baseRental = baseRentalFull * prorateFactor;
    const extraCharge = extraKm * Number(slab.additional_km_rate);
    const overtimeCost = Number(slab.overtime_rate) * Number(overtimeHours);
    const overnightCost = Number(slab.night_allowance) * Number(overnightStays);

    candidates.push({
      slab,
      nominalUpperKm: isFinite(up) ? up : null,
      allowedUpperKm: isFinite(cap) ? cap : null,
      extraKm,
      baseRental,
      baseRentalFull,
      prorateFactor,
      extraCharge,
      overtimeCost,
      overnightCost,
      total: baseRental + extraCharge + overtimeCost + overnightCost,
      billingDays: bd,
      workingDays: wd,
    });
  }

  if (candidates.length === 0) {
    const last = ordered[ordered.length - 1];
    const up = last.nominal.upper;
    const cap = allowedUpperBound(up);
    const baseRentalFull = Number(last.monthly_rental);
    const baseRental = baseRentalFull * (Number(workingDays ?? billingDays) / (Number(billingDays) || 30));
    candidates.push({
      slab: last,
      nominalUpperKm: isFinite(up) ? up : null,
      allowedUpperKm: isFinite(cap) ? cap : null,
      extraKm: 0,
      baseRental,
      baseRentalFull,
      prorateFactor: 1,
      extraCharge: 0,
      overtimeCost: 0,
      overnightCost: 0,
      total: baseRental,
      billingDays: Number(billingDays) || 30,
      workingDays: Number(workingDays ?? billingDays),
    });
  }

  candidates.sort((a, b) => (a.total - b.total) || (a.baseRental - b.baseRental));
  return candidates[0];
}

function calculateDailyCost(input, slabs) {
  const { kmRun, workingDays = 1, overtimeHours = 0, overnightStays = 0 } = input;
  const ordered = buildOrderedSlabs(slabs);
  const s = ordered.find(x => x.nominal.type === 'DAILY') || slabs[0];
  const dailyCap = s?.nominal?.upper ?? 100;
  const dailyRate = Number(s.monthly_rental);
  const extraKm = Math.max(0, kmRun - dailyCap);
  const extraCharge = extraKm * Number(s.additional_km_rate);
  const overtimeCost = Number(s.overtime_rate) * Number(overtimeHours);
  const overnightCost = Number(s.night_allowance) * Number(overnightStays);
  const total = dailyRate * (Number(workingDays) || 1) + extraCharge + overtimeCost + overnightCost;

  return {
    slab: s,
    dailyCapKm: dailyCap,
    dailyRate,
    extraKm,
    extraCharge,
    overtimeCost,
    overnightCost,
    total,
  };
}

// ==================== BATCH CALCULATION ====================
async function calculateBatch(conn, inputs, config) {
  const results = [];
  for (const input of inputs) {
    try {
      const slabs = await getSlabs(conn, input.calculatedCardId, input.categoryCode, input.yomCategory, input.serviceType, input.fuelType, input.rateType);
      if (!slabs || slabs.length === 0) {
        results.push({ error: 'No rate slabs found', pk: input.__pk });
        continue;
      }

      const rt = String(input.rateType || 'Monthly').toUpperCase();
      let calcResult;
      if (rt === 'MONTHLY') {
        calcResult = calculateMonthlyCost(input, slabs);
      } else if (rt === 'DAILY') {
        calcResult = calculateDailyCost(input, slabs);
      } else {
        results.push({ error: `Unsupported rateType: ${input.rateType}`, pk: input.__pk });
        continue;
      }

      // EXCEL-STYLE ABSENT DEDUCTION
      let absentDeduction = 0;
      if (config.absencePenaltyPercent > 0 && input.absentDays > config.absencePenaltyThreshold) {
        const penaltyAmount = Math.floor(calcResult.baseRentalFull * (config.absencePenaltyPercent / 100));
        absentDeduction = penaltyAmount;
        if (config.absentCapPercent != null) {
          const capAmount = (calcResult.baseRentalFull * config.absentCapPercent) / 100;
          const capFloor = Math.floor(capAmount);
          if (absentDeduction > capFloor) absentDeduction = capFloor;
        }
      } else if (config.absentDayRate > 0 && input.absentDays > 0) {
        absentDeduction = input.absentDays * config.absentDayRate;
      }

      const subtotal = calcResult.total - absentDeduction;
      const adjustedTotal = subtotal + toNum(input.otherAdditions) - toNum(input.otherDeductions);
      let vat = 0;
      if (config.includeVAT) {
        vat = round2(adjustedTotal * toNum(config.vatPercent) / 100);
      }
      const grandTotal = round2(adjustedTotal + vat);

      results.push({
        pk: input.__pk,
        rental: round2(calcResult.baseRental),
        baseRentalFull: round2(calcResult.baseRentalFull),
        ot_amount: round2(calcResult.overtimeCost),
        overnight_amount: round2(calcResult.overnightCost),
        excess_km: Math.round(calcResult.extraKm),
        excess_amount: round2(calcResult.extraCharge),
        absent_deduct_amount: round2(absentDeduction),
        total_preTax: round2(adjustedTotal),
        vat,
        grand_total: grandTotal,
        rate_period_val: rt,
        rate_category_val: input.serviceType,
        slab: calcResult.slab?.km_slab || 'Unknown',
        billingDays: calcResult.billingDays,
        workingDays: calcResult.workingDays,
        prorateFactor: calcResult.prorateFactor,
      });
    } catch (err) {
      results.push({ error: err.message, pk: input.__pk });
    }
  }
  return results;
}

// ==================== MAIN CONTROLLER ====================
exports.calculateAndPersistForTable = async (req, res) => {
  try {
    const {
      table, calculatedCardId, billingDays = USER_CONFIG.billingDays,
      absentDayRate = USER_CONFIG.absentDayRate, absentCapPercent = USER_CONFIG.absentCapPercent,
      absencePenaltyThreshold = USER_CONFIG.absencePenaltyThreshold, absencePenaltyPercent = USER_CONFIG.absencePenaltyPercent,
      includeVAT = USER_CONFIG.includeVAT, vatPercent = USER_CONFIG.vatPercent, rateType = USER_CONFIG.rateType,
      filter = { accept_role: "level02" }, serNoList = null, vehicleTable = USER_CONFIG.vehicleTable,
      categoryTable = USER_CONFIG.categoryTable, otherAdditions = 0, otherDeductions = 0,
    } = req.body || {};

    if (!table) return res.status(400).json({ error: "table is required" });
    if (!calculatedCardId && calculatedCardId !== 0) {
      return res.status(400).json({ error: "calculatedCardId is required" });
    }

    const tableName = safeTableName(table);
    const vehicleTbl = safeTableName(vehicleTable);

    const whereParts = [];
    const params = [];
    if (serNoList && Array.isArray(serNoList) && serNoList.length > 0) {
      whereParts.push(`t.ser_no IN (${serNoList.map(() => "?").join(",")})`);
      params.push(...serNoList.map(toNum));
    } else if (filter && typeof filter === "object") {
      for (const [k, v] of Object.entries(filter)) {
        if (!/^[a-zA-Z0-9_]+$/.test(k)) continue;
        if (Array.isArray(v)) {
          if (v.length > 0) {
            whereParts.push(`t.${k} IN (${v.map(() => "?").join(",")})`);
            params.push(...v.map(String));
          }
        } else if (v !== undefined && v !== null && v !== "") {
          whereParts.push(`t.${k} = ?`);
          params.push(String(v));
        }
      }
    }
    const whereClause = whereParts.length ? `WHERE ${whereParts.join(" AND ")}` : "";

    const sql = `
      SELECT t.*, v.fuel_type AS v_fuel_type, v.category AS v_category,
             v.vehicle_type AS v_vehicle_type, v.manuf_year AS v_manuf_year
      FROM ${tableName} t LEFT JOIN ${vehicleTbl} v ON v.ref_no = t.ref_no
      ${whereClause}
      ORDER BY t.ser_no ASC
    `;
    
    const conn = await db.getConnection();
    let updatedCount = 0;
    const failed = [];
    const sample = [];

    try {
      const [rows] = await conn.execute(sql, params);
      if (!rows || rows.length === 0) {
        conn.release();
        return res.json({ updatedCount: 0, failed, sample: [] });
      }

      const { byName: categoryByName, byCode: categoryCodesSet } = await loadCategoryMap(conn, categoryTable);

      const validInputs = [];
      for (const r of rows) {
        let categoryCode = null;
        const tCategoryRaw = String(r.category ?? "").trim();
        const vCategoryRaw = String(r.v_category ?? "").trim();
        const vehicleTypeName = String(r.vehicle_type ?? r.v_vehicle_type ?? "").trim();
        
        if (looksLikeCategoryCode(tCategoryRaw) && categoryCodesSet.has(tCategoryRaw.toUpperCase())) {
          categoryCode = tCategoryRaw;
        } else if (looksLikeCategoryCode(vCategoryRaw) && categoryCodesSet.has(vCategoryRaw.toUpperCase())) {
          categoryCode = vCategoryRaw;
        } else if (vehicleTypeName) {
          const mapped = categoryByName.get(norm(vehicleTypeName));
          if (mapped) categoryCode = mapped;
        }
        
        if (!categoryCode) {
          failed.push({ ser_no: r.ser_no, error: `Cannot map category: ${tCategoryRaw || vehicleTypeName}` });
          continue;
        }

        const intent = intendedFromRow(r);
        const resolved = await resolveLabelsFromSlabs(conn, {
          calculatedCardId, categoryCode, yomCategory: intent.yomCategory,
          intendedServiceBucket: intent.serviceBucket, intendedRateType: intent.rateType,
          signals: { hasOT: toNum(r.ot_hrs) > 0, hasNight: toNum(r.overnight) > 0, kmRun: toNum(r.km_run), yomYear: intent.yomYear }
        });
        
        if (resolved.error) {
          failed.push({ ser_no: r.ser_no, error: resolved.error });
          continue;
        }

        validInputs.push({
          __pk: r.ser_no, calculatedCardId, categoryCode,
          yomCategory: intent.yomCategory,
          serviceType: autoPickServiceType(r.rate_category),
          fuelType: normalizeFuel(r.fuel_type ?? r.v_fuel_type),
          rateType: intent.rateType,
          kmRun: toNum(r.km_run), billingDays: toNum(billingDays, 30),
          workingDays: toNum(r.working_days, toNum(billingDays, 30)),
          overtimeHours: toNum(r.ot_hrs), overnightStays: toNum(r.overnight),
          absentDays: toNum(r.absent_total), otherAdditions: toNum(otherAdditions),
          otherDeductions: toNum(otherDeductions),
        });
      }

      if (validInputs.length === 0) {
        conn.release();
        return res.json({ updatedCount: 0, failed, sample: [] });
      }

      const config = { includeVAT, vatPercent, absentDayRate, absencePenaltyThreshold, absencePenaltyPercent, absentCapPercent };
      const results = await calculateBatch(conn, validInputs, config);

      await conn.beginTransaction();
      const updateSql = `
        UPDATE ${tableName}
        SET
          rental = ?, ot_amount = ?, overnight_amount = ?, excess_km = ?, excess_amount = ?,
          absent_deduct_amount = ?, total = ?, tax_18_percent = ?, grand_total = ?,
          rate_period = ?, rate_category = ?, accept_role = 'admin'
        WHERE ser_no = ?
      `;

      for (const result of results) {
        if (result.error) {
          failed.push({ ser_no: result.pk, error: result.error });
          continue;
        }
        await conn.execute(updateSql, [
          result.rental, result.ot_amount, result.overnight_amount, result.excess_km,
          result.excess_amount, result.absent_deduct_amount, result.total_preTax, result.vat,
          result.grand_total, result.rate_period_val, result.rate_category_val, result.pk
        ]);
        updatedCount++;
        if (sample.length < 5) sample.push({
          ser_no: result.pk, slab: result.slab, baseRental: result.rental,
          extraKm: result.excess_km, extraAmount: result.excess_amount,
          overtime: result.ot_amount, overnight: result.overnight_amount,
          absentDeduction: result.absent_deduct_amount, total: result.total_preTax,
          vat: result.vat, grand_total: result.grand_total,
          rateType: result.rate_period_val, serviceType: result.rate_category_val,
        });
      }

      await conn.commit();
      conn.release();
      return res.json({ updatedCount, failed, sample });
      
    } catch (e) {
      await conn.rollback();
      conn.release();
      console.error("Transaction rollback:", e);
      return res.status(500).json({ error: "Failed during update transaction" });
    }
  } catch (err) {
    console.error("🚫 Error:", err);
    return res.status(500).json({ error: "Internal Server Error" });
  }
};