class CalculatedRateCard {
  final int id;
  final int baseId;
  final String baseName;
  final DateTime calculationDate;
  final double newDieselPrice;
  final double newPetrolPrice;
  final String status;

  CalculatedRateCard({
    required this.id,
    required this.baseId,
    required this.baseName,
    required this.calculationDate,
    required this.newDieselPrice,
    required this.newPetrolPrice,
    required this.status,
  });

  factory CalculatedRateCard.fromJson(Map<String, dynamic> json) {
    return CalculatedRateCard(
      id: json['id'] ?? 0,
      baseId: json['base_id'] ?? 0,
      baseName: json['base_name'] ?? '',
      calculationDate: DateTime.parse(json['calculation_date'] ?? DateTime.now().toString()),
      newDieselPrice: _parseDouble(json['new_diesel_price']),
      newPetrolPrice: _parseDouble(json['new_petrol_price']),
      status: json['status'] ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

// In your rate_card_models.dart file
class RateCardSlab {
  final int id;
  final int calculatedCardId;
  final String yomCategory;
  final String serviceType;
  final String categoryCode;
  final String? fuelType;
  final String rateType;
  final String kmSlab;
  final int maxDistance; // ADD THIS FIELD
  final double? monthlyRental;
  final double? additionalKmRate;
  final double? overtimeRate;
  final double? nightAllowance;

  RateCardSlab({
    required this.id,
    required this.calculatedCardId,
    required this.yomCategory,
    required this.serviceType,
    required this.categoryCode,
    this.fuelType,
    required this.rateType,
    required this.kmSlab,
    required this.maxDistance, // ADD THIS
    this.monthlyRental,
    this.additionalKmRate,
    this.overtimeRate,
    this.nightAllowance,
  });

  bool get hasValidData => monthlyRental != null || additionalKmRate != null;

  factory RateCardSlab.fromJson(Map<String, dynamic> json) {
    return RateCardSlab(
      id: json['id'] ?? 0,
      calculatedCardId: json['calculated_card_id'] ?? 0,
      yomCategory: json['yom_category'] ?? '',
      serviceType: json['service_type'] ?? '',
      categoryCode: json['category_code'] ?? '',
      fuelType: json['fuel_type'],
      rateType: json['rate_type'] ?? '',
      kmSlab: json['km_slab'] ?? '',
      maxDistance: _parseInt(json['max_distance']), // ADD THIS
      monthlyRental: _parseDouble(json['monthly_rental']),
      additionalKmRate: _parseDouble(json['additional_km_rate']),
      overtimeRate: _parseDouble(json['overtime_rate']),
      nightAllowance: _parseDouble(json['night_allowance']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  // ADD THIS HELPER METHOD
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
// Add this to your rate_card_models.dart file
// In your rate_card_models.dart file
class RentalCalculationResult {
  final double baseRental;
  final double overtimeAmount;
  final double overnightAmount;
  final double excessKmAmount;
  final double absentDeduction;
  final double subtotal;
  final double taxAmount;
  final double grandTotal;
  final RateCardSlab? applicableSlab;
  final bool fifteenPercentRuleApplied;
  final int allowedExcess;
  final int actualExcess;
  final int referenceDistance;

  RentalCalculationResult({
    required this.baseRental,
    required this.overtimeAmount,
    required this.overnightAmount,
    required this.excessKmAmount,
    required this.absentDeduction,
    required this.subtotal,
    required this.taxAmount,
    required this.grandTotal,
    this.applicableSlab,
    required this.fifteenPercentRuleApplied,
    required this.allowedExcess,
    required this.actualExcess,
    required this.referenceDistance,
  });

  // ADD THIS FACTORY CONSTRUCTOR
  factory RentalCalculationResult.fromCalculation({
    required num baseRental,
    required num overtimeAmount,
    required num overnightAmount,
    required num excessKmAmount,
    required num absentDeduction,
    required num subtotal,
    required num taxAmount,
    required num grandTotal,
    RateCardSlab? applicableSlab,
    required bool fifteenPercentRuleApplied,
    required int allowedExcess,
    required int actualExcess,
    required int referenceDistance,
  }) {
    return RentalCalculationResult(
      baseRental: baseRental.toDouble(),
      overtimeAmount: overtimeAmount.toDouble(),
      overnightAmount: overnightAmount.toDouble(),
      excessKmAmount: excessKmAmount.toDouble(),
      absentDeduction: absentDeduction.toDouble(),
      subtotal: subtotal.toDouble(),
      taxAmount: taxAmount.toDouble(),
      grandTotal: grandTotal.toDouble(),
      applicableSlab: applicableSlab,
      fifteenPercentRuleApplied: fifteenPercentRuleApplied,
      allowedExcess: allowedExcess,
      actualExcess: actualExcess,
      referenceDistance: referenceDistance,
    );
  }
}
class RentalCalculationInput {
  final int calculatedCardId;
  final String categoryCode;
  final String yomCategory;
  final String serviceType;
  final String fuelType;
  final int workingDays;
  final int kmRun;
  final int overtimeHours;
  final int overnightStays;
  final int absentDays;

  RentalCalculationInput({
    required this.calculatedCardId,
    required this.categoryCode,
    required this.yomCategory,
    required this.serviceType,
    required this.fuelType,
    required this.workingDays,
    required this.kmRun,
    required this.overtimeHours,
    required this.overnightStays,
    required this.absentDays,
  });

  // Add toJson method if needed for API calls
  Map<String, dynamic> toJson() {
    return {
      'calculatedCardId': calculatedCardId,
      'categoryCode': categoryCode,
      'yomCategory': yomCategory,
      'serviceType': serviceType,
      'fuelType': fuelType,
      'workingDays': workingDays,
      'kmRun': kmRun,
      'overtimeHours': overtimeHours,
      'overnightStays': overnightStays,
      'absentDays': absentDays,
    };
  }
}