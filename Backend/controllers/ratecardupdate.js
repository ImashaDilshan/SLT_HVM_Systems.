// controllers/ratecardController.js
const db = require('../config/db');

// ✅ Update Monthly Rate by criteria
exports.updateMonthlyRate = async (req, res) => {
  const {
    effectiveDate,
    vehicle,
    fuelType,
    kmSlab,
    monthlyRentalLKR,
    additionalKmRateLKR,
    overTimeRateLKR,
    nightAllowanceLKR
  } = req.body;

  const query = `
    UPDATE MonthlyRates mr
    JOIN VehicleTypes vt ON mr.VehicleTypeID = vt.VehicleTypeID
    JOIN RatePlans rp ON mr.PlanID = rp.PlanID
    SET 
      mr.MonthlyRentalLKR = ?,
      mr.AdditionalKmRateLKR = ?,
      mr.OverTimeRateLKR = ?,
      mr.NightAllowanceLKR = ?
    WHERE rp.EffectiveDate = ?
      AND vt.Category = ?
      AND vt.FuelType = ?
      AND mr.KMSlab = ?
  `;

  try {
    const [result] = await db.query(query, [
      monthlyRentalLKR,
      additionalKmRateLKR,
      overTimeRateLKR || 78.75,
      nightAllowanceLKR || 525.00,
      effectiveDate,
      vehicle,
      fuelType,
      kmSlab
    ]);

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'No matching rate found to update'
      });
    }

    res.json({
      success: true,
      message: 'Rate updated successfully'
    });
  } catch (err) {
    console.error('❌ Update error:', err);
    res.status(500).json({
      success: false,
      message: 'Database update failed'
    });
  }
};

// ✅ Update Daily Rate
exports.updateDailyRate = async (req, res) => {
  const {
    effectiveDate,
    vehicle,
    fuelType,
    dailyRateLKR,
    additionalKmRateLKR
  } = req.body;

  const query = `
    UPDATE DailyRates dr
    JOIN VehicleTypes vt ON dr.VehicleTypeID = vt.VehicleTypeID
    JOIN RatePlans rp ON dr.PlanID = rp.PlanID
    SET 
      dr.DailyRateLKR = ?,
      dr.AdditionalKmRateLKR = ?
    WHERE rp.EffectiveDate = ?
      AND vt.Category = ?
      AND vt.FuelType = ?
  `;

  try {
    const [result] = await db.query(query, [
      dailyRateLKR,
      additionalKmRateLKR,
      effectiveDate,
      vehicle,
      fuelType
    ]);

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'No daily rate found to update'
      });
    }

    res.json({
      success: true,
      message: 'Daily rate updated successfully'
    });
  } catch (err) {
    console.error('❌ Daily update error:', err);
    res.status(500).json({
      success: false,
      message: 'Failed to update daily rate'
    });
  }
};