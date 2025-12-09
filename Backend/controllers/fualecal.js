// controllers/fualecal.js
// Fuel-Based Rate Calculator for SLT Vehicle Hire
// Formula: I = (N - P) * (D / K), New Rate = R + I
// Uses: Jan 31, 2025 base prices: Petrol=309, Diesel=286

const mysql = require('mysql2/promise');
const db = require('../config/db');

exports.calculateHire = async (req, res) => {
  const { petrol, diesel } = req.body;

  // Validate input
  if (typeof petrol !== 'number' || typeof diesel !== 'number') {
    return res.status(400).json({
      error: 'Please provide valid petrol and diesel prices as numbers.'
    });
  }

  let connection;
  try {
    connection = await db.getConnection();

    // 1. Get latest base rate card (Jan 31, 2025)
    const [baseRows] = await connection.execute(
      `SELECT id FROM rate_card_base ORDER BY effective_date DESC LIMIT 1`
    );

    if (baseRows.length === 0) {
      return res.status(404).json({ error: 'Base rate card not found.' });
    }

    const base_id = baseRows[0].id;

    // 2. Get base fuel prices (P) from Jan 31, 2025
    const [fuelRows] = await connection.execute(
      `SELECT fuel_type, base_price FROM fuel_prices WHERE base_id = ?`,
      [base_id]
    );

    const baseFuelPrices = {};
    fuelRows.forEach(row => {
      baseFuelPrices[row.fuel_type] = parseFloat(row.base_price);
    });

    if (!baseFuelPrices.Petrol || !baseFuelPrices.Diesel) {
      return res.status(500).json({
        error: 'Base fuel prices missing. Must have Petrol=309, Diesel=286.'
      });
    }

    const P_petrol = baseFuelPrices.Petrol; // 309 LKR/L
    const P_diesel = baseFuelPrices.Diesel; // 286 LKR/L

    // 3. Fetch all base slabs with vehicle fuel consumption (K)
    const [slabRows] = await connection.execute(`
      SELECT 
        rcs.category_code,
        rcs.yom_category,
        rcs.km_slab,
        rcs.max_distance,
        rcs.monthly_rental,
        COALESCE(rcs.fuel_type, v.fuel_type) AS fuel_type,
        v.fuel_consumption AS K
      FROM rate_card_slabs rcs
      JOIN vehicles v ON rcs.category_code = v.category_code
      WHERE rcs.base_id = ?
        AND rcs.service_type = 'WithDriverFuel'
      ORDER BY rcs.category_code, rcs.yom_category, rcs.max_distance
    `, [base_id]);

    if (slabRows.length === 0) {
      return res.status(404).json({ error: 'No base slabs found for calculation.' });
    }

    // 4. Generate unique version string
    const now = new Date();
    const targetMonth = now.toLocaleString('default', { month: 'short', year: 'numeric' });
    const versionNo = `Manual-${targetMonth}-P${petrol}-D${diesel}`; // Human-readable

    // 5. Prepare insert data
    const insertValues = [];
    const calculatedRates = [];
    const seen = new Set(); // Prevent duplicates

    for (const row of slabRows) {
      const D = row.max_distance;
      const R = parseFloat(row.monthly_rental);
      const K = row.K;

      // Determine fuel type
      let fuelTypeToUse;
      if (row.category_code === 'CAR01') {
        fuelTypeToUse = 'Petrol'; // SLT uses only petrol for cars
      } else {
        fuelTypeToUse = row.fuel_type || 'Diesel'; // Fallback
      }

      // Choose base price (P) and new price (N)
      const P = fuelTypeToUse === 'Petrol' ? P_petrol : P_diesel;
      const N = fuelTypeToUse === 'Petrol' ? petrol : diesel;

      // Calculate adjustment: I = (N - P) * (D / K)
      const I = (N - P) * (D / K);
      const newRental = parseFloat((R + I).toFixed(2));

      // Prevent duplicates (include fuel type in key)
      const key = `${row.category_code}-${row.yom_category}-${row.km_slab}-${fuelTypeToUse}`;
      if (seen.has(key)) continue;
      seen.add(key);

      // Add to insert array
      insertValues.push([
        base_id,
        targetMonth,
        versionNo,
        row.category_code,
        row.yom_category,
        row.km_slab,
        D,
        newRental
      ]);

      // Add to response
      calculatedRates.push({
        category: row.category_code,
        yom: row.yom_category,
        slab: row.km_slab,
        fuel_type: fuelTypeToUse,
        base_rental: R,
        adjustment: I.toFixed(2),
        new_rental: newRental
      });
    }

    // 6. Insert into calculated_rate_cards using query() (supports VALUES ?)
    const [result] = await connection.query(
      `INSERT INTO calculated_rate_cards 
       (base_id, target_month, version_no, category_code, yom_category, km_slab, max_distance, new_rental)
       VALUES ?`,
      [insertValues]
    );

    connection.release();

    // 7. Return success
    res.json({
      message: 'Rate card calculated and saved successfully.',
      version: versionNo,
      total_calculated: calculatedRates.length,
      affected_rows: result.affectedRows,
      new_fuel_prices: { Petrol: petrol, Diesel: diesel },
      sample_rates: calculatedRates.slice(0, 5)
    });

  } catch (error) {
    if (connection) connection.release();
    console.error('Rate calculation failed:', error);
    res.status(500).json({
      error: 'Server error',
      details: error.message
    });
  }
};