// lib/blocs/dashboard/dashboard_state.dart
abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<dynamic> data;

  DashboardLoaded(this.data);
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);
}
