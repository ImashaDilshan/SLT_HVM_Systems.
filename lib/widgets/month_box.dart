import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_event.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:slt_hire_log/constants/app_colors.dart';
import 'package:slt_hire_log/constants/app_styles.dart';
import 'package:slt_hire_log/extensions/role_extension.dart';

class MonthPickerContainer extends StatefulWidget {
  const MonthPickerContainer({super.key});

  @override
  State<MonthPickerContainer> createState() => _MonthPickerContainerState();
}

class _MonthPickerContainerState extends State<MonthPickerContainer> {
  DateTime selectedDate = DateTime.now();
  @override
  void initState() {
    context.read<SharedDataCubit>().setDate(selectedDate);
    super.initState();
  }

  void _selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: selectedDate,
      monthPickerDialogSettings: MonthPickerDialogSettings(
        headerSettings: PickerHeaderSettings(
          headerBackgroundColor: const Color.fromARGB(255, 0, 123, 255),
        ),
      ),

      headerTitle: Container(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.only(top: 30),
          alignment: Alignment.topCenter,
          height: 200,
          width: 300,
          child: Image.asset(
            "assets/SLTMobitel_Logo.png",
            width: 280,
            height: 200,
          ),
        ),
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      // headerColor: AppColors.primary, // Removed because it's not a valid parameter
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
       final sharedDataCubit =
                                context.read<SharedDataCubit>();
      context.read<SharedDataCubit>().setDate(selectedDate);
      final sharedData = context.read<SharedDataCubit>().state;
final stepDown = sharedData.role!.stepDown;

      context.read<DashboardBloc>().add(
        FetchDashboardData(
          tableName: sharedDataCubit.tableName ?? '',
          location: sharedData.location ?? '',
          mode: sharedData.mode ?? '',
          role: stepDown??''
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String month = DateFormat.MMMM().format(selectedDate);
    final String year = DateFormat.y().format(selectedDate);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(63, 0, 0, 0),
            spreadRadius: 6,
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          hoverColor: const Color(0xFF50B748).withOpacity(0.1),
          splashColor: AppColors.primary.withOpacity(0.1),
          onTap: () => _selectMonth(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  year,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.subheading.copyWith(
                    fontSize: 20,
                    color: const Color.fromARGB(255, 44, 44, 44),
                  ),
                ),
                Text(
                  month,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.heading.copyWith(
                    fontSize: 40,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
