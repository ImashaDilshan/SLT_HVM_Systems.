
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:slt_hire_log/blocks/add_item_load/add_item_load_bloc.dart';
import 'package:slt_hire_log/blocks/add_item_load/add_item_load_event.dart';
import 'package:slt_hire_log/blocks/navigation/navigation_cubit.dart';
import 'package:slt_hire_log/widgets/custom_widget/cost_card.dart';
import '../../blocks/user/user_bloc.dart';
import '../../blocks/user/user_state.dart';
// <-- import your SharedDataCubit

class CostCenterCards extends StatelessWidget {
  const CostCenterCards({super.key});

  @override
  Widget build(BuildContext context) {
    final sharedData = context.watch<SharedDataCubit>().state;
    final String month = context.watch<SharedDataCubit>().tableName;
    final String mode =
        context.watch<SharedDataCubit>().state.mode?.trim().toLowerCase() ?? '';

    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        if (userState is UserLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userState is UserLoaded) {
          final costCenters = userState.user.costCenters;

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: costCenters.length,
            itemBuilder: (context, index) {
              final c = costCenters[index];
              return GestureDetector(
                onTap: () {
                  context.read<AddItemLoadBloc>().add(FetchAddItemData(c.id));

                  context.read<SharedDataCubit>().setLocation(c.id.toString());
                  print("Selected Cost Center: ${c.id}");

                  context.read<SharedDataCubit>().setMode(mode);
                  context.read<NavigationCubit>().selectIndex(0);
                 
                },
                child: CostCenterCard(
                  costCenterId: c.id,
                  name: c.name,
                  month: month,
                  mode: mode,
                ),
              );
            },
          );
        }

        if (userState is UserError) {
          return Center(child: Text(userState.message));
        }

        return const SizedBox.shrink();
      },
    );
  }
}
