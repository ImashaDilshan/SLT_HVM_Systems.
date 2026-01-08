import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_cubit.dart';
import 'package:intl/intl.dart';

class SharedDataCubit extends Cubit<SharedDataState> {
  SharedDataCubit() : super(SharedDataState());

  void setLocation(String location) {
    emit(state.copyWith(location: location));
  }

  void setMode(String mode) {
    emit(state.copyWith(mode: mode));
  }

  void setDate(DateTime date) {
    emit(state.copyWith(date: date));
  }

  void setrole(String role) {
    emit(state.copyWith(role: role));
   
  }

  String get tableName {
    if (state.date == null) return '';
    final y = state.date!.year;
    final m = state.date!.month.toString().padLeft(2, '0');
    return "${y}_${DateFormat.MMMM().format(state.date!).toLowerCase()}"; // e.g., "2025_june"
  }
}
