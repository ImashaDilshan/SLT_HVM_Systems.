const db = require('../config/db');

async function getVehiclesByCostCenter(costCenter) {
  console.log('Querying vehicles for cost center:', costCenter);
  try {
    const [rows] = await db.execute('SELECT * FROM vehicle_records WHERE cost_center = ?', [costCenter]);
    console.log('Query finished:', rows.length);
    return rows;
  } catch (err) {
    console.error('Query error:', err);
    throw err;
  }
}

module.exports = {
  getVehiclesByCostCenter
};