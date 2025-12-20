import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:slt_hire_log/blocks/AdminCalcBloc/admin_calc_bloc_bloc.dart';
import 'package:slt_hire_log/blocks/AdminCalcBloc/admin_calc_bloc_state.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:slt_hire_log/blocks/role/user_role_cubit.dart';
import 'package:slt_hire_log/blocks/role_update/role_update_bloc.dart';
import 'package:slt_hire_log/blocks/role_update/role_update_state.dart';
import 'package:slt_hire_log/blocks/remove/remove_bloc.dart';
import 'package:slt_hire_log/blocks/remove/remove_state.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_event.dart';
import 'package:slt_hire_log/extensions/role_extension.dart';
import 'package:slt_hire_log/widgets/dashboard_table_page.dart';

class TableBox extends StatefulWidget {
  const TableBox({super.key});

  @override
  State<TableBox> createState() => _TableBoxState();
}

class _TableBoxState extends State<TableBox> {
  String? overriddenRole;

 Future<void> _refreshDashboard(BuildContext context) async {
    final sharedData = context.read<SharedDataCubit>().state;
    final stepDown = sharedData.role.stepDown;

    setState(() {
      overriddenRole = stepDown;
    });

    _showLoadingDialog("Refreshing...");

    await Future.delayed(const Duration(seconds: 1)); // ⏱ Add delay

    context.read<DashboardBloc>().add(ResetDashboard());
    context.read<DashboardBloc>().add(
      FetchDashboardData(
        tableName: context.read<SharedDataCubit>().tableName,
        location: sharedData.location ?? '',
        mode: sharedData.mode ?? '',
        role: stepDown,
      ),
    );

    _maybeCloseDialog();
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>   Center(
              child: Shimmer.fromColors(
                baseColor: const Color.fromARGB(255, 0, 106, 255),
                highlightColor: const Color.fromARGB(255, 4, 190, 128),
                child: Image.asset(
                  'assets/SLTMobitel_Logo.png',
                  width: 300,
                  height: 200,
                ),
              ),
            ),
          

    );
  }

  void _maybeCloseDialog() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sharedData = context.watch<SharedDataCubit>().state;
    final displayRole = overriddenRole ?? sharedData.role;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: context.read<UserInfoCubit>().state?.role == "Moderetor"
            ? MediaQuery.of(context).size.width - 300
            : MediaQuery.of(context).size.width - 425,
        height: MediaQuery.of(context).size.height - 390,
        constraints: const BoxConstraints(minHeight: 310),
        decoration: BoxDecoration(
         
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(55, 0, 0, 0),
              spreadRadius: 6,
              blurRadius: 6,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Stack(
            children: [
              
              MultiBlocListener(
                listeners: [
                  BlocListener<RoleUpdateBloc, RoleUpdateState>(
                    listener: (context, state) {
                      if (state is RoleUpdateLoading) {
                        _showLoadingDialog("Updating...");
                      } else {
                        _maybeCloseDialog();
                        if (state is RoleUpdateSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message)),
                          );
                          _refreshDashboard(context);
                        }
                        else if (state is RoleUpdateFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.error)),
                          );
                        }
                        
                        }
                    },
                  ),
                  BlocListener<RemoveBloc, RemoveState>(
                    listener: (context, state) {
                      if (state is RemoveLoading) {
                        _showLoadingDialog("Removing...");
                      } else {
                        _maybeCloseDialog();
                        if (state is RemoveSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message)),
                          );
                          _refreshDashboard(context);
                        } else if (state is RemoveFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.error)),
                          );
                        }
                      }
                    },
                  ),
                   BlocListener<AdminCalcBloc, AdminCalcState>(
                    listener: (context, state) {
                      if (state is AdminCalcRunning) {
                        _showLoadingDialog("Calculating...");
                      } else {
                        _maybeCloseDialog();
                        if (state is AdminCalcSuccess) {
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.failed.isEmpty
                                ? "Calculation completed successfully!"
                                : "Calculation completed with some failures.")),
                          );
                          _refreshDashboard(context);
                        } else if (state is AdminCalcFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.error)),
                          );
                        }
                      }
                    },
                  ),
                ],
                child: DashboardTablePage(
                  tableName: context.read<SharedDataCubit>().tableName,
                  location: context.read<SharedDataCubit>().state.location ?? '',
                  mode: context.read<SharedDataCubit>().state.mode ?? '',
                  role: context.read<SharedDataCubit>().state.role ?? '',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
