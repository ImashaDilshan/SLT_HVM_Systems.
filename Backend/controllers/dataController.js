const db = require('../config/db');
const userModel = require('../models/userModel');

async function getUser(req, res) {
  const { uid } = req.params;
  try {
    const userData = await userModel.getUserWithCostCenters(uid);
    res.json(userData);
  } catch (err) {
    res.status(404).json({ error: err.message });
  }
}

async function getDataByDateAndFilter(req, res) {
  const { tableName, location, mode, role } = req.body;
  console.log("🔍 Fetching data for mode:", mode, "role:", role);

  try {
    // 1. Check if table exists
    const [tableCheck] = await db.query(
      `SHOW TABLES LIKE ?`,
      [tableName]
    );

    if (tableCheck.length === 0) {
      return res.json({
        success: true,
        data: [],
        message: `NOTE: Data Sheet '${tableName}' does not exist yet.`,
      });
    }

    let query;
    let params;

    // 2. If role is Moderetor → fetch both 'Moderetor' and 'Remove'
    if (role === "Moderetor") {
      query = `
        SELECT 
          ser_no, user, cost_center, ref_no, vehicle_no, accept_role, vehicle_type, category,
          manufacture_year, from_date, to_date, working_days, km_run, ot_hrs, overnight
        FROM \`${tableName}\`
        WHERE cost_center = ? AND type = ? AND accept_role IN (?, ?)
      `;
      params = [location, mode, "Moderetor", "Remove"];
    } else {
      // For all other roles → match exact accept_role
      query = `
        SELECT 
          ser_no, user, cost_center, ref_no, vehicle_no, accept_role, vehicle_type, category,
          manufacture_year, from_date, to_date, working_days, km_run, ot_hrs, overnight
        FROM \`${tableName}\`
        WHERE cost_center = ? AND type = ? AND accept_role = ?
      `;
      params = [location, mode, role];
    }

    const [rows] = await db.query(query, params);

    if (rows.length === 0) {
      return res.json({
        success: true,
        message: '⚠️ No records found in database.',
        data: [],
      });
    }

    // 3. Return the matching records
    res.json({
      success: true,
      data: rows,
    });

  } catch (error) {
    console.error('❌ Error fetching data:', error);
    if (error.code === 'ER_BAD_FIELD_ERROR') {
      return res.status(400).json({
        success: false,
        message: `Query error`,
      });
    }
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
}

module.exports = {
  getUser,
  getDataByDateAndFilter,
};