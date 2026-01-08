const db = require('../config/db');

// GET /admin/cost-centers
// returns distinct cost centers from vehicle_records table
exports.getCostCentersList = async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT
        ser_no            AS cost_center_id,
        cost_center       AS cost_center_name,
        gm                AS region,
        dgm               AS dgm_title
      FROM vehicle_records
      GROUP BY ser_no, cost_center, gm, dgm
      ORDER BY cost_center ASC;
    `);

    res.json({
      success: true,
      costCenters: rows
    });
  } catch (err) {
    console.error('❌ getCostCentersList error:', err);
    res.status(500).json({
      success: false,
      message: 'Failed to load cost centers'
    });
  }
};
