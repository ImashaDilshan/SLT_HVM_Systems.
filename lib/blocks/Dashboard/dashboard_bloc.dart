import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';


class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<FetchDashboardData>((event, emit) async {
      emit(DashboardLoading());
      try {
        final response = await Dio().post(
          '${dotenv.env['BASE_URL']}/get-data',
          data: {
            'tableName': event.tableName,
            'location': event.location,
            'mode': event.mode,
            'role': event.role ,
          },
        );

        if (response.data['success']) {
          emit(DashboardLoaded(response.data['data']));
        } else {
          emit(DashboardError('Failed to load data'));
        }
      } catch (e) {
        emit(DashboardError(e.toString()));
      }
    });
    on<ResetDashboard>((event, emit) {
      emit(DashboardInitial());
    });
  }
}
