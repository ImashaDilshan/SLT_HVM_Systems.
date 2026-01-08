// lib/blocs/dashboard/dashboard_event.dart
abstract class DashboardEvent {}

class FetchDashboardData extends DashboardEvent {
  final String tableName;
  final String location;
  final String mode;
  final String role;

  FetchDashboardData({
    required this.tableName,
    required this.location,
    required this.mode,
    required this.role
  });
}
class ResetDashboard extends DashboardEvent {}