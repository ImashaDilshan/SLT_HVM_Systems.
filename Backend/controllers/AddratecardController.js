// controllers/ratecardBulkController.js
const e = require('express');
const db = require('../config/db');

// ✅ Bulk Add Monthly Rates
exports.bulkAddMonthly = async (req, res) => {
  console.log(res.body);
  
  const { effectiveDate, rates } = req.body;

  if (!effectiveDate || !Array.isArray(rates)) {
    return res.status(400).json({
      success: false,
      message: 'Missing effectiveDate or rates'
    });
  }

  try {
    // Get or Create PlanID
    let [plan] = await db.query('SELECT PlanID FROM RatePlans WHERE EffectiveDate = ?', [effectiveDate]);
    let planId;
    if (plan.length === 0) {
      const [result] = await db.query(
        'INSERT INTO RatePlans (PlanName, EffectiveDate) VALUES (?, ?)',
        [`Rates from ${effectiveDate}`, effectiveDate]
      );
      planId = result.insertId;
    } else {
      planId = plan[0].PlanID;
    }

    const insertPromises = rates.map(async (rate) => {
      const [vehicleType] = await db.query(
        'SELECT VehicleTypeID FROM VehicleTypes WHERE Category = ? AND FuelType = ?',
        [rate.vehicle, rate.fuelType]
      );
      let vehicleTypeId;
      if (vehicleType.length === 0) {
        const [result] = await db.query(
          'INSERT INTO VehicleTypes (Category, FuelType) VALUES (?, ?)',
          [rate.vehicle, rate.fuelType]
        );
        vehicleTypeId = result.insertId;
      } else {
        vehicleTypeId = vehicleType[0].VehicleTypeID;
      }

      await db.query(
        `INSERT INTO MonthlyRates 
        (PlanID, VehicleTypeID, KMSlab, MonthlyRentalLKR, AdditionalKmRateLKR, OverTimeRateLKR, NightAllowanceLKR)
        VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          planId,
          vehicleTypeId,
          rate.kmSlab,
          rate.monthlyRentalLKR,
          rate.additionalKmRateLKR,
          rate.overTimeRateLKR || 78.75,
          rate.nightAllowanceLKR || 525.00
        ]
      );
    });

    await Promise.all(insertPromises);

    res.status(201).json({
      success: true,
      message: 'Full monthly rate card added'
    });
  } catch (err) {
    console.error('❌ Bulk add error:', err);
    res.status(500).json({
      success: false,
      message: 'Failed to add rate card'
    });
  }
};

// ✅ Bulk Add Daily Rates
exports.bulkAddDaily = async (req, res) => {
  const { effectiveDate, rates } = req.body;

  try {
    let [plan] = await db.query('SELECT PlanID FROM RatePlans WHERE EffectiveDate = ?', [effectiveDate]);
    let planId;
    if (plan.length === 0) {
      const [result] = await db.query(
        'INSERT INTO RatePlans (PlanName, EffectiveDate) VALUES (?, ?)',
        [`Rates from ${effectiveDate}`, effectiveDate]
      );
      planId = result.insertId;
    } else {
      planId = plan[0].PlanID;
    }

    const insertPromises = rates.map(async (rate) => {
      const [vehicleType] = await db.query(
        'SELECT VehicleTypeID FROM VehicleTypes WHERE Category = ? AND FuelType = ?',
        [rate.vehicle, rate.fuelType]
      );
      let vehicleTypeId;
      if (vehicleType.length === 0) {
        const [result] = await db.query(
          'INSERT INTO VehicleTypes (Category, FuelType) VALUES (?, ?)',
          [rate.vehicle, rate.fuelType]
        );
        vehicleTypeId = result.insertId;
      } else {
        vehicleTypeId = vehicleType[0].VehicleTypeID;
      }

      await db.query(
        `INSERT INTO DailyRates (PlanID, VehicleTypeID, DailyRateLKR, AdditionalKmRateLKR)
         VALUES (?, ?, ?, ?)`,
        [planId, vehicleTypeId, rate.dailyRateLKR, rate.additionalKmRateLKR]
      );
    });

    await Promise.all(insertPromises);

    res.status(201).json({
      success: true,
      message: 'Daily rates added'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed' });
  }
};