import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:slt_hire_log/blocks/AdminCalcBloc/admin_calc_bloc_event.dart';
import 'package:slt_hire_log/blocks/AdminCalcBloc/admin_calc_bloc_state.dart';
import 'package:slt_hire_log/models/calculation_config_service.dart';

class AdminCalcBloc extends Bloc<AdminCalcEvent, AdminCalcState> {
  final Dio _dio;
  final CalculationConfigService _configService;

  AdminCalcBloc({
    Dio? dio,
    CalculationConfigService? configService,
  })  : _dio = dio ?? Dio(),
        _configService = configService ?? CalculationConfigService(),
        super(AdminCalcInitial()) {
    on<RunAdminCalculation>(_onRunCalculation);
  }

  Future<void> _onRunCalculation(
    RunAdminCalculation event,
    Emitter<AdminCalcState> emit,
  ) async {
    emit(AdminCalcRunning());

    try {
      // Load settings from local storage
      final config = await _configService.getConfig();

      // Build payload with config
      final payload = {
        'table': event.tableName,
        'calculatedCardId': event.calculatedCardId,
        'filter': event.filter,
        if (event.serNoList != null) 'serNoList': event.serNoList,
        // Senda all config parameters
        'billingDays': config['billingDays'],
        'absentDayRate': config['absentDayRate'],
        'absentCapPercent': config['absentCapPercent'],
        'absencePenaltyThreshold': config['absencePenaltyThreshold'],
        'absencePenaltyPercent': config['absencePenaltyPercent'],
        'includeVAT': config['includeVAT'],
        'vatPercent': config['vatPercent'],
      };

      final response = await _dio.post(
        '${dotenv.env['BASE_URL']}/api/calculate-rates/table',
        data: payload,
      );

      if (response.statusCode == 200) {
        emit(AdminCalcSuccess(
          updatedCount: response.data['updatedCount'] ?? 0,
          failed: List<Map<String, dynamic>>.from(response.data['failed'] ?? []),
          sample: List<Map<String, dynamic>>.from(response.data['sample'] ?? []),
        ));
      } else {
        emit(AdminCalcFailure('Server error: ${response.statusCode}'));
      }
    } catch (e) {
      emit(AdminCalcFailure(e.toString()));
    }
  }
}