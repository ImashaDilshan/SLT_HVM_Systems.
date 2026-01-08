const ratecardService = require('../models/ratecardServiceNew');

exports.upsertRateCard = async (req, res) => {
  try {
    const { name, status, effectiveMonthDate, rateRecords } = req.body;

    if (!name || !effectiveMonthDate || !rateRecords || !Array.isArray(rateRecords)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid request: name, effectiveMonthDate, and rateRecords array required'
      });
    }

    const result = await ratecardService.upsertRateCardWithDetails({
      name,
      status: status || 'active',
      effectiveMonthDate,
      rateRecords
    });

    res.status(result.operation === 'updated' ? 200 : 201).json({
      success: true,
      message: `Rate card ${result.operation} successfully with ${result.totalRecords} records`,
      data: {
        ratecardId: result.ratecardId,
        name: result.name,
        operation: result.operation,
        totalRecords: result.totalRecords
      }
    });

  } catch (error) {
    console.error('Rate card processing error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to process rate card'
    });
  }
}