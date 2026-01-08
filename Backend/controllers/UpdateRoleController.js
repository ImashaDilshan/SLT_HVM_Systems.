const { log } = require("node:console");
const db = require("../config/db");

async function bulkUpdateRole(req, res) {
  try {
    const { tableName, location, mode, role, newRole } = req.body;

    console.log("🔄 Payload:", tableName, location, mode, role, newRole);

    // 1. Check if the target table (e.g., 2025_june) exists
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
    }

    // 3. Enforce step-by-step role upgrade logic
    if (targetTable) {
      const [logExists] = await db.query(`
    SELECT role FROM \`${targetTable}\`
    WHERE cost_center = ? AND month = ?
    LIMIT 1
  `, [location, tableName]);

      const roleOrder = ["Moderetor", "level01", "level02", "admin"];
      const newRoleIndex = roleOrder.indexOf(newRole);
      const currentRoleIndex = roleOrder.indexOf(role);

      if (logExists.length > 0) {
        const existingRole = logExists[0].role;
        const existingIndex = roleOrder.indexOf(existingRole);
       console.log(`Existing role for ${location} in ${tableName}: ${existingRole} ${newRole}`);
        if (existingRole === "Remove") {
          if (newRole !== "level01") {
            return res.status(403).json({
              success: false,
              message: `🚫 Cannot upgrade from 'Remove' to '${newRole}'. Start from 'Moderetor'.`,
            });
          }
        } else {
          if (newRoleIndex !== existingIndex + 1) {
            return res.status(403).json({
              success: false,
              message: `🚫 Invalid upgrade. Current role is '${existingRole}', allowed next role is '${roleOrder[existingIndex + 1]}'.`,
            });
          }
        }
      }
    }
let acceptRoles = [role];
if (role === "Moderetor") {
  acceptRoles = ["Moderetor", "Remove"];
}
    // 4. Find matching rows in the main table
    const [rows] = await db.query(`
      SELECT ser_no FROM \`${tableName}\`
      WHERE cost_center = ? AND type = ? AND accept_role IN (?)
    `, [location, mode, acceptRoles]);

    if (rows.length === 0) {
      console.log("⚠️ No matching rows found to update.");
      return res.status(400).json({
        success: false,
        message: "⚠️ No matching rows found to update.",
      });
    }

    // 5. Update accept_role in the main table
    const [updateResult] = await db.query(`
      UPDATE \`${tableName}\`
      SET accept_role = ?
      WHERE cost_center = ? AND type = ? AND accept_role IN (?)
    `, [newRole, location, mode, acceptRoles]);

    console.log(`✅ Updated ${updateResult.affectedRows} row(s).`);

    // 6. Log the update in the target log table (update or insert)
    if (targetTable && updateResult.affectedRows > 0) {
      const [existing] = await db.query(`
        SELECT id FROM \`${targetTable}\`
        WHERE cost_center = ? AND month = ?
        LIMIT 1
      `, [location, tableName]);

      if (existing.length > 0) {
        // UPDATE existing log entry
        await db.query(`
          UPDATE \`${targetTable}\`
          SET role = ?, date = CURDATE()
          WHERE cost_center = ? AND month = ?
        `, [newRole, location, tableName]);
        console.log(`🔁 Updated existing entry in ${targetTable}`);
      } else {
        // INSERT new log entry (fallback, although this should not happen due to check above)
        await db.query(`
          INSERT INTO \`${targetTable}\` (cost_center, month, role, date)
          VALUES (?, ?, ?, CURDATE())
        `, [location, tableName, newRole]);
        console.log(`🟢 Inserted into ${targetTable}`);
      }
    }

    res.json({
      success: true,
      message: `✅ ${updateResult.affectedRows} record(s) updated to role '${newRole}'.`,
    });

  } catch (err) {
    console.error("❌ Error during role update:", err);
    res.status(500).json({
      success: false,
      message: "Server error while updating roles.",
    });
  }
}

module.exports = {
  bulkUpdateRole,
};
