const rateCardService = require('../models/rateCardService');

class RateCardController {
  async calculateRateCard(req, res) {
    try {
      const { diesel_price, petrol_price } = req.body;

      if (!diesel_price || !petrol_price) {
        return res.status(400).json({
          error: 'Diesel price and petrol price are required'
        });
      }

      const result = await rateCardService.calculateNewRateCard(
        parseFloat(diesel_price),
        parseFloat(petrol_price)
      );

      res.json({
        success: true,
        message: 'Rate card calculated successfully',
        data: result
      });

    } catch (error) {
      console.error('Error calculating rate card:', error);
      if (error.message.includes('Unknown column')) {
      res.status(500).json({ 
        error: 'Database schema issue. Please check if all required columns exist.' 
      });
    } else if (error.message.includes('No active base rate card')) {
      res.status(404).json({ 
        error: 'No base rate card found. Please add a base rate card first.' 
      });
    } else {
      res.status(500).json({ error: error.message });
    }
  }
  }

  async getCalculatedRateCards(req, res) {
    try {
      const rateCards = await rateCardService.getCalculatedRateCards();
      res.json({
        success: true,
        data: rateCards
      });
    } catch (error) {
      console.error('Error fetching calculated rate cards:', error);
      res.status(500).json({
        error: error.message
      });
    }
  }

  async getCalculatedRateSlabs(req, res) {
    try {
      const { id } = req.params;
      const slabs = await rateCardService.getCalculatedRateSlabs(parseInt(id));
      res.json({
        success: true,
        data: slabs
      });
    } catch (error) {
      console.error('Error fetching calculated rate slabs:', error);
      res.status(500).json({
        error: error.message
      });
    }
  }

  async getLatestBaseRateCard(req, res) {
    try {
      const baseRateCard = await rateCardService.getLatestBaseRateCard();
      res.json({
        success: true,
        data: baseRateCard
      });
    } catch (error) {
      console.error('Error fetching base rate card:', error);
      res.status(500).json({
        error: error.message
      });
    }
  }
  async getCategories(req, res) {
  try {
    const { calculatedCardId, yomCategory } = req.params;
    const categories = await rateCardService.getCategories(
      parseInt(calculatedCardId),
      yomCategory
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

async getFuelTypes(req, res) {
  try {
    const { calculatedCardId, yomCategory, categoryCode, serviceType } = req.params;
    const fuelTypes = await rateCardService.getFuelTypes(
      parseInt(calculatedCardId),
      yomCategory,
      categoryCode,
      serviceType
    );
    
    res.json({
      success: true,
      data: fuelTypes
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
}

async calculateRental(req, res) {
  try {
    const {
      calculatedCardId,
      yomCategory,
      categoryCode,
      serviceType,
      fuelType,
      workingDays,
      kmRun,
      overtimeHours,
      overnightStays,
      absentDays
    } = req.body;

    // Find the applicable slab with 15% rule
    const slabResult = await rateCardService.findApplicableSlabWith15PercentRule(
      parseInt(calculatedCardId),
      yomCategory,
      categoryCode,
      serviceType,
      fuelType,
      parseInt(kmRun)
    );

    if (!slabResult) {
      return res.status(404).json({
        success: false,
        error: 'No applicable rate slab found for the given parameters'
      });
    }

    const slab = slabResult.slab;
    
    // Parse numeric values
    const monthlyRental = parseFloat(slab.monthly_rental) || 0;
    const additionalKmRate = parseFloat(slab.additional_km_rate) || 0;
    const overtimeRate = parseFloat(slab.overtime_rate) || 0;
    const nightAllowance = parseFloat(slab.night_allowance) || 0;
    const maxDistance = parseInt(slab.max_distance) || 0;

    // Calculate base rental
    const dailyRental = monthlyRental / 30;
    const baseRental = dailyRental * parseInt(workingDays);

    // Calculate excess KM amount with 15% rule
    let excessKmAmount = 0;
    let excessDetails = {
      withinAllowance: 0,
      beyondAllowance: 0,
      rateWithin: additionalKmRate,
      rateBeyond: additionalKmRate * 1.5 // 50% higher penalty rate
    };

    if (slabResult.actualExcess > 0) {
      const fifteenPercentAllowance = Math.floor(maxDistance * 0.15);
      
      if (slabResult.actualExcess <= fifteenPercentAllowance) {
        // Within 15% allowance - regular rate
        excessKmAmount = slabResult.actualExcess * additionalKmRate;
        excessDetails.withinAllowance = slabResult.actualExcess;
      } else {
        // Beyond 15% allowance - penalty rate for excess beyond 15%
        const beyondAllowanceExcess = slabResult.actualExcess - fifteenPercentAllowance;
        excessKmAmount = (fifteenPercentAllowance * additionalKmRate) + 
                         (beyondAllowanceExcess * (additionalKmRate * 1.5));
        excessDetails.withinAllowance = fifteenPercentAllowance;
        excessDetails.beyondAllowance = beyondAllowanceExcess;
      }
    }

    // Calculate other amounts
    const overtimeAmount = parseInt(overtimeHours) * overtimeRate;
    const overnightAmount = parseInt(overnightStays) * nightAllowance;
    const absentDeduction = parseInt(absentDays) * dailyRental;

    // Calculate subtotal
    const subtotal = baseRental + overtimeAmount + overnightAmount + excessKmAmount - absentDeduction;

    // Calculate tax (18%)
    const taxAmount = subtotal * 0.18;

    // Calculate grand total
    const grandTotal = subtotal + taxAmount;

    res.json({
      success: true,
      data: {
        baseRental,
        overtimeAmount,
        overnightAmount,
        excessKmAmount,
        excessDetails, // Detailed breakdown of excess KM
        absentDeduction,
        subtotal,
        taxAmount,
        grandTotal,
        applicableSlab: slab,
        fifteenPercentRuleApplied: slabResult.actualExcess > 0,
        allowedExcess: slabResult.allowedExcess,
        actualExcess: slabResult.actualExcess
      }
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