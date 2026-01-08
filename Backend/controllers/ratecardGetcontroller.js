// controllers/rateCardController.js
const rateCardService = require('../models/GetRateCardService');

class RateCardController {
  async getCalculatedRateCards(req, res) {
    try {
      const rateCards = await rateCardService.getCalculatedRateCards();
      res.json({
        success: true,
        data: rateCards
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getRateCardDetails(req, res) {
    try {
      const { id } = req.params;
      const rateCard = await rateCardService.getCalculatedRateCardById(parseInt(id));
      const slabs = await rateCardService.getCalculatedRateSlabs(parseInt(id));
      
      res.json({
        success: true,
        data: {
          rateCard,
          slabs
        }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getRateSlabsByYomCategory(req, res) {
    try {
      const { calculatedCardId, yomCategory } = req.params;
      const slabs = await rateCardService.getRateSlabsByYomCategory(
        parseInt(calculatedCardId),
        yomCategory
      );
      
      res.json({
        success: true,
        data: slabs
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  // NEW: Get organized data by service type, category, fuel type
  async getOrganizedSlabs(req, res) {
    try {
      const { calculatedCardId, yomCategory } = req.params;
      const organizedData = await rateCardService.getOrganizedSlabs(
        parseInt(calculatedCardId),
        yomCategory
      );
      
      res.json({
        success: true,
        data: organizedData
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  // NEW: Get distinct service types for a YOM category
  async getServiceTypes(req, res) {
    try {
      const { calculatedCardId, yomCategory } = req.params;
      const serviceTypes = await rateCardService.getServiceTypes(
        parseInt(calculatedCardId),
        yomCategory
      );
      
      res.json({
        success: true,
        data: serviceTypes
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
   async getCategoriesByServiceType(req, res) {
    try {
      const { calculatedCardId, yomCategory, serviceType } = req.params;
      const categories = await rateCardService.getCategoriesByServiceType(
        parseInt(calculatedCardId),
        yomCategory,
        serviceType
      );
      
      res.json({
        success: true,
        data: categories
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

}


module.exports = new RateCardController();