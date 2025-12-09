// controllers/userAdminController.js
const db = require('../config/db');

// ✅ Create User + Cost Centers in single transaction
exports.createUserWithCostCenters = async (req, res) => {
  const { uid, name, role, position, costCenters } = req.body;

  // Basic validation
  if (!uid || !name || !role || !position) {
    return res.status(400).json({
      success: false,
      message: 'uid, name, role, and position are required'
    });
  }

  if (!Array.isArray(costCenters) || costCenters.length === 0) {
    return res.status(400).json({
      success: false,
      message: 'costCenters array is required and cannot be empty'
    });
  }

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    // 1️⃣ Insert user
    const [userResult] = await conn.query(
      `INSERT INTO users (uid, name, role, position) VALUES (?, ?, ?, ?)`,
      [uid, name, role, position]
    );

    const newUserId = userResult.insertId;

    // 2️⃣ Insert cost centers
    const values = costCenters.map(cc => [
      cc.cost_center_id,
      newUserId,
      cc.region,
      cc.cost_center_name
    ]);

    await conn.query(
      `INSERT INTO cost_centers (cost_center_id, user_id, regon, cost_center_name) VALUES ?`,
      [values]
    );

    await conn.commit();

    res.json({
      success: true,
      message: 'User and cost centers created successfully',
      user: { id: newUserId, uid, name, role, position },
      costCenters
    });
  } catch (err) {
    await conn.rollback();
    console.error('❌ createUserWithCostCenters error:', err);
    res.status(500).json({
      success: false,
      message: 'Failed to create user with cost centers'
    });
  } finally {
    conn.release();
  }
};
