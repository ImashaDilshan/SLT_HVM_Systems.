// bloc/ratecard_bloc.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:slt_hire_log/core/api_service.dart';
import 'package:slt_hire_log/models/ratecard.dart';
part 'ratecard_event.dart';
part 'ratecard_state.dart';

class RateCardBloc extends Bloc<RateCardEvent, RateCardState> {
  final ApiService apiService;

  RateCardBloc({required this.apiService}) : super(RateCardInitial()) {
    on<LoadRateCardsByDate>((event, emit) async {
      emit(RateCardLoading());
      try {
        final response = await apiService.fetchRateCardsByDate(event.date);
        emit(RateCardLoaded(
          response.monthlyRates,
          response.dailyRates,
          event.date,
        ));
      } on Exception catch (e) {
        emit(RateCardError(e.toString()));
      }
    });
  }
}