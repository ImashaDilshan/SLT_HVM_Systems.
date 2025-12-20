class DashboardData {
  final int serNo;
  final String user;
  final String costCenter;
  final String refNo;
  final String vehicleNo;
  final String vehicleType;
  final String category;
  final String manufactureYear;
  final DateTime fromDate;
  final DateTime toDate;
  final int workingDays;
  final double kmRun;
  final double otHrs;
  final int overnight;
  final String acceptRole;

  DashboardData({
    required this.serNo,
    required this.user,
    required this.costCenter,
    required this.refNo,
    required this.vehicleNo,
    required this.vehicleType,
    required this.category,
    required this.manufactureYear,
    required this.fromDate,
    required this.toDate,
    required this.workingDays,
    required this.kmRun,
    required this.otHrs,
    required this.overnight,
    required this.acceptRole,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
    serNo: json['ser_no'] ?? 0,
    user: json['user'] ?? '',
    costCenter: json['cost_center'] ?? '',
    refNo: json['ref_no'] ?? '',
    vehicleNo: json['vehicle_no'] ?? '',
    vehicleType: json['vehicle_type'] ?? '',
    category: json['category'] ?? '',
    manufactureYear: json['manufacture_year'] ?? '',
    fromDate: json['from_date'] != null ? DateTime.parse(json['from_date']) : DateTime(1970),
    toDate: json['to_date'] != null ? DateTime.parse(json['to_date']) : DateTime(1970),
    workingDays: json['working_days'] ?? 0,
    kmRun: (json['km_run'] as num?)?.toDouble() ?? 0.0,
    otHrs: (json['ot_hrs'] as num?)?.toDouble() ?? 0.0,
    overnight: json['overnight'] ?? 0,
    acceptRole: json['accept_role'] ?? '',
    );
  }
}
