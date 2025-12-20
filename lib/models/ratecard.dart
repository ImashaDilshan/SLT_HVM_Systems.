// models/ratecard.dart
class RateCardResponse {
  final bool success;
  final String effectiveDate;
  final String yomCondition;
  final List<MonthlyRate> monthlyRates;
  final List<DailyRate> dailyRates;

  RateCardResponse({
    required this.success,
    required this.effectiveDate,
    required this.yomCondition,
    required this.monthlyRates,
    required this.dailyRates,
  });

  factory RateCardResponse.fromJson(Map<String, dynamic> json) {
    return RateCardResponse(
      success: json['success'] ?? false,
      effectiveDate: json['effectiveDate'] ?? 'Unknown',
      yomCondition: json['yomCondition'] ?? 'Before 2000',
      monthlyRates: (json['monthlyRates'] as List)
          .map((e) => MonthlyRate.fromJson(e))
          .toList(),
      dailyRates: (json['dailyRates'] as List)
          .map((e) => DailyRate.fromJson(e))
          .toList(),
    );
  }
}

class MonthlyRate {
  final String vehicle;
  final String fuelType;
  final String? subCategory;
  final String kmSlab;
  final double monthlyRentalLKR;
  final double? additionalKmRateLKR;
  final double overTimeRateLKR;
  final double nightAllowanceLKR;

  MonthlyRate({
    required this.vehicle,
    required this.fuelType,
    this.subCategory,
    required this.kmSlab,
    required this.monthlyRentalLKR,
    this.additionalKmRateLKR,
    this.overTimeRateLKR = 78.75,
    this.nightAllowanceLKR = 525.00,
  });

  factory MonthlyRate.fromJson(Map<String, dynamic> json) {
    return MonthlyRate(
      vehicle: json['vehicle'] ?? 'Unknown',
      fuelType: json['fuelType'] ?? 'Unknown',
      subCategory: json['subCategory']?.toString(),
      kmSlab: json['kmSlab'] ?? 'Unknown',
      monthlyRentalLKR: (json['monthlyRentalLKR'] ?? 0.0).toDouble(),
      additionalKmRateLKR: json['additionalKmRateLKR']?.toDouble(),
      overTimeRateLKR: (json['overTimeRateLKR'] ?? 78.75).toDouble(),
      nightAllowanceLKR: (json['nightAllowanceLKR'] ?? 525.00).toDouble(),
    );
  }
}

class DailyRate {
  final String vehicle;
  final String fuelType;
  final double dailyRateLKR;
  final double additionalKmRateLKR;

  DailyRate({
    required this.vehicle,
    required this.fuelType,
    required this.dailyRateLKR,
    required this.additionalKmRateLKR,
  });

  factory DailyRate.fromJson(Map<String, dynamic> json) {
    return DailyRate(
      vehicle: json['vehicle'] ?? 'Field Van',
      fuelType: json['fuelType'] ?? 'Unknown',
      dailyRateLKR: (json['dailyRateLKR'] ?? 0.0).toDouble(),
      additionalKmRateLKR: (json['additionalKmRateLKR'] ?? 0.0).toDouble(),
    );
  }
}