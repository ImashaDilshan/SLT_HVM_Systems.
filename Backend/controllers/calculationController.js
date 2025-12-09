// controllers/calculationController.js
const db = require('../config/db');

/**
 * POST /api/ratecards/calculate-monthly
 * Calculate total cost for monthly rental
 */
async function calculateMonthlyPrice(req, res) {
  const {
    date,
    vehicleCategory,
    fuelType,
    agreedKMSlab,
    actualKM,
    overTimeHours = 0,
    nightCount = 0
  } = req.body;

  // Validate required fields
  if (!date || !vehicleCategory || !fuelType || !agreedKMSlab || actualKM === undefined) {
    return res.status(400).json({
      success: false,
      message: 'Missing required fields'
    });
  }

  const query = `
    SELECT 
      mr.MonthlyRentalLKR,
      mr.AdditionalKmRateLKR AS slabAdditionalRate,
      COALESCE(mr.OverTimeRateLKR, 78.75) AS OverTimeRateLKR,
      COALESCE(mr.NightAllowanceLKR, 525.00) AS NightAllowanceLKR,
      -- Get per km rate from "Above 2500 km" slab for this vehicle
      (SELECT mr2.AdditionalKmRateLKR 
       FROM MonthlyRates mr2 
       JOIN VehicleTypes vt2 ON mr2.VehicleTypeID = vt2.VehicleTypeID 
       JOIN RatePlans rp2 ON mr2.PlanID = rp2.PlanID 
       WHERE rp2.EffectiveDate = ? 
         AND vt2.Category = ? 
         AND vt2.FuelType = ? 
         AND mr2.KMSlab = 'Above 2500 km'
      ) AS basePerKmRate
    FROM MonthlyRates mr
    JOIN VehicleTypes vt ON mr.VehicleTypeID = vt.VehicleTypeID
    JOIN RatePlans rp ON mr.PlanID = rp.PlanID
    WHERE rp.EffectiveDate = ? 
      AND vt.Category = ? 
      AND vt.FuelType = ? 
      AND mr.KMSlab = ?
  `;

  try {
    const [results] = await db.query(query, [
      date, vehicleCategory, fuelType,  // for basePerKmRate
      date, vehicleCategory, fuelType, agreedKMSlab
    ]);

    if (results.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Rate not found for given criteria'
      });
    }

    const rate = results[0];
    const additionalKmRate = rate.slabAdditionalRate || rate.basePerKmRate || 0;

    // Base monthly rental
    let total = parseFloat(rate.MonthlyRentalLKR);

    // Excess km: Only charge if actual > 2500 (or slab logic)
    let excessKM = 0;
    let excessCharge = 0;

    if (actualKM > 2500) {
      excessKM = actualKM - 2500;
      excessCharge = excessKM * additionalKmRate;
    }

    // Overtime and night allowance
    const overTimeCharge = overTimeHours * rate.OverTimeRateLKR;
    const nightAllowance = nightCount * rate.NightAllowanceLKR;

    total += excessCharge + overTimeCharge + nightAllowance;

    res.json({
      success: true,
      result: {
        baseRate: rate.MonthlyRentalLKR,
        excessKM,
        excessCharge: parseFloat(excessCharge.toFixed(2)),
        overTimeHours,
        overTimeCharge: parseFloat(overTimeCharge.toFixed(2)),
        nightCount,
        nightAllowance: parseFloat(nightAllowance.toFixed(2)),
        total: parseFloat(total.toFixed(2))
      }
    });

  } catch (err) {
    console.error('❌ Calculation Error:', err);
    res.status(500).json({
      success: false,
      message: 'Failed to calculate price'
    });
  }
}

/**
 * POST /api/ratecards/calculate-daily
 * Calculate daily rental cost
 */
async function calculateDailyPrice(req, res) {
  const { date, vehicleType, drivenKM } = req.body;

  if (!date || !vehicleType || drivenKM === undefined) {
    return res.status(400).json({
      success: false,
      message: 'Missing required fields'
    });
  }

  const query = `
    SELECT 
      dr.DailyRateLKR,
      dr.AdditionalKmRateLKR,
      vt.Category
    FROM DailyRates dr
    JOIN VehicleTypes vt ON dr.VehicleTypeID = vt.VehicleTypeID
    JOIN RatePlans rp ON dr.PlanID = rp.PlanID
    WHERE rp.EffectiveDate = ? 
      AND vt.Category = 'Field Van'
      AND vt.FuelType = ?
  `;

  try {
    const fuelType = vehicleType.includes('Diesel') ? 'Diesel' : 'Petrol';
    const [results] = await db.query(query, [date, fuelType]);

    if (results.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Daily rate not found'
      });
    }

    const rate = results[0];
    const baseRate = rate.DailyRateLKR;
    const extraKM = drivenKM > 100 ? drivenKM - 100 : 0;
    const extraCharge = extraKM * rate.AdditionalKmRateLKR;
    const total = baseRate + extraCharge;

    res.json({
      success: true,
      result: {
        baseDailyRate: baseRate,
        drivenKM,
        includedKM: 100,
        extraKM,
        extraCharge: parseFloat(extraCharge.toFixed(2)),
        total: parseFloat(total.toFixed(2))
      }
    });

  } catch (err) {
    console.error('❌ Daily Calc Error:', err);
    res.status(500).json({
      success: false,
      message: 'Failed to calculate daily price'
    });
  }
}

module.exports = {
  calculateMonthlyPrice,
  calculateDailyPrice
};