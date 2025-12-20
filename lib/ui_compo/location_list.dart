import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_event.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_cubit.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:slt_hire_log/blocks/add_item_load/add_item_load_bloc.dart';
import 'package:slt_hire_log/blocks/add_item_load/add_item_load_event.dart';
import 'package:slt_hire_log/constants/app_colors.dart';
import 'package:slt_hire_log/constants/app_styles.dart';
import 'package:slt_hire_log/extensions/role_extension.dart';
import 'package:slt_hire_log/models/user_model.dart';
import 'package:slt_hire_log/blocks/map_district_cubit.dart';

class LocationList extends StatefulWidget {
  final UserModel user;
  const LocationList({super.key, required this.user});

  @override
  State<LocationList> createState() => _LocationListState();
}

class _LocationListState extends State<LocationList> {
  final ScrollController _scrollController = ScrollController();

  void scrollToSelected(String? selectedId) {
    if (selectedId == null || !_scrollController.hasClients) return; // FIXED: Check hasClients

    final index = widget.user.costCenters.indexWhere(
      (e) => e.id.toString() == selectedId,
    );
    if (index != -1) {
      // FIXED: Use jumpTo instead of animateTo for initial scroll
      // Also check hasClients again before animating
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(index * 320.0);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final shared = context.read<SharedDataCubit>();

    shared.setDate(DateTime.now());
    shared.setLocation(shared.state.location ?? '');
    shared.setrole(widget.user.role);

    // FIXED: Use post-frame callback to ensure widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToSelected(shared.state.location);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // FIXED: Dispose controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sharedLocation = context.watch<SharedDataCubit>().state.location;

    return BlocListener<SharedDataCubit, SharedDataState>(
      listenWhen: (previous, current) => previous.location != current.location,
      listener: (context, state) {
        scrollToSelected(state.location);
      },
      child: BlocBuilder<MapDistrictCubit, String?>(
        builder: (context, selectedDistrict) {
          final filteredCenters =
              selectedDistrict == null
                  ? widget.user.costCenters
                  : widget.user.costCenters.where((e) {
                    return e.name.toLowerCase().contains(
                      selectedDistrict.toLowerCase(),
                    );
                  }).toList();

          return Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...filteredCenters.map((e) {
                            final isSelected =
                                sharedLocation == e.id.toString();

                            return Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: GestureDetector(
                                onTap: () {
                                  context.read<AddItemLoadBloc>().add(
                                    FetchAddItemData(e.id),
                                  );

                                  context.read<SharedDataCubit>().setLocation(
                                    e.id.toString(),
                                  );

                                  final sharedData =
                                      context.read<SharedDataCubit>().state;
                                  final stepDown = sharedData.role?.stepDown;

                                  context.read<DashboardBloc>().add(
                                    FetchDashboardData(
                                      tableName:
                                          context
                                              .read<SharedDataCubit>()
                                              .tableName ?? '',
                                      location: sharedData.location ?? '',
                                      mode: sharedData.mode ?? '',
                                      role: stepDown ?? '',
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 300,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 1,
                                    ),
                                    color:
                                        isSelected
                                            ? const Color(
                                              0xFF50B748,
                                            ).withOpacity(0.2)
                                            : Colors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 50,
                                        color: AppColors.primary,
                                      ),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 200,
                                        height: 100,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppStyles.heading.copyWith(
                                                fontSize: 20,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            Text(
                                              "Cost Center: ${e.id}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppStyles.normal,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                // Left Scroll
                Positioned(
                  bottom: 8,
                  right: 60,
                  child: FloatingActionButton(
                    heroTag: 'locationListLeftBtn',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    backgroundColor: AppColors.secondary,
                    mini: true,
                    onPressed: () {
                      if (_scrollController.hasClients) { // FIXED: Check hasClients
                        _scrollController.animateTo(
                          _scrollController.offset - 300,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: const Icon(CupertinoIcons.left_chevron),
                  ),
                ),
                // Right Scroll
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: FloatingActionButton(
                    heroTag: 'locationListRightBtn',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    backgroundColor: AppColors.secondary,
                    mini: true,
                    onPressed: () {
                      if (_scrollController.hasClients) { // FIXED: Check hasClients
                        _scrollController.animateTo(
                          _scrollController.offset + 300,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: const Icon(CupertinoIcons.right_chevron),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}