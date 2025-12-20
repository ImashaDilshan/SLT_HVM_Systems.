import 'package:equatable/equatable.dart';

abstract class AdminCalcState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AdminCalcInitial extends AdminCalcState {}

class AdminCalcRunning extends AdminCalcState {}

class AdminCalcSuccess extends AdminCalcState {
  final int updatedCount;
  final List<Map<String, dynamic>> failed;
  final List<Map<String, dynamic>> sample;

  AdminCalcSuccess({
    required this.updatedCount,
    required this.failed,
    required this.sample,
  });

  @override
  List<Object?> get props => [updatedCount, failed, sample];
}

class AdminCalcFailure extends AdminCalcState {
  final String error;

  AdminCalcFailure(this.error);

  @override
  List<Object?> get props => [error];
}