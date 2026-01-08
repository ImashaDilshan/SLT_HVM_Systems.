const db = require("../config/db");

async function removeRoleStep(req, res) {
  try {
    const { tableName, location, mode, role, newRole } = req.body;

    console.log("❌ Remove Step Payload:", tableName, location, mode, role, newRole);

    if (newRole !== "Remove") {
      return res.status(400).json({
        success: false,
        message: `❌ newRole must be 'Remove' to proceed.`,
      });
    }

    const allowedRolesToRemove = ["level01", "level02"];
    if (!allowedRolesToRemove.includes(role)) {
      return res.status(403).json({
        success: false,
        message: `🚫 Only users with role 'level02' or 'admin' can remove.`,
      });
    }

    // 1. Check if target table exists
    const [tableCheck] = await db.query("SHOW TABLES LIKE ?", [tableName]);
    if (tableCheck.length === 0) {
      return res.status(404).json({
        success: false,
        message: `❌ Table '${tableName}' not found.`,
      });
    }

    // 2. Determine target log table
    let targetTable;
    if (mode === "Self Vehicles") {
      targetTable = "self_vehicals";
    } else if (mode === "Non Self Vehicles") {
      targetTable = "non_self_vehicals";
    } else if (mode === "Short Period") {
      targetTable = "short_period_vehicals";
    } else {
      return res.status(400).json({
        success: false,
        message: `❌ Unknown mode: '${mode}'`,
      });
    }

    // 3. Update accept_role in the main table to 'Remove'
    const [updateResult] = await db.query(`
      UPDATE \`${tableName}\`
      SET accept_role = ?
      WHERE cost_center = ? AND type = ? AND accept_role = ?
    `, ["Remove", location, mode, role]);

    console.log(`🧹 Removed ${updateResult.affectedRows} row(s).`);

    // 4. Update or insert log with role = 'Remove'
    if (updateResult.affectedRows > 0) {
      const [existing] = await db.query(`
        SELECT id FROM \`${targetTable}\`
        WHERE cost_center = ? AND month = ?
        LIMIT 1
      `, [location, tableName]);

      if (existing.length > 0) {
        await db.query(`
          UPDATE \`${targetTable}\`
          SET role = ?, date = CURDATE()
          WHERE cost_center = ? AND month = ?
        `, ["Remove", location, tableName]);
        console.log(`📝 Updated log entry to 'Remove'`);
      } else {
        await db.query(`
          INSERT INTO \`${targetTable}\` (cost_center, month, role, date)
          VALUES (?, ?, ?, CURDATE())
        `, [location, tableName, "Remove"]);
        console.log(`➕ Inserted new log with role = 'Remove'`);
      }
    }

    res.json({
      success: true,
      message: `✅ ${updateResult.affectedRows} record(s) updated to 'Remove'.`,
    });

  } catch (err) {
    console.error("❌ Error during role removal:", err);
    res.status(500).json({
      success: false,
      message: "Server error while removing role.",
    });
  }
}

module.exports = {
  removeRoleStep,
};
