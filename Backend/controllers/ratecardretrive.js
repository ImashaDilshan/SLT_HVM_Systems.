// controllers/rateCardController.js
const db = require('../config/db');

// GET /api/rates/versions
// Returns list of all unique rate card versions
exports.getRateCardVersions = async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT DISTINCT 
        version_no,
        target_month,
        base_id,
        MAX(id) as id
      FROM calculated_rate_cards 
      GROUP BY version_no, target_month 
      ORDER BY id DESC
    `);

    return res.json({ versions: rows });
  } catch (error) {
    console.error('Error fetching versions:', error);
    return res.status(500).json({ error: 'Failed to fetch rate card versions' });
  }
};

// GET /api/rates/by-version?version=...
// Returns all rate cards for a specific version
exports.getRatesByVersion = async (req, res) => {
  const { version } = req.query;

  if (!version) {
    return res.status(400).json({ error: 'Version is required' });
  }

  try {
    const [rows] = await db.execute(`
      SELECT 
        category_code,
        yom_category,
        km_slab,
        max_distance,
        new_rental
      FROM calculated_rate_cards 
      WHERE version_no = ?
      ORDER BY category_code, yom_category, max_distance
    `, [version]);

    if (rows.length === 0) {
      return res.status(404).json({ message: 'No rates found for this version.' });
    }

    // ✅ Move grouping logic BEFORE sending response
    const grouped = {};
    rows.forEach(row => {
      const key = `${row.category_code}-${row.yom_category}`;
      if (!grouped[key]) {
        grouped[key] = {
          category_code: row.category_code,
          yom_category: row.yom_category,
          slabs: []
        };
      }
      grouped[key].slabs.push({
        km_slab: row.km_slab,
        max_distance: row.max_distance,
        monthly_rental: parseFloat(row.new_rental)
      });
    });

    // ✅ Correct way to send grouped data
    res.json({ data: Object.values(grouped) });

  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};