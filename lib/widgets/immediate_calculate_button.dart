import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/AdminCalcBloc/admin_calc_bloc_bloc.dart';
import 'package:slt_hire_log/blocks/AdminCalcBloc/admin_calc_bloc_event.dart';
import 'package:slt_hire_log/blocks/AdminCalcBloc/admin_calc_bloc_state.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:toastification/toastification.dart';

class ImmediateCalculateButton extends StatelessWidget {
  final String tableName;
  final int calculatedCardId;
  final List<int>? serNoList;

  const ImmediateCalculateButton({
    super.key,
    required this.tableName,
    required this.calculatedCardId,
    this.serNoList,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminCalcBloc, AdminCalcState>(
      listener: (context, state) {
        if (state is AdminCalcRunning) {
          toastification.show(
            context: context,
            type: ToastificationType.info,
            style: ToastificationStyle.fillColored,
            title: const Text('Calculating…'),
            autoCloseDuration: const Duration(seconds: 2),
            alignment: Alignment.topRight,
            showProgressBar: true,
          );
        } else if (state is AdminCalcSuccess) {
          if (state.updatedCount == 0) {
            toastification.show(
              context: context,
              type: ToastificationType.warning,
              style: ToastificationStyle.fillColored,
              title: const Text('No rows updated'),
              description: Text('${state.failed.length} mapping failures'),
              autoCloseDuration: const Duration(seconds: 4),
              alignment: Alignment.topRight,
              showProgressBar: true,
            );
          } else {
            toastification.show(
              context: context,
              type: ToastificationType.success,
              style: ToastificationStyle.fillColored,
              title: Text('Updated ${state.updatedCount} rows'),
              description: state.failed.isNotEmpty 
                ? Text('${state.failed.length} failed') 
                : null,
              autoCloseDuration: const Duration(seconds: 4),
              alignment: Alignment.topRight,
              showProgressBar: true,
            );
          }
        } else if (state is AdminCalcFailure) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            title: const Text('Calculation failed'),
            description: Text(state.error),
            autoCloseDuration: const Duration(seconds: 8),
            alignment: Alignment.topRight,
            showProgressBar: true,
          );
        }
      },
      child: BlocBuilder<AdminCalcBloc, AdminCalcState>(
        builder: (context, state) {
          final isRunning = state is AdminCalcRunning;

          return FloatingActionButton.extended(
            onPressed: isRunning ? null : () => _triggerCalculation(context),
            icon: isRunning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.calculate, color: Colors.white),
            label: Text(
              isRunning ? 'Calculating...' : 'Calculate',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: isRunning ? Colors.grey : Colors.blue,
          );
        },
      ),
    );
  }

  void _triggerCalculation(BuildContext context) {
    final sharedData = context.read<SharedDataCubit>().state;
     final sharedData2 = context.read<SharedDataCubit>();


    context.read<AdminCalcBloc>().add(
      RunAdminCalculation(
        tableName: sharedData2.tableName,
        calculatedCardId: 23,
        filter: {
          "accept_role": 'level02',
          "cost_center": sharedData.location ?? "",
        },
        serNoList: serNoList,
      ),
    );
  }
}