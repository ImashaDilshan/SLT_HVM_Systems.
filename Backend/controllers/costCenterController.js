const pool = require('../config/db');

exports.searchCostCenters = async (req, res) => {
  const q = req.query.q ?? '';
  console.log(`🔍 Searching cost centers with query: ${q}`);
  
  try {
    const [rows] = await pool.query(
      `SELECT id, cost_center_id, regon, cost_center_name
       FROM cost_centers
       WHERE cost_center_name LIKE ? OR CAST(cost_center_id AS CHAR) LIKE ?
       LIMIT 50`,
      [`%${q}%`, `%${q}%`]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).json({ success: false, error: 'Database error' });
  }
};
