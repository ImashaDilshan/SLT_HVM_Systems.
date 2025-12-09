const express = require('express');
const router = express.Router();
const vehicleController = require('../controllers/vehicleController');

// GET /vehicles/:costCenter
router.get('/:costCenter', vehicleController.getByCostCenter);

module.exports = router;
