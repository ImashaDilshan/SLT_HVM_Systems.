const db = require("../config/db");

// Check if table exists in DB
async function checkTableExists(tableName) {
  const [rows] = await db.query(`SHOW TABLES LIKE ?`, [tableName]);
  return rows.length > 0;
}

module.exports = { checkTableExists };
