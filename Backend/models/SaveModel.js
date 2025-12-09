const db = require("../config/db");

// Check if table exists in DB
async function checkTableExists(tableName) {
  const [rows] = await db.query(`SHOW TABLES LIKE ?`, [tableName]);
  return rows.length > 0;
}

// Create table if not exists
async function createTable(tableName) {
  const createTableSQL = `
    CREATE TABLE \`${tableName}\` (
      ser_no INT AUTO_INCREMENT PRIMARY KEY,
  type VARCHAR(50),
  user VARCHAR(255),
  dgm VARCHAR(255),
  gm VARCHAR(255),
  cost_center VARCHAR(255),
  ref_no VARCHAR(255) UNIQUE,
  vehicle_no VARCHAR(255),
  vehicle_type VARCHAR(255),
  category VARCHAR(255),
  manufacture_year VARCHAR(50),
  rate FLOAT,
  from_date DATE,
  to_date DATE,
  working_days INT,
  km_run INT,
  rental FLOAT,
  ot_hrs INT,
  ot_amount FLOAT,
  overnight INT,
  overnight_amount FLOAT,
  excess_km INT,
  excess_amount FLOAT,
  absent_total INT,
  absent_deduct_amount FLOAT,
  total FLOAT,
  tax_18_percent FLOAT,
  grand_total FLOAT,
  supplier VARCHAR(255),
  District VARCHAR(255),
  fuel_type VARCHAR(50),
  accept_role VARCHAR(50),
  rate_category VARCHAR(50),
  rate_period VARCHAR(50),
  created_date DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  `;
  await db.query(createTableSQL);
}

// Insert data
async function insertData(tableName, data) {
  if (!Array.isArray(data) || data.length === 0) return;

  const columns = [
     "ser_no",
      "type",
     "user",
  "dgm",
  "gm",
  "cost_center",
  "ref_no",
  "vehicle_no",
  "vehicle_type",
  "category",
  "manufacture_year",
  "rate",
  "from_date",
  "to_date",
  "working_days",
  "km_run",
  "rental",
  "ot_hrs",
  "ot_amount",
  "overnight",
  "overnight_amount",
  "excess_km",
  "excess_amount",
  "absent_total",
  "absent_deduct_amount",
  "total",
  "tax_18_percent",
  "grand_total",
  "supplier",
  "District",
  "fuel_type",
  "accept_role",
  "created_date",
  "rate_category",
  "rate_period",
  ];

  const placeholders = data
    .map(() => "(" + columns.map(() => "?").join(",") + ")")
    .join(",");
  const values = data.flatMap((row) => columns.map((col) => row[col] || null));

  const sql = `INSERT INTO \`${tableName}\` (${columns.join(
    ","
  )}) VALUES ${placeholders}`;
  await db.query(sql, values);
}

async function getDetailsByRefNo(refNo) {
  const [rows] = await db.query(
    `SELECT * FROM vehicle_records WHERE ref_No = ? LIMIT 1`,
    [refNo]
  );
  console.log("Fetched Details for", refNo, rows[0]);
  return rows[0]; 
  // might be undefined
}

module.exports = {
  checkTableExists,
  createTable,
  insertData,
  getDetailsByRefNo,
};
