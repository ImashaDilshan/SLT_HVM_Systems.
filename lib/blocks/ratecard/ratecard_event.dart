// bloc/ratecard_event.dart
part of 'ratecard_bloc.dart';

@immutable
abstract class RateCardEvent {}

class LoadRateCardsByDate extends RateCardEvent {
  final String date;
  LoadRateCardsByDate(this.date);
  @override
  List<Object?> get props => [date];
}