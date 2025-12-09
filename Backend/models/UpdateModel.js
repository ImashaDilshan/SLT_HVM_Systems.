const db = require("../config/db");

async function checkTableExists(tableName) {
  const [rows] = await db.query(
    "SELECT COUNT(*) AS count FROM information_schema.tables WHERE table_name = ?",
    [tableName]
  );
  return rows[0].count > 0;
}

async function updateByRefNo(tableName, refNo, data) {
  const fields = Object.keys(data)
    .map((key) => `\`${key}\` = ?`)
    .join(", ");
  const values = Object.values(data);

  const [result] = await db.query(
    `UPDATE \`${tableName}\` SET ${fields} WHERE ref_no = ?`,
    [...values, refNo]
  );
  return result;
}

module.exports = {
  checkTableExists,
  updateByRefNo,
};