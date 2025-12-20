
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/core/add_item_submit_model.dart';
import 'add_item_submit_event.dart';
import 'add_item_submit_state.dart';

class AddItemSubmitBloc extends Bloc<AddItemSubmitEvent, AddItemSubmitState> {
  final AddItemSubmitRepository repository;

  AddItemSubmitBloc(this.repository) : super(AddItemSubmitInitial()) {
    on<SubmitAddItem>(_onSubmitAddItem);
  }

  Future<void> _onSubmitAddItem(
    SubmitAddItem event,
    Emitter<AddItemSubmitState> emit,
  ) async {
    emit(AddItemSubmitLoading());
    try {
      late String message;
       if (event.formData['mode'] == 'update') {
      message = await repository.updateItem(event.formData);
    } else {
      message = await repository.submitAddItem(event.formData);
    }

      emit(AddItemSubmitSuccess(message));
    } catch (e) {
     String errorMessage = 'Something went wrong';

  if (e is DioException) {
    // If backend returns a structured JSON error (recommended)
    if (e.response?.data is Map && e.response?.data['message'] != null) {
      errorMessage = e.response?.data['message'];
    } else {
      // Fallback to Dio's own error string
      errorMessage = e.message ?? 'Unknown Dio error';
    }
  } else {
    errorMessage = e.toString().replaceFirst('Exception: ', '');
  }

  emit(AddItemSubmitFailure(errorMessage));
    }
  }
  
}
