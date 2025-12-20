import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:slt_hire_log/blocks/navigation/navigation_cubit.dart';

import 'package:slt_hire_log/models/user_model.dart';
import 'package:slt_hire_log/screens/desktop_page.dart';
import 'package:slt_hire_log/screens/monthly_reports.dart';
import 'package:slt_hire_log/screens/ratecardscreen.dart';
import 'package:slt_hire_log/screens/summery_screen.dart';
import 'package:slt_hire_log/screens/userauthpage.dart';

class DashboardPage extends StatelessWidget {
  final UserModel user;
  const DashboardPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavigationCubit(),
      child: Scaffold(
        body: Row(
          children: [// Added navigation bar
            Expanded(
              child: BlocBuilder<NavigationCubit, int>(
                builder: (context, index) {
                  final role = context.watch<SharedDataCubit>().state.role ?? 'user';
                  
                  // Protect admin routes from non-admin access
                  if (role != 'admin' && (index == 2 || index == 3)) {
                    return DesktopPage(user: user); // Redirect to home
                  }

                  switch (index) {
                    case 0:
                      return DesktopPage(user: user);
                    case 1:
                      return MonthlyReports(user: user);
                    case 2:
                      return SummeryScreen(user: user);
                    case 3:
                      return Ratecardscreen(user: user);
                    case 4:
                      return Userauthpage();
                    default:
                      return DesktopPage(user: user);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}