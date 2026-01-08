const pool = require("../config/db");

exports.getAllVehicles = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT f.ref_no, f.vehicle_no, f.user, f.dgm, f.gm, f.cost_center,
              f.fuel_type, f.manuf_year, vc.category_name, f.category_code
       FROM fleet_vehicles f
       JOIN vehicle_categories vc ON f.category_code = vc.category_code
       ORDER BY f.ref_no`
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.addVehicle = async (req, res) => {
  const {
    ref_no,
    vehicle_no,
    user,
    dgm,
    gm,
    cost_center,
    fuel_type,
    manuf_year,
    category_code,
  } = req.body;

  try {
    await pool.query(
      `INSERT INTO fleet_vehicles 
       (ref_no, vehicle_no, user, dgm, gm, cost_center, fuel_type, manuf_year, category_code)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        ref_no,
        vehicle_no,
        user,
        dgm,
        gm,
        cost_center,
        fuel_type,
        manuf_year,
        category_code,
      ]
    );
    res.json({ message: "Vehicle added successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
