// services/rateCardService.js
const pool = require("../config/db");

class RateCardService {
  async getCalculatedRateCards() {
    const query = `
      SELECT crc.*, rcb.name as base_name, rcb.effective_date as base_effective_date
      FROM calculated_rate_cards crc
      JOIN rate_card_base rcb ON crc.base_id = rcb.id
      WHERE crc.status = 'ACTIVE'
      ORDER BY crc.calculation_date DESC
    `;
    
    const [rows] = await pool.query(query);
    return rows;
  }

  async getCalculatedRateCardById(id) {
    const query = `
      SELECT crc.*, rcb.name as base_name, rcb.effective_date as base_effective_date
      FROM calculated_rate_cards crc
      JOIN rate_card_base rcb ON crc.base_id = rcb.id
      WHERE crc.id = ? AND crc.status = 'ACTIVE'
    `;
    
    const [rows] = await pool.query(query, [id]);
    return rows[0];
  }

  async getCalculatedRateSlabs(calculatedCardId) {
    const query = `
      SELECT * FROM calculated_rate_slabs 
      WHERE calculated_card_id = ?
      ORDER BY 
        yom_category,
        category_code,
        service_type,
        fuel_type,
        rate_type,
        km_slab
    `;
    
    const [rows] = await pool.query(query, [calculatedCardId]);
    return rows;
  }

  async getRateSlabsByYomCategory(calculatedCardId, yomCategory) {
    const query = `
      SELECT * FROM calculated_rate_slabs 
      WHERE calculated_card_id = ? AND yom_category = ?
      ORDER BY category_code, service_type, fuel_type, rate_type, km_slab
    `;
    
    const [rows] = await pool.query(query, [calculatedCardId, yomCategory]);
    return rows;
  }

  // NEW: Get organized data structure
  async getOrganizedSlabs(calculatedCardId, yomCategory) {
    const query = `
      SELECT * FROM calculated_rate_slabs 
      WHERE calculated_card_id = ? AND yom_category = ?
      ORDER BY service_type, category_code, fuel_type, rate_type, km_slab
    `;
    
    const [rows] = await pool.query(query, [calculatedCardId, yomCategory]);
    
    // Organize data: serviceType -> categoryCode -> fuelType -> rateType
    const organizedData = {};
    
    rows.forEach(slab => {
      const serviceType = slab.service_type;
      const categoryCode = slab.category_code;
      const fuelType = slab.fuel_type || 'GENERAL';
      const rateType = slab.rate_type;
      
      if (!organizedData[serviceType]) {
        organizedData[serviceType] = {};
      }
      
      if (!organizedData[serviceType][categoryCode]) {
        organizedData[serviceType][categoryCode] = {};
      }
      
      if (!organizedData[serviceType][categoryCode][fuelType]) {
        organizedData[serviceType][categoryCode][fuelType] = {};
      }
      
      if (!organizedData[serviceType][categoryCode][fuelType][rateType]) {
        organizedData[serviceType][categoryCode][fuelType][rateType] = [];
      }
      
      organizedData[serviceType][categoryCode][fuelType][rateType].push(slab);
    });
    
    return organizedData;
  }

  // NEW: Get distinct service types
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

  // NEW: Get categories for a specific service type
  async getCategoriesByServiceType(calculatedCardId, yomCategory, serviceType) {
    const query = `
      SELECT DISTINCT category_code 
      FROM calculated_rate_slabs 
      WHERE calculated_card_id = ? AND yom_category = ? AND service_type = ?
      ORDER BY category_code
    `;
    
    const [rows] = await pool.query(query, [calculatedCardId, yomCategory, serviceType]);
    return rows.map(row => row.category_code);
  }
}

module.exports = new RateCardService();