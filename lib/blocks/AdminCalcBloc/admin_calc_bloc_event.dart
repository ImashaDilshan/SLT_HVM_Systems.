import 'package:equatable/equatable.dart';

class AdminCalcEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class RunAdminCalculation extends AdminCalcEvent {
  final String tableName;
  final int calculatedCardId;
  final Map<String, dynamic> filter;
  final List<int>? serNoList;

  RunAdminCalculation({
    required this.tableName,
    required this.calculatedCardId,
    required this.filter,
    this.serNoList,
  });

  @override
  List<Object?> get props => [tableName, calculatedCardId, filter, serNoList];
}