class FuelCalculator {
  static calculateAdjustment(newPrice, basePrice, distance, fuelConsumption) {
    return (newPrice - basePrice) * (distance / fuelConsumption);
  }

  static getFuelConsumption(categoryCode) {
    // USE STANDARDIZED VALUES FROM THE FORMULA DOCUMENT
    const consumptionRates = {
      'CAR01': 10,    // Cars: 10 km/L
      'CAR02': 10,    // Cars: 10 km/L
      'CAR03': 10,    // Cars: 10 km/L
      'VAN01': 9,     // Vans: 9 km/L
      'VAN02': 9,     // Passenger Vans: 9 km/L
      'DCAB01': 9,    // Double Cabs 2WD: 9 km/L
      'DCAB02': 9,    // Double Cabs 4WD: 9 km/L
      'DCAB03': 9     // Double Cabs 4WD: 9 km/L
    };
    
    return consumptionRates[categoryCode] || 10;
  }

static calculateNewRates(baseSlabs, baseDieselPrice, basePetrolPrice, newDieselPrice, newPetrolPrice) {
  return baseSlabs.map(slab => {
    const fuelType = slab.fuel_type;

    if(fuelType === 'NULL' || !fuelType) {
      return slab;
    }
    
    // Skip adjustment for diesel if prices are the same
    if (fuelType === 'DIESEL' && newDieselPrice === baseDieselPrice) {
      return slab;
    }
    
    // Skip adjustment for petrol if prices are the same  
    if (fuelType === 'PETROL' && newPetrolPrice === basePetrolPrice) {
      return slab;
    }

    const basePrice = fuelType === 'DIESEL' ? baseDieselPrice : basePetrolPrice;
    const newPrice = fuelType === 'DIESEL' ? newDieselPrice : newPetrolPrice;
    
    const fuelConsumption = FuelCalculator.getFuelConsumption(slab.category_code);
    
    let monthlyAdjustment = 0;
    let kmAdjustment = 0;
    
    // ✅ FIXED: CORRECT DISTANCE CALCULATION FOR ALL KM_SLAB TYPES
    let distance = 0;
    if (slab.rate_type === 'Daily') {
      distance = 100; // Daily rates are for 100 km
    } else {
      // Handle all possible km_slab patterns
      if (slab.km_slab.includes('1000') || slab.km_slab.includes('Upto')) {
        distance = 1000;
      } else if (slab.km_slab.includes('1500')) {
        distance = 1500;
      } else if (slab.km_slab.includes('2000') && !slab.km_slab.includes('2001')) {
        distance = 2000; // For "1501-2000 km" slab
      } else if (slab.km_slab.includes('2500') && !slab.km_slab.includes('Above')) {
        distance = 2500; // For "2001-2500 km" slab
      } else if (slab.km_slab.includes('Above')) {
        // For "Above" slabs, use the max distance of the previous slab
        if (slab.km_slab.includes('2500')) {
          distance = 2500;
        } else if (slab.km_slab.includes('2000')) {
          distance = 2000;
        }
      } else {
        distance = slab.max_distance || 0;
      }
    }
    
    // Calculate adjustment for monthly rental
    if (distance > 0 && slab.monthly_rental) {
      monthlyAdjustment = FuelCalculator.calculateAdjustment(newPrice, basePrice, distance, fuelConsumption);
    }
    
    // Calculate adjustment for additional km rate (always use 1 km distance)
    if (slab.additional_km_rate) {
      kmAdjustment = FuelCalculator.calculateAdjustment(newPrice, basePrice, 1, fuelConsumption);
    }

    return {
      ...slab,
      monthly_rental: slab.monthly_rental ? (Number(slab.monthly_rental) + monthlyAdjustment).toFixed(2) : null,
      additional_km_rate: slab.additional_km_rate ? (Number(slab.additional_km_rate) + kmAdjustment).toFixed(2) : null
    };
  });
}
}

module.exports = FuelCalculator;