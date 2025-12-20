import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_event.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:slt_hire_log/extensions/role_extension.dart';

class ModeSelect extends StatefulWidget {
  const ModeSelect({super.key});

  @override
  State<ModeSelect> createState() => _ModeSelectState();
}

class _ModeSelectState extends State<ModeSelect> {
  int selectedIndex = 0;

  void _onItemTap(int index) {
    setState(() {
      selectedIndex = index;
    });
    context.read<SharedDataCubit>().setMode(
      index == 0
          ? "Self Vehicles"
          : index == 1
          ? "Non Self Vehicles"
          : "Short Period",
    );
    final sharedDataCubit = context.read<SharedDataCubit>();
    final sharedData = context.read<SharedDataCubit>().state;
    final stepDown = sharedData.role!.stepDown;
    context.read<DashboardBloc>().add(
      FetchDashboardData(
        tableName: sharedDataCubit.tableName ?? '',
        location: sharedData.location ?? '',
        role: stepDown??'' ,
        mode:
            index == 0
                ? "Self Vehicles"
                : index == 1
                ? "Non Self Vehicles"
                : "Short Period",
      ),
    );
  }

  @override
  void initState() {
    context.read<SharedDataCubit>().setMode("Self Vehicles");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,

      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(3, (index) {
          final bool isSelected = selectedIndex == index;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _onItemTap(index),
              splashColor: Color(0xFF50B748).withOpacity(0.3),
              hoverColor: Color(0xFF50B748).withOpacity(0.15),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Color.fromARGB(255, 189, 247, 185)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  index == 0
                      ? "Self Vehicles"
                      : index == 1
                      ? "Non Self Vehicles"
                      : "Short Period",
                  style: TextStyle(
                    color: isSelected ? Color(0xFF50B748) : Colors.black,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
