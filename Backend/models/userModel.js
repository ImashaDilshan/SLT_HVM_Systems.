const db = require('../config/db');

async function getUserWithCostCenters(uid) {
  const [userRows] = await db.execute('SELECT * FROM users WHERE uid = ?', [uid]);
  if (userRows.length === 0) throw new Error('User not found');

  const user = userRows[0];
  const [costCenters] = await db.execute(
    'SELECT cost_center_id, cost_center_name, regon FROM cost_centers WHERE user_id = ?',
    [user.id]
  );

  return {
    id: user.id,
    name: user.name,
    role: user.role,
    position: user.position,
    cost_centers: costCenters,
  };
}

module.exports = {
  getUserWithCostCenters,
};
