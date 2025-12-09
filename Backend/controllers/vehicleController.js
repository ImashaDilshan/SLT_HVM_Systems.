const Vehicle = require('../models/vehicleModel');

const getByCostCenter = async (req, res) => {
  const costCenter = req.params.costCenter;

  try {
    const vehicles = await Vehicle.getVehiclesByCostCenter(costCenter);
    res.json(vehicles);
  } catch (err) {
    console.error('🚫 Error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

module.exports = {
  getByCostCenter
};