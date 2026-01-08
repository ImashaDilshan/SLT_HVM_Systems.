const RateCard = require('../models/ratecardCalculateModel');

const calculateRates = async (req, res) => {
  try {
    const inputs = req.body; // Expect array of inputs
    if (!Array.isArray(inputs)) {
      return res.status(400).json({ error: "Input must be an array" });
    }

    const results = await RateCard.calculateBatch(inputs);
    res.json(results);
  } catch (err) {
    console.error("🚫 Error:", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

module.exports = { calculateRates };