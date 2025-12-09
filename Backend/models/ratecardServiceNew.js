const db = require("../config/db");

exports.calculateAllRateCards = async (data) => {
  const connection = await db.getConnection();
  
  try {
    const [activeRatecards] = await connection.execute(
      'SELECT id, name, base_fuel_price_diesel, base_fuel_price_petrol FROM ratecard_list WHERE status = "active"'
    );

    if (activeRatecards.length === 0) {
      throw new Error('No active rate cards found');
    }

    const results = [];
    
    for (const ratecard of activeRatecards) {
      console.log(`Processing rate card: ${ratecard.name} (ID: ${ratecard.id})`);
      const result = await processSingleRateCard(connection, ratecard, data);
      results.push(result);
    }

    return results;

  } catch (error) {
    throw new Error(`Bulk processing failed: ${error.message}`);
  } finally {
    connection.release();
  }
};

async function processSingleRateCard(connection, ratecard, data) {
  await connection.beginTransaction();

  try {
    const ratecardId = ratecard.id;
    const baseDieselPrice = parseFloat(ratecard.base_fuel_price_diesel) || 286.00;
    const basePetrolPrice = parseFloat(ratecard.base_fuel_price_petrol) || 299.00;

    const [baseRates] = await connection.execute(
      'SELECT * FROM baseratecard_new WHERE ratecard_id = ?',
      [ratecardId]
    );

    const [logResult] = await connection.execute(
      `INSERT INTO fuel_calculation_log (...) VALUES (?, ?, ?, ?, ?, ?)`,
      [ratecardId, data.dieselPrice, data.petrolPrice, data.calculationDate, baseDieselPrice, basePetrolPrice]
    );
    const calculationLogId = logResult.insertId;

    let recordCount = 0;
    for (const rate of baseRates) {
      if (!rate.monthly_rental) continue;

      // Convert ONCE at the start
      const monthlyRental = parseFloat(rate.monthly_rental);
      const maxDistance = parseFloat(rate.max_distance) || 1000;
      const additionalKmRate = parseFloat(rate.additional_km_rate) || 0;
      const overtimeRate = parseFloat(rate.overtime_rate) || 0;
      const nightAllowance = parseFloat(rate.night_allowance) || 0;

      // Calculate
      const baseFuelPrice = rate.fuel_type === 'Diesel' ? baseDieselPrice : basePetrolPrice;
      const newFuelPrice = rate.fuel_type === 'Diesel' ? data.dieselPrice : data.petrolPrice;
      const distanceFactor = maxDistance / 1000;
      const fuelAdjustment = (newFuelPrice - baseFuelPrice) * distanceFactor;
      const adjustedRental = monthlyRental + fuelAdjustment;

      // Insert After
      await insertAdjustedRate(connection, calculationLogId, rate, 'After Year 2000', adjustedRental, fuelAdjustment, additionalKmRate, overtimeRate, nightAllowance);
      console.log('DEBUG_HELPER:', {
    monthlyRental: monthlyRental,
    type: typeof monthlyRental,
    isNaN: isNaN(monthlyRental)
  });

      recordCount++;

      // Insert Before (if applicable)
      const discountPercent = getYomDiscount(rate.category_code);
      if (discountPercent > 0) {
        const beforeYomRental = adjustedRental * (100 - discountPercent) / 100;
        await insertAdjustedRate(connection, calculationLogId, rate, 'Before Year 2000', beforeYomRental, fuelAdjustment, additionalKmRate, overtimeRate, nightAllowance);
        recordCount++;
      }
    }

    await connection.commit();
    return { ratecardId, ratecardName: ratecard.name, calculationLogId, totalRecords: recordCount };

  } catch (error) {
    await connection.rollback();
    throw error;
  }
}

function getYomDiscount(categoryCode) {
  switch (categoryCode) {
    case 'VFP01': return 7;
    case 'VFD01': return 19;
    case 'VP01': return 25;
    default: return 0;
  }
}

// FIX: Convert values INSIDE helper before .toFixed()
async function insertAdjustedRate(connection, logId, rate, yomCategory, monthlyRental, fuelAdjustment, additionalKmRate, overtimeRate, nightAllowance) {
  // FINAL SAFETY: Convert everything to number
  const rental = Number(monthlyRental);
  const adjustment = Number(fuelAdjustment);
  
  if (isNaN(rental) || isNaN(adjustment)) {
    throw new Error(`Invalid numeric values: rental=${monthlyRental}, adjustment=${fuelAdjustment}`);
  }

  // Convert all rate values to numbers
  const addKmRate = Number(additionalKmRate);
  const otRate = Number(overtimeRate);
  const nightAllow = Number(nightAllowance);
  const maxDist = Number(rate.max_distance);

  await connection.execute(
    `INSERT INTO fuel_adjusted_ratecards (...) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      logId, rate.category_code, yomCategory, rate.km_slab, maxDist,
      parseFloat(rental.toFixed(2)), addKmRate, otRate, nightAllow,
      rate.rate_type, rate.service_type, rate.fuel_type,
      parseFloat(adjustment.toFixed(2))
    ]
  );
}