// controllers/tableSummaryController.js
const db = require("../config/db");

function safeTableName(name) {
  const n = String(name || "");
  if (!/^[a-zA-Z0-9_]+$/.test(n)) throw new Error("Invalid table name");
  return n;
}
function round2(n) {
  return Math.round((Number(n || 0) + Number.EPSILON) * 100) / 100;
}
function to2(n) {
  return Number(Number(n || 0).toFixed(2));
}

/**
 * POST /api/table-summary
 * Body:
 * {
 *   "table": "2025_july",
 *   "filters": { "accept_role": "admin", "supplier": "..." },
 *   "includeVAT": true,
 *   "vatPercent": 18,
 *   "advancedPercent": 90,
 *   // OR advancedAmount
 * }
 */
exports.summarizeWithRows = async (req, res) => {
  try {
    const {
      table,
      filters = {},
      includeVAT = true,
      vatPercent = 18,
      advancedPercent = 90,
      advancedAmount = null,
    } = req.body || {};

    if (!table) return res.status(400).json({ error: "table is required" });
    const tableName = safeTableName(table);
    
    // Check if table exists
    const [tableExists] = await db.query(`SHOW TABLES LIKE ?`, [tableName]);
    if (tableExists.length === 0) {
       return res.json({ rows: [], summary: {
          rentalAmount: 0,
          otAmount: 0,
          overnightAmount: 0,
          excessAmount: 0,
          total: 0,
          absentDeduction: 0,
          absentAfterTotal: 0,
          advanceLabel: "0% Advanced Amount",
          advanceAmount: 0,
          balanceAfterAdvance: 0,
          includeVAT: !!includeVAT,
          vatPercent: Number(vatPercent || 0),
          vatAmount: 0,
          netAmount: 0,
          table: tableName,
          filters,
          rowCount: 0
       }});
    }

    // WHERE clause
    const whereParts = [];
    const params = [];
    if (filters && typeof filters === "object") {
      for (const [k, v] of Object.entries(filters)) {
        if (!/^[a-zA-Z0-9_]+$/.test(k)) continue;
        if (v === undefined || v === null || v === "") continue;
        whereParts.push(`\`${k}\` = ?`);
        params.push(String(v));
      }
    }
    const whereClause = whereParts.length ? `WHERE ${whereParts.join(" AND ")}` : "";

    /* --- 1. Get all rows --- */
    const [rows] = await db.execute(
      `SELECT * FROM ${tableName} t ${whereClause} ORDER BY ser_no ASC`,
      params
    );

    /* --- 2. Aggregate sums from those rows --- */
    let rental = 0,
      ot = 0,
      overnight = 0,
      excess = 0,
      absent = 0;

    for (const r of rows) {
      rental += Number(r.rental || 0);
      ot += Number(r.ot_amount || 0);
      overnight += Number(r.overnight_amount || 0);
      excess += Number(r.excess_amount || 0);
      absent += Number(r.absent_deduct_amount || 0);
    }

    const total = rental + ot + overnight + excess;
    const totalAfterAbsent = Math.max(0, total - absent);

    // Advance
    let advanceUsed;
    if (advancedAmount != null && !isNaN(advancedAmount)) {
      advanceUsed = Math.max(0, Math.min(totalAfterAbsent, Number(advancedAmount)));
    } else {
      advanceUsed = Math.max(
        0,
        round2(totalAfterAbsent * Number(advancedPercent || 0) / 100)
      );
    }

    const balanceAfterAdvance = Math.max(0, totalAfterAbsent - advanceUsed);
    const vat = includeVAT ? round2(balanceAfterAdvance * Number(vatPercent || 0) / 100) : 0;
    const netAmount = round2(balanceAfterAdvance + vat);

    const summary = {
      rentalAmount: to2(rental),
      otAmount: to2(ot),
      overnightAmount: to2(overnight),
      excessAmount: to2(excess),
      total: to2(total),
      absentDeduction: to2(absent),
      absentAfterTotal: to2(totalAfterAbsent),
      advanceLabel:
        advancedAmount != null
          ? "Advanced Amount"
          : `${Number(advancedPercent || 0)}% Advanced Amount`,
      advanceAmount: to2(advanceUsed),
      balanceAfterAdvance: to2(balanceAfterAdvance),
      includeVAT: !!includeVAT,
      vatPercent: Number(vatPercent || 0),
      vatAmount: to2(vat),
      netAmount: to2(netAmount),
      table: tableName,
      filters,
      rowCount: rows.length,
    };

    return res.json({ rows, summary });
  } catch (err) {
    console.error("summarizeWithRows error:", err);
    return res.status(500).json({ error: "Internal Server Error" });
  }
};
