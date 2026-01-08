import 'package:equatable/equatable.dart';

abstract class RemoveEvent extends Equatable {
  const RemoveEvent();

  @override
  List<Object> get props => [];
}

class RemoveRoleRequested extends RemoveEvent {
  final String tableName;
  final String location;
  final String mode;
  final String role;

  const RemoveRoleRequested({
    required this.tableName,
    required this.location,
    required this.mode,
    required this.role,
  });

  @override
  List<Object> get props => [tableName, location, mode, role];
}
