const fuelRateService = require('../models/fuelRateservice');

exports.calculateAllActiveRates = async (req, res) => {
  try {
    const { dieselPrice, petrolPrice, calculationDate } = req.body;

    // Defensive validation
    if (dieselPrice === undefined || petrolPrice === undefined || !calculationDate) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: dieselPrice, petrolPrice, calculationDate'
      });
    }

    // Convert to numbers to prevent type issues
    const diesel = parseFloat(dieselPrice);
    const petrol = parseFloat(petrolPrice);

    if (isNaN(diesel) || isNaN(petrol)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid fuel prices: must be numbers'
      });
    }

    const results = await fuelRateService.calculateAllRateCards({
      dieselPrice: diesel,
      petrolPrice: petrol,
      calculationDate
    });

    res.status(201).json({
      success: true,
      message: `Successfully processed ${results.length} active rate cards`,
      data: results
    });

  } catch (error) {
    console.error('Fuel rate calculation failed:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Internal server error during fuel rate calculation'
    });
  }
};