// controllers/calculateController.js
const db = require('../config/db');

exports.calculateHire = async (req, res) => {
    console.log(req.body);

  const {
    vehicle_type,
    fuel_type,
    from_date,
    to_date,
    km_run,
    ot_hrs = 0,
    overnight = 0,
    absent_total = 0,
  } = req.body;

  // Validate required fields
  if (!vehicle_type || !fuel_type || !from_date || !to_date || km_run == null) {
    return res.status(400).json({
      success: false,
      message: 'Missing required fields'
    });
  }

  try {
    // 1. Calculate working_days
    const from = new Date(from_date);
    const to = new Date(to_date);
    const working_days = Math.floor((to - from) / (1000 * 60 * 60 * 24)) + 1;

    // 2. Detect hire type using working_days
    let hireType;
    if (working_days >= 28) {
      hireType = 'Monthly';
    } else {
      hireType = 'Daily';
    }

    // 3. Find Rate Plan by from_date
    const [plan] = await db.query(
      'SELECT PlanID, EffectiveDate FROM RatePlans WHERE ? <= EffectiveDate ORDER BY EffectiveDate ASC LIMIT 1',
      [from_date]
    );

    if (plan.length === 0) {
         console.log('Vehicle type not found');
      return res.status(404).json({
        success: false,
        message: 'No rate plan found for the given date'
      });
    }

    const planId = plan[0].PlanID;
    const effectiveDate = plan[0].EffectiveDate;


    // 4. Get VehicleTypeID
    const [vehicleType] = await db.query(
      'SELECT VehicleTypeID FROM VehicleTypes WHERE Category = ? AND FuelType = ?',
      [vehicle_type, fuel_type]
    );
    console.log(vehicleType);
    console.log(fuel_type);
    console.log(km_run);
    

    if (vehicleType.length === 0) {
        console.log('Vehicle type not foundsss');
      return res.status(404).json({
        success: false,
        message: 'Vehicle type not found in rate card'
      });
    }

    const vehicleTypeId = vehicleType[0].VehicleTypeID;

    let rental = 0;
    let excess_km = 0;
    let excess_amount = 0;
    let ot_amount = 0;
    let overnight_amount = 0;
    let absent_deduct_amount = 0;

    if (hireType === 'Monthly') {
      // ✅ Monthly Hire
      
      let kmSlab;
      if (km_run <= 1000) kmSlab = 'Upto 1000 km';
      else if (km_run <= 1500) kmSlab = '1001-1500 km';
      else if (km_run <= 2000) kmSlab = '1501-2000 km';
      else if (km_run <= 2500) kmSlab = '2001-2500 km';
      else kmSlab = 'Above 2500 km';
      

      const [rate] = await db.query(
        'SELECT * FROM MonthlyRates WHERE PlanID = ? AND VehicleTypeID = ? AND KMSlab = ?',
        [planId, vehicleTypeId, kmSlab]
      );

      if (rate.length === 0) {

        return res.status(404).json({
          success: false,
          message: 'Rate not found for this vehicle and slab'
        });
      }

      rental = rate[0].MonthlyRentalLKR;
      const addKmRate = rate[0].AdditionalKmRateLKR || 0;
      const otRate = rate[0].OverTimeRateLKR || 78.75;
      const nightRate = rate[0].NightAllowanceLKR || 525.00;

      // 🔹 Apply 15% excess rule (Note X)
      if (kmSlab === 'Upto 1000 km' && km_run > 1150) {
        excess_km = km_run - 1150;
        excess_amount = excess_km * addKmRate;
      } else if (kmSlab === '1001-1500 km' && km_run > 1725) {
        excess_km = km_run - 1725;
        excess_amount = excess_km * addKmRate;
      } else if (kmSlab === 'Above 2500 km' && km_run > 2500) {
        excess_km = km_run - 2500;
        excess_amount = excess_km * addKmRate;
      }

      ot_amount = ot_hrs * otRate;
      overnight_amount = overnight * nightRate;
    } else {
      // ✅ Daily Hire
      const [rate] = await db.query(
        'SELECT * FROM DailyRates WHERE PlanID = ? AND VehicleTypeID = ?',
        [planId, vehicleTypeId]
      );

      if (rate.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Daily rate not found'
        });
      }

      const dailyRate = rate[0].DailyRateLKR;
      const addKmRate = rate[0].AdditionalKmRateLKR || 0;
      const otRate = 78.75;
      const nightRate = 525.00;

      rental = dailyRate * working_days;

      const avgKmPerDay = km_run / working_days;
      if (avgKmPerDay > 100) {
        const excessPerDay = avgKmPerDay - 100;
        excess_km = excessPerDay * working_days;
        excess_amount = excess_km * addKmRate;
      }

      ot_amount = ot_hrs * otRate;
      overnight_amount = overnight * nightRate;
    }

    // 5. Total
    const total = rental + ot_amount + overnight_amount + excess_amount - absent_deduct_amount;
    const tax_18_percent = total * 0.18;
    const grand_total = total + tax_18_percent;

    // 6. Return full response
    res.json({
      success: true,
      data: {
        hireType,
        working_days,
        effectiveDate,
        vehicle_type,
        fuel_type,
        km_run,
        rental,
        ot_hrs,
        ot_amount,
        overnight,
        overnight_amount,
        excess_km,
        excess_amount,
        absent_total,
        absent_deduct_amount,
        total,
        tax_18_percent,
        grand_total,
        calculation_notes: {
          kmSlab: hireType === 'Monthly' ? 'Auto-detected' : 'Daily rate per 100 km',
          excess_rule_applied: hireType === 'Monthly' && (km_run > 1150 || km_run > 1725),
        }
      }
    });
  } catch (err) {
    console.error('❌ Calculation error:', err);
    res.status(500).json({
      success: false,
      message: 'Calculation failed'
    });
  }
};