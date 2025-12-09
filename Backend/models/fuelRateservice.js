const db = require("../config/db");

exports.calculateAllRateCards = async (data) => {
  const connection = await db.getConnection();
  
  try {
    // Fetch all active rate cards
    const [activeRatecards] = await connection.execute(
      'SELECT id, name, base_fuel_price_diesel, base_fuel_price_petrol FROM ratecard_list WHERE status = "active"'
    );

    if (activeRatecards.length === 0) {
      throw new Error('No active rate cards found in database');
    }

    const results = [];
    
    // Process each rate card sequentially
    for (const ratecard of activeRatecards) {
      console.log(`Fuel Calculation: Processing ${ratecard.name} (ID: ${ratecard.id})`);
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

/**
 * Process a single rate card with transaction safety
 */
async function processSingleRateCard(connection, ratecard, data) {
  await connection.beginTransaction();

  try {
    const ratecardId = ratecard.id;
    const baseDieselPrice = parseFloat(ratecard.base_fuel_price_diesel) || 286.00;
    const basePetrolPrice = parseFloat(ratecard.base_fuel_price_petrol) || 299.00;

    // Get base rate records
    const [baseRates] = await connection.execute(
      'SELECT * FROM baseratecard_new WHERE ratecard_id = ?',
      [ratecardId]
    );

    if (baseRates.length === 0) {
      throw new Error(`No base rates found for rate card ID ${ratecardId}`);
    }

    // Insert calculation log
    const [logResult] = await connection.execute(
      `INSERT INTO fuel_calculation_log (
        ratecard_id, diesel_price, petrol_price, calculation_date,
        base_fuel_price_diesel, base_fuel_price_petrol
      ) VALUES (?, ?, ?, ?, ?, ?)`,
      [ratecardId, data.dieselPrice, data.petrolPrice, data.calculationDate, baseDieselPrice, basePetrolPrice]
    );
    const calculationLogId = logResult.insertId;

    // Process each rate record
    let recordCount = 0;
    for (const rate of baseRates) {
      // Skip records with no rental value
      if (!rate.monthly_rental) {
        console.warn(`Skipping record ID ${rate.id}: no monthly_rental`);
        continue;
      }

      // MySQL returns DECIMAL as STRING - convert ALL to numbers
      const monthlyRental = parseFloat(rate.monthly_rental);
      const maxDistance = parseFloat(rate.max_distance) || 1000;
      const additionalKmRate = parseFloat(rate.additional_km_rate) || 0;
      const overtimeRate = parseFloat(rate.overtime_rate) || 0;
      const nightAllowance = parseFloat(rate.night_allowance) || 0;

      // Validate conversions
      if (isNaN(monthlyRental)) {
        throw new Error(`Invalid monthly_rental value: ${rate.monthly_rental} (record ID: ${rate.id})`);
      }

      // Apply fuel formula: I = (N-P) * (D/K)
      const baseFuelPrice = rate.fuel_type === 'Diesel' ? baseDieselPrice : basePetrolPrice;
      const newFuelPrice = rate.fuel_type === 'Diesel' ? data.dieselPrice : data.petrolPrice;
      const distanceFactor = maxDistance / 1000;
      const fuelAdjustment = (newFuelPrice - baseFuelPrice) * distanceFactor;
      const adjustedRental = monthlyRental + fuelAdjustment;

      // Insert "After Year 2000" record
      await insertAdjustedRate(connection, {
        logId: calculationLogId,
        rate,
        yomCategory: 'After Year 2000',
        monthlyRental: adjustedRental,
        fuelAdjustment,
        additionalKmRate,
        overtimeRate,
        nightAllowance
      });
      recordCount++;

      // Insert "Before Year 2000" with discount (if applicable)
      const discountPercent = getYomDiscount(rate.category_code);
      if (discountPercent > 0) {
        const beforeYomRental = adjustedRental * (100 - discountPercent) / 100;
        await insertAdjustedRate(connection, {
          logId: calculationLogId,
          rate,
          yomCategory: 'Before Year 2000',
          monthlyRental: beforeYomRental,
          fuelAdjustment,
          additionalKmRate,
          overtimeRate,
          nightAllowance
        });
        recordCount++;
      }
    }

    // Update base fuel prices for future calculations
    await connection.execute(
      'UPDATE ratecard_list SET base_fuel_price_diesel = ?, base_fuel_price_petrol = ? WHERE id = ?',
      [data.dieselPrice, data.petrolPrice, ratecardId]
    );

    await connection.commit();
    
    return {
      ratecardId,
      ratecardName: ratecard.name,
      calculationLogId,
      totalRecords: recordCount
    };

  } catch (error) {
    await connection.rollback();
    throw new Error(`Failed ${ratecard.name}: ${error.message}`);
  }
}

/**
 * Get YOM discount percentage by vehicle category
 */
function getYomDiscount(categoryCode) {
  switch (categoryCode) {
    case 'VFP01': return 7;  // Vans Petrol Before 2000
    case 'VFD01': return 19; // Vans Diesel Before 2000
    case 'VP01': return 25;  // Passenger Vans Before 2000
    default: return 0;        // N/A for other categories
  }
}

/**
 * Insert adjusted rate with final number conversion
 * This is where .toFixed() is safely called
 */
async function insertAdjustedRate(connection, options) {
  const {
    logId,
    rate,
    yomCategory,
    monthlyRental,
    fuelAdjustment,
    additionalKmRate,
    overtimeRate,
    nightAllowance
  } = options;

  // CRITICAL: Final number conversion right before .toFixed()
  const rental = Number(monthlyRental);
  const adjustment = Number(fuelAdjustment);
  const addKm = Number(additionalKmRate);
  const otRate = Number(overtimeRate);
  const nightAllow = Number(nightAllowance);
  const maxDist = Number(rate.max_distance);

  // Validate numbers
  if (isNaN(rental) || isNaN(adjustment)) {
    throw new Error(`Cannot convert to number: rental=${monthlyRental}, adjustment=${fuelAdjustment}`);
  }

  // Now safe to use .toFixed()
  await connection.execute(
    `INSERT INTO fuel_adjusted_ratecards (
      calculation_log_id, category_code, yom_category, km_slab, max_distance,
      monthly_rental, additional_km_rate, overtime_rate, night_allowance,
      rate_type, service_type, fuel_type, fuel_adjustment_amount
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      logId,
      rate.category_code,
      yomCategory,
      rate.km_slab,
      maxDist,
      rental.toFixed(2),          // SAFE NOW
      addKm,
      otRate,
      nightAllow,
      rate.rate_type,
      rate.service_type,
      rate.fuel_type,
      adjustment.toFixed(2)       // SAFE NOW
    ]
  );
}