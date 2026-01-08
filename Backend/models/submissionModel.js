const db = require('../config/db');

function getTableFromMode(mode) {
  const normalized = mode.trim().toLowerCase();
  console.log("🔍 Normalized mode:", normalized);
  
  switch (normalized) {
    case 'self vehicles':
      return 'self_vehicals';
    case 'non self vehicles':
      return 'non_self_vehicals';
    case 'short period':
      return 'short_period_vehicals';
    default:
      return null;
  }
}

async function getSubmissionRole(costCenterId, month, mode) {
  const table = getTableFromMode(mode);
  if (!table) throw new Error(`❌ Invalid mode: ${mode}`);

  console.log("🟢 Input received:", { costCenterId, month, mode, table });

  // Get the role instead of counting
  const [rows] = await db.query(
    `SELECT role FROM \`${table}\` WHERE cost_center = ? AND month = ? LIMIT 1`,
    [costCenterId, month]
  );

  console.log("📊 DB result:", rows);

  const role = rows?.[0]?.role ?? null;
  console.log("✅ Parsed role:", role);

  return role; // Return the role or null
}

module.exports = {
  getSubmissionRole,
};