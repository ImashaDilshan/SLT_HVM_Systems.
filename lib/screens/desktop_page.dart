import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_event.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:slt_hire_log/blocks/overlay/overlay_cubit.dart';
import 'package:slt_hire_log/constants/app_colors.dart';
import 'package:slt_hire_log/extensions/role_extension.dart';
import 'package:slt_hire_log/models/user_model.dart';
import 'package:slt_hire_log/ui_compo/location_list.dart';
import 'package:slt_hire_log/ui_compo/logo.dart';
import 'package:slt_hire_log/ui_compo/mode_select.dart';
import 'package:slt_hire_log/ui_compo/name_bar.dart';
import 'package:slt_hire_log/widgets/add_item.dart';
import 'package:slt_hire_log/widgets/bottam_bar.dart';
import 'package:slt_hire_log/widgets/custom_widget/cost_center_search_field.dart';
import 'package:slt_hire_log/widgets/map_district_picker.dart';
import 'package:slt_hire_log/widgets/month_box.dart';
import 'package:slt_hire_log/widgets/naviation_bar.dart';
import 'package:slt_hire_log/widgets/table_box.dart';
import 'package:slt_hire_log/blocks/add_item_submit/add_item_submit_bloc.dart';
import 'package:slt_hire_log/blocks/add_item_submit/add_item_submit_state.dart';
import 'package:toastification/toastification.dart';

class DesktopPage extends StatefulWidget {
  final UserModel user;
  const DesktopPage({super.key, required this.user});

  @override
  State<DesktopPage> createState() => _DesktopPageState();
}

class _DesktopPageState extends State<DesktopPage> {
  FocusNode? searchFocus;
  VoidCallback? closeSearchOverlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double dialogWidth = screenWidth < 600 ? screenWidth * 0.9 : 500;

