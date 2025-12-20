import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:slt_hire_log/blocks/submission_status/submission_status_bloc.dart';
import 'submission_status_event.dart';

class SubmissionStatusBloc extends Bloc<SubmissionStatusEvent, SubmissionStatusState> {
  final Dio dio;

  SubmissionStatusBloc(this.dio) : super(SubmissionStatusInitial()) {
    on<CheckSubmissionStatus>(_onCheckStatus);
  }

  Future<void> _onCheckStatus(
      CheckSubmissionStatus event, Emitter<SubmissionStatusState> emit) async {
    emit(SubmissionStatusLoading());

    try {
      print("🔍 Sending request: ${event.costCenterId}, ${event.month}, ${event.mode}");
      final response = await dio.get('/api/submission-status', queryParameters: {
        'costCenterId': event.costCenterId,
        'month': event.month,
        'mode': event.mode,
      });

      final role = response.data['role'] as String?;
      emit(SubmissionStatusLoaded(role));
    } catch (e) {
      emit(SubmissionStatusError('Failed to load status'));
    }
  }
}