import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_event.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:slt_hire_log/blocks/remove/remove_bloc.dart';
import 'package:slt_hire_log/blocks/remove/remove_event.dart';
import 'package:slt_hire_log/blocks/role/user_role_cubit.dart';
import 'package:slt_hire_log/blocks/role_update/role_update_bloc.dart';
import 'package:slt_hire_log/blocks/role_update/role_update_event.dart';
import 'package:slt_hire_log/blocks/role_update/role_update_state.dart';
import 'package:slt_hire_log/constants/app_colors.dart';
import 'package:slt_hire_log/constants/app_styles.dart';
import 'package:slt_hire_log/extensions/role_extension.dart';
import 'package:slt_hire_log/widgets/immediate_calculate_button.dart';
import 'package:slt_hire_log/widgets/settings_dialog.dart';
import 'package:toastification/toastification.dart';

class BottamBar extends StatefulWidget {
  const BottamBar({super.key});

  @override
  State<BottamBar> createState() => _BottamBarState();
}

class _BottamBarState extends State<BottamBar> {
  static const _darkBar = Color(0xFF0A2540);
  static const _btnBlue = Color(0xFF0E4C92);
  static const _btnBlueHover = Color(0xFF2E6CCB);

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RoleUpdateBloc, RoleUpdateState>(
          listener: (context, state) {
            if (state is RoleUpdateSuccess) {
              toastification.show(
                type: ToastificationType.success,
                style: ToastificationStyle.fillColored,
                title: const Text('Item added successfully!'),
                autoCloseDuration: const Duration(seconds: 3),
                alignment: Alignment.topRight,
                showProgressBar: true,
              );
              final sharedDataCubit = context.read<SharedDataCubit>();
              final sharedData = context.read<SharedDataCubit>().state;

              context.read<DashboardBloc>().add(ResetDashboard());
              context.read<DashboardBloc>().add(
                FetchDashboardData(
                  tableName: sharedDataCubit.tableName,
                  location: sharedData.location!,
                  mode: sharedData.mode!,
                  role: sharedData.role!,
                ),
              );
            } else if (state is RoleUpdateFailure) {
              toastification.show(
                type: ToastificationType.error,
                style: ToastificationStyle.fillColored,
                title: const Text('Failed to add item'),
                description: Text(state.error),
                autoCloseDuration: const Duration(seconds: 8),
                alignment: Alignment.topRight,
                showProgressBar: true,
              );
            }
          },
        ),

        // NEW: AdminCalcBloc toasts
      
      ],
      child: Container(
        width: MediaQuery.of(context).size.width - 425,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              context.read<UserInfoCubit>().state?.role == "Moderetor"
                  ? Colors.transparent
                  : _darkBar,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.download,
                    size: 28,
                    color: Colors.white70,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 10),
                width: MediaQuery.of(context).size.width - 1035,
                height: 50,
                alignment: Alignment.center,

              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SizedBox(
                  width: 460,
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 360,
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ADMIN: ONLY a Calculate button (uses AdminCalcBloc)
                            if (context.read<UserInfoCubit>().state?.role ==
                                'admin')
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => const SettingsPage(),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.settings,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 40,
                                    child: ImmediateCalculateButton(
                                      tableName:
                                          context
                                              .read<SharedDataCubit>()
                                              .tableName,
                                      calculatedCardId: 23,

                                      // Optional: specific rows
                                      // serNoList: [1, 6, 20],
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  ElevatedButton(
                                    onPressed: () {
                                      final sharedData =
                                          context.read<SharedDataCubit>().state;
                                      final role = sharedData.role!;
                                      final downrole = role.stepDown;

                                      context.read<RemoveBloc>().add(
                                        RemoveRoleRequested(
                                          tableName:
                                              context
                                                  .read<SharedDataCubit>()
                                                  .tableName,
                                          location: sharedData.location!,
                                          mode: sharedData.mode!,
                                          role: downrole,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      minimumSize: const Size(100, 50),
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        168,
                                        0,
                                        0,
                                      ),
                                      elevation: 4,
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      width: 100,
                                      height: 40,
                                      child: Text(
                                        "X",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppStyles.heading.copyWith(
                                          fontSize: 20,
                                          color: const Color.fromARGB(
                                            255,
                                            255,
                                            255,
                                            255,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            // NON-ADMIN: keep EXACT UI/logic (X + Send) from your original code
                            if (context.read<UserInfoCubit>().state?.role !=
                                'admin') ...[
                              context.read<UserInfoCubit>().state?.role ==
                                      "Moderetor"
                                  ? const SizedBox()
                                  : context.read<UserInfoCubit>().state?.role ==
                                      "level01"
                                  ? const SizedBox()
                                  : ElevatedButton(
                                    onPressed: () {
                                      final sharedData =
                                          context.read<SharedDataCubit>().state;
                                      final role = sharedData.role!;
                                      final downrole = role.stepDown;

                                      context.read<RemoveBloc>().add(
                                        RemoveRoleRequested(
                                          tableName:
                                              context
                                                  .read<SharedDataCubit>()
                                                  .tableName,
                                          location: sharedData.location!,
                                          mode: sharedData.mode!,
                                          role: downrole,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      minimumSize: const Size(100, 50),
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        168,
                                        0,
                                        0,
                                      ),
                                      elevation: 4,
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      width: 100,
                                      height: 40,
                                      child: Text(
                                        "X",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppStyles.heading.copyWith(
                                          fontSize: 20,
                                          color: const Color.fromARGB(
                                            255,
                                            255,
                                            255,
                                            255,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              context.read<UserInfoCubit>().state?.role ==
                                      "Moderetor"
                                  ? const SizedBox()
                                  : ElevatedButton(
                                    onPressed: () {
                                      final sharedData =
                                          context.read<SharedDataCubit>().state;
                                      final role = sharedData.role!;
                                      final downrole = role.stepDown;
                                      final newRole = role;

                                      context.read<RoleUpdateBloc>().add(
                                        SubmitBulkRoleUpdate(
                                          tableName:
                                              context
                                                  .read<SharedDataCubit>()
                                                  .tableName,
                                          location: sharedData.location!,
                                          mode: sharedData.mode!,
                                          role: downrole,
                                          newRole: newRole,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      minimumSize: const Size(100, 50),
                                      backgroundColor: const Color(0xFF0057A8),
                                      elevation: 4,
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      width: 100,
                                      height: 40,
                                      child: Text(
                                        "Send",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppStyles.heading.copyWith(
                                          fontSize: 20,
                                          color: const Color.fromARGB(
                                            255,
                                            255,
                                            255,
                                            255,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(
                        width: 100,
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FloatingActionButton(
                              heroTag: 'locationListLeftBtns',
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              backgroundColor: AppColors.secondary,
                              mini: true,
                              onPressed: () {},
                              child: const Icon(CupertinoIcons.left_chevron),
                            ),
                            FloatingActionButton(
                              heroTag: 'locationListRightBtns',
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              backgroundColor: AppColors.secondary,
                              mini: true,
                              onPressed: () {},
                              child: const Icon(CupertinoIcons.right_chevron),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


