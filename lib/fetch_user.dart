import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:slt_hire_log/auth_gate.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';

import 'package:slt_hire_log/blocks/add_item_load/add_item_load_bloc.dart';
import 'package:slt_hire_log/blocks/add_item_load/add_item_load_event.dart';
import 'package:slt_hire_log/blocks/role/user_role_cubit.dart';
import 'package:slt_hire_log/blocks/user/user_bloc.dart';
import 'package:slt_hire_log/blocks/user/user_state.dart';
import 'package:slt_hire_log/screens/dashboard_page.dart';


class FetchUser extends StatefulWidget {
  const FetchUser({super.key});

  @override
  State<FetchUser> createState() => _FetchUserState();
}

class _FetchUserState extends State<FetchUser> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state is UserLoading) {
          return Scaffold(
            body: Center(
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

        if (state is UserError) {
          return Scaffold(
            body: Center(child: Text(state.message)),
          );
        }

        if (state is UserLoaded && !_navigated) {
          // 👇 Prevent navigating multiple times
          _navigated = true;

          // Set user in cubit
          context.read<UserInfoCubit>().setUser(state.user);
          final costCenter = state.user.costCenters.first.id;
          context.read<SharedDataCubit>().setLocation(costCenter.toString());
          context.read<AddItemLoadBloc>().add(FetchAddItemData(costCenter));
    context.read<SharedDataCubit>().setrole(state.user.role);
          // Defer navigation to after current frame to avoid build errors
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardPage(user: state.user),
              ),
            );
          });

          // While navigating, show shimmer
          return Scaffold(
            body: Center(
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

        // Default case: show login page
        return const AuthGate();
      },
    );
  }
}
