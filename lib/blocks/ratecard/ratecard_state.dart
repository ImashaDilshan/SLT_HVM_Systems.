// bloc/ratecard_state.dart
part of 'ratecard_bloc.dart';

@immutable
abstract class RateCardState {}

class RateCardInitial extends RateCardState {}

class RateCardLoading extends RateCardState {}

class RateCardLoaded extends RateCardState {
  final List<MonthlyRate> monthlyRates;
  final List<DailyRate> dailyRates;
  final String selectedDate;

  RateCardLoaded(
    this.monthlyRates,
    this.dailyRates,
    this.selectedDate,
  );

  @override
  List<Object?> get props => [monthlyRates, dailyRates, selectedDate];
}

class RateCardError extends RateCardState {
  final String message;
  RateCardError(this.message);
  @override
  List<Object?> get props => [message];
}