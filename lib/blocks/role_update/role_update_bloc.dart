
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/role_update/role_update_event.dart';
import 'package:slt_hire_log/blocks/role_update/role_update_state.dart';

class RoleUpdateBloc extends Bloc<SubmitBulkRoleUpdate, RoleUpdateState> {
  final Dio _dio;

  RoleUpdateBloc(this._dio) : super(RoleUpdateInitial()) {
    on<SubmitBulkRoleUpdate>((event, emit) async {
      emit(RoleUpdateLoading());
      try {
        final res = await _dio.put('http://localhost:3000/api/update-bulk-role', data: {
          'tableName': event.tableName,
          'location': event.location,
          'mode': event.mode,
          'role': event.role,
          'newRole': event.newRole,
        });

        if (res.data['success']) {
          emit(RoleUpdateSuccess(res.data['message']));
        } else {
          emit(RoleUpdateFailure(res.data['message']));
        }
      } catch (e) {
        emit(RoleUpdateFailure('Update failed: ${e.toString()}'));
      }
    });
  }
}
