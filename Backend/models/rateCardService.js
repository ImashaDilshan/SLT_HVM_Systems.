const pool = require("../config/db");
const FuelCalculator = require('../utils/fuelCalculator'); 

class RateCardService {
  async getLatestBaseRateCard() {
    const query = `
      SELECT * FROM rate_card_base 
      WHERE status = 'ACTIVE' 
      ORDER BY effective_date DESC 
      LIMIT 1
    `;
    
    // ✅ MySQL2 returns [rows, fields] format
    const [rows] = await pool.query(query);
    
    console.log('MySQL query result:', rows); // Debug log
    
    if (!rows || rows.length === 0) {
      throw new Error('No active base rate card found in database');
    }
    
    return rows[0];
  }

  async getRateCardSlabs(baseId) {
    const query = 'SELECT * FROM rate_card_slabs WHERE base_id = ?';
    
    // ✅ MySQL2 uses ? for parameters
    const [rows] = await pool.query(query, [baseId]);
    
    return rows;
  }

async calculateNewRateCard(newDieselPrice, newPetrolPrice) {
  const baseRateCard = await this.getLatestBaseRateCard();
  
  if (!baseRateCard) {
    throw new Error('No active base rate card found');
  }

  const baseSlabs = await this.getRateCardSlabs(baseRateCard.id);
  
  const calculatedSlabs = FuelCalculator.calculateNewRates(
    baseSlabs,
    Number(baseRateCard.diesel_price),  // 286.00
    Number(baseRateCard.petrol_price),  // 309.00
    newDieselPrice,
    newPetrolPrice
  );

  // Save calculated rate card
  const calculatedCardQuery = `
    INSERT INTO calculated_rate_cards (base_id, calculation_date, new_diesel_price, new_petrol_price)
    VALUES (?, CURRENT_DATE, ?, ?)
  `;
  
  const [calculatedCardResult] = await pool.query(calculatedCardQuery, [
    baseRateCard.id,
    newDieselPrice,
    newPetrolPrice
  ]);

  const calculatedCardId = calculatedCardResult.insertId;

  // Save calculated slabs - PRESERVE YOM_CATEGORY
  for (const slab of calculatedSlabs) {
    const slabQuery = `
      INSERT INTO calculated_rate_slabs (
        calculated_card_id, category_code, yom_category, km_slab, max_distance,
        monthly_rental, additional_km_rate, overtime_rate, night_allowance,
        rate_type, service_type, fuel_type
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    await pool.query(slabQuery, [
      calculatedCardId,
      slab.category_code,
      slab.yom_category, // ✅ This was missing!
      slab.km_slab,
      slab.max_distance,
      slab.monthly_rental,
      slab.additional_km_rate,
      slab.overtime_rate,
      slab.night_allowance,
      slab.rate_type,
      slab.service_type,
      slab.fuel_type
    ]);
  }

  return {
    calculatedCard: {
      id: calculatedCardId,
      base_id: baseRateCard.id,
      calculation_date: new Date(),
      new_diesel_price: newDieselPrice,
      new_petrol_price: newPetrolPrice
    },
    slabs: calculatedSlabs
  };
}

  async getCalculatedRateCards() {
    const query = `
      SELECT crc.*, rcb.name as base_name, rcb.effective_date as base_effective_date
      FROM calculated_rate_cards crc
      JOIN rate_card_base rcb ON crc.base_id = rcb.id
      ORDER BY crc.created_at DESC
    `;
    
    const [rows] = await pool.query(query);
    return rows;
  }

  async getCalculatedRateSlabs(calculatedCardId) {
    const query = 'SELECT * FROM calculated_rate_slabs WHERE calculated_card_id = ?';
    
    const [rows] = await pool.query(query, [calculatedCardId]);
    return rows;
  }
  async getCategories(calculatedCardId, yomCategory) {
  const query = `
    SELECT DISTINCT category_code 
    FROM calculated_rate_slabs 
    WHERE calculated_card_id = ? AND yom_category = ?
    ORDER BY category_code
  `;
  
  const [rows] = await pool.query(query, [calculatedCardId, yomCategory]);
  return rows.map(row => row.category_code);
}

async getServiceTypes(calculatedCardId, yomCategory) {
  const query = `
    SELECT DISTINCT service_type 
    FROM calculated_rate_slabs 
    WHERE calculated_card_id = ? AND yom_category = ?
    ORDER BY service_type
  `;
  
  const [rows] = await pool.query(query, [calculatedCardId, yomCategory]);
  return rows.map(row => row.service_type);
}

async getFuelTypes(calculatedCardId, yomCategory, categoryCode, serviceType) {
  const query = `
    SELECT DISTINCT COALESCE(fuel_type, 'GENERAL') as fuel_type 
    FROM calculated_rate_slabs 
    WHERE calculated_card_id = ? AND yom_category = ? AND category_code = ? AND service_type = ?
    ORDER BY fuel_type
  `;
  
  const [rows] = await pool.query(query, [calculatedCardId, yomCategory, categoryCode, serviceType]);
  return rows.map(row => row.fuel_type);
}

async findApplicableSlabWith15PercentRule(calculatedCardId, yomCategory, categoryCode, serviceType, fuelType, kmRun) {
  const query = `
    SELECT * FROM calculated_rate_slabs 
    WHERE calculated_card_id = ? AND yom_category = ? AND category_code = ? 
      AND service_type = ? AND (fuel_type = ? OR fuel_type IS NULL)
    ORDER BY 
      CASE 
        WHEN fuel_type = ? THEN 0 
        ELSE 1 
      END,
      km_slab
  `;
  
  const [rows] = await pool.query(query, [
    calculatedCardId, yomCategory, categoryCode, serviceType, fuelType, fuelType
  ]);
  
  // Find the slab that matches the KM range with 15% rule
  for (const slab of rows) {
    const range = slab.km_slab.split('-');
    if (range.length === 2) {
      const minKm = parseInt(range[0]);
      const maxKm = parseInt(range[1]);
      const fifteenPercentAllowance = Math.floor(maxKm * 0.15);
      
      // Check if KM run is within slab + 15% allowance
      if (kmRun >= minKm && kmRun <= (maxKm + fifteenPercentAllowance)) {
        return {
          slab: slab,
          excessType: kmRun > maxKm ? 'within_15_percent' : 'within_slab',
          allowedExcess: fifteenPercentAllowance,
          actualExcess: Math.max(0, kmRun - maxKm)
        };
      }
    }
  }
  
  return null;
}
}

module.exports = new RateCardService();