    return BlocListener<AddItemSubmitBloc, AddItemSubmitState>(
      listener: (context, state) {
       if (state is AddItemSubmitSuccess) {
          toastification.show(
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Item added successfully!'),
            autoCloseDuration: const Duration(seconds: 3),
            alignment: Alignment.topRight,
            showProgressBar: true,
          );

          final sharedData = context.read<SharedDataCubit>().state;
          final stepDown = sharedData.role!.stepDown;

          context.read<DashboardBloc>().add(ResetDashboard());
          context.read<DashboardBloc>().add(
            FetchDashboardData(
              tableName: context.read<SharedDataCubit>().tableName,
              location: sharedData.location!,
              mode: sharedData.mode!,
              role: stepDown,
            ),
          );
        } else if (state is AddItemSubmitFailure) {
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
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackgroundColor,
        body: GestureDetector(
          behavior:  HitTestBehavior.opaque,
          onTap: () {
            if (searchFocus != null && searchFocus!.hasFocus) {
              searchFocus!.unfocus();
            }
            closeSearchOverlay?.call();
          },
          child: Stack(
            children: [
              Positioned(
                right: 0,
                child: Opacity(
                            opacity: 0.2, // 👈 Adjust the opacity here (0.0 - 1.0)
                            child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/btn_Logo.png'), // 👈 Your image path
                    fit: BoxFit.cover,
                  ),
                ),
                            ),
                          ),
              ),
              
              SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: Row(
                      children: [
                        Logo(),
                        
                        NameBar(
                          name: widget.user.name,
                          position: widget.user.position,
                          role: widget.user.role,
                        ),
                        SizedBox(
                          height: 100,
                          child: VerticalDivider(
                            color: Colors.grey,
                            thickness: 0.5,
                            
                          ),
                        ),
                        LocationList(user: widget.user),
                        SizedBox(
                          height: 100,
                          child: VerticalDivider(
                            color: Colors.grey,
                            thickness: 0.5,
                            
                          ),),
                        SizedBox(width: 30,)
                      ],
                    ),

                  ),
                    Row(
                      children: [
                       Container(
                        constraints: const BoxConstraints(minHeight: 550),
                        height: MediaQuery.of(context).size.height - 200,
                        width: widget.user.role == "Moderetor" ? 300 : 425,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 30,
                              bottom: 20,
                            ),
                            child: Row(
                              children: [
                                widget.user.role == 'Moderetor'
                                    ? const SizedBox()
                                    : NaviationBar(),
                                SizedBox(
                                  width: 245,
                                  height: double.infinity,

                                  child: SizedBox(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          // MapDistrict for admin
                                          if (widget.user.role == 'admin')
                                            SizedBox(
                                              width: 200,
                                              height: 260,
                                              child: Material(
                                                color: Colors.transparent,
                                                elevation: 0,
                                                child: MapDistrictPicker(),
                                              ),
                                            ),
                                          // MonthPicker on top
                                          SizedBox(height: 20),
                                          SizedBox(
                                            width: 200,
                                            height: 200,
                                            child: MonthPickerContainer(),
                                          ),
                                          SizedBox(height: 20),
                                          // ModeSelect below month picker
                                          const ModeSelect(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                        Stack(
                          children: [
                            // 🟢 MAIN RIGHT PANEL
                            Container(
                              width: widget.user.role == "Moderetor"
                                  ? MediaQuery.of(context).size.width - 300
                                  : MediaQuery.of(context).size.width - 425,
                              constraints: const BoxConstraints(minHeight: 500),
                              height: MediaQuery.of(context).size.height - 200,
                              child: Column(
                                children: [
                                  widget.user.role == 'admin' || widget.user.role == 'level02'
                                      ? SizedBox(height: 100)
                                      : Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: DottedBorder(
                                            options:
                                                RoundedRectDottedBorderOptions(
                                              dashPattern: [6, 3],
                                              strokeWidth: 3,
                                              radius: const Radius.circular(15),
                                              color: const Color.fromARGB(
                                                  167, 85, 85, 85),
                                              padding: EdgeInsets.zero,
                                            ),
                                            child: Material(
                                              color: const Color.fromARGB(
                                                  76, 140, 189, 185),
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                splashColor: Colors.grey
                                                    .withOpacity(0.3),
                                                hoverColor: Colors.grey
                                                    .withOpacity(0.1),
                                                onTap: () {
                                                  context
                                                      .read<OverlayCubit>()
                                                      .show();
                                                },
                                                child: const SizedBox(
                                                  width: double.infinity,
                                                  height: 70,
                                                  child: Center(
                                                    child: Icon(
                                                      CupertinoIcons
                                                          .add_circled,
                                                      size: 30,
                                                      color: Color.fromARGB(
                                                          167, 85, 85, 85),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Container(
                                     
                                      width: widget.user.role == "Moderetor"
                                          ? MediaQuery.of(context).size.width -
                                              300
                                          : MediaQuery.of(context).size.width -
                                              425,
                                      height:
                                          MediaQuery.of(context).size.height -
                                              340,
                                      constraints:
                                          const BoxConstraints(minHeight: 360),
                                      child: Column(
                                        children: [
                                          Stack(
                                            children: [
                                              const TableBox(),
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  width: 15,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height -
                                                      390,
                                                  constraints:
                                                      const BoxConstraints(
                                                          minHeight: 310),
                                                  decoration:
                                                      const BoxDecoration(
                                                    
                                                    color: Color(0xFF0057A8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const BottamBar(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 🔵 REFRESH BUTTON
                            Positioned(
                              top: 95,
                              left: 10,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(100),
                                    topRight: Radius.circular(100),
                                    bottomLeft: Radius.circular(100),
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.refresh),
                                  tooltip: "Refresh",
                                  onPressed: () {
                                    final sharedData =
                                        context.read<SharedDataCubit>().state;
                                    final stepDown = sharedData.role.stepDown;
                                    context.read<DashboardBloc>().add(
                                      FetchDashboardData(
                                        tableName: context
                                            .read<SharedDataCubit>()
                                            .tableName,
                                        location:
                                            sharedData.location ?? '',
                                        mode: sharedData.mode ?? '',
                                        role: stepDown,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // 🔴 SEARCH FIELD
                            if (widget.user.role == 'admin')
                              Positioned(
                                top: 20,
                                left: 20,
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width -
                                      470,
                                  height: 70,
                                  child: CostCenterSearchField(
                                    
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ⚫️ OVERLAY
              BlocBuilder<OverlayCubit, Map<String, dynamic>?>(
                builder: (context, overlayState) {
                  if (overlayState == null) return const SizedBox.shrink();
                  return Positioned.fill(
                    child:
                        BlocBuilder<AddItemSubmitBloc, AddItemSubmitState>(
                      builder: (context, submitState) {
                        return Stack(
                          children: [
                            BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ),
                            Center(
                              child: Container(
                                alignment: Alignment.center,
                                width: dialogWidth + 50,
                                height: 600,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: const [],
                                ),
                              ),
                            ),
                            const AddItem(),
                            if (submitState is AddItemSubmitLoading)
                              Container(
                                color: Colors.black.withOpacity(0.4),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
