import 'package:flutter_bloc/flutter_bloc.dart';
import 'remove_event.dart';
import 'remove_state.dart';
import 'package:dio/dio.dart';

class RemoveBloc extends Bloc<RemoveEvent, RemoveState> {
  final Dio dio;

  RemoveBloc({required this.dio}) : super(RemoveInitial()) {
    on<RemoveRoleRequested>(_onRemoveRoleRequested);
  }

  Future<void> _onRemoveRoleRequested(
    RemoveRoleRequested event,
    Emitter<RemoveState> emit,
  ) async {
    emit(RemoveLoading());

    try {
      print('Removing role: ${event.role} from ${event.tableName} at ${event.location} in ${event.mode} mode');
       final res = await dio.put(
        'http://localhost:3000/api/remove-role', // 🔁 your backend endpoint
        data: {
          'tableName': event.tableName,
          'location': event.location,
          'mode': event.mode,
          'role': event.role,
          'newRole': 'Remove',
        },
      );

      if (res.data['success']) {
        emit(RemoveSuccess(message: res.data['message']));
        print( 'Role removed successfully: ${res.data['message']}');
      } else {
        emit(RemoveFailure(error: res.data['message']));
        print('Failed to remove role: ${res.data['message']}');

      }
    } catch (e) {
      emit(RemoveFailure(error: 'Server error occurred while removing role.'));
      print('Error removing role: ${e.toString()}');
    }
  }
}
