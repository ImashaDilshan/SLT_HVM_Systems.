import 'package:equatable/equatable.dart';

abstract class RemoveState extends Equatable {
  const RemoveState();

  @override
  List<Object> get props => [];
}

class RemoveInitial extends RemoveState {}

class RemoveLoading extends RemoveState {}

class RemoveSuccess extends RemoveState {
  final String message;

  const RemoveSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class RemoveFailure extends RemoveState {
  final String error;

  const RemoveFailure({required this.error});

  @override
  List<Object> get props => [error];
}
