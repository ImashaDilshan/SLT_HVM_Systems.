import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:slt_hire_log/blocks/navigation/navigation_cubit.dart';
import 'package:slt_hire_log/constants/app_colors.dart';


class NaviationBar extends StatelessWidget {
  const NaviationBar({super.key});

  // Define items with admin-only flags (fixed duplicate label)
  static const List<Map<String, dynamic>> _allNavItems = [
    {"icon": CupertinoIcons.home, "label": "Home", "index": 0, "adminOnly": false},
    {"icon": CupertinoIcons.chart_pie, "label": "Status", "index": 1, "adminOnly": false},
    {"icon": CupertinoIcons.table, "label": "Result", "index": 2, "adminOnly": true},
    {"icon": CupertinoIcons.doc_text, "label": "Rate Card", "index": 3, "adminOnly": true},
    {"icon": CupertinoIcons.person, "label": "Profile", "index": 4, "adminOnly": false},
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = context.watch<NavigationCubit>().state;
    final role = context.watch<SharedDataCubit>().state.role ?? 'user'; // Get role

    return Container(
      width: 130,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: AppColors.secondary,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(55, 0, 0, 0),
            spreadRadius: 6,
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Show items based on role
          for (var item in _allNavItems)
            if (!item["adminOnly"] || role == 'admin')
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => context.read<NavigationCubit>().selectIndex(item["index"]),
                  hoverColor: const Color.fromARGB(255, 0, 89, 255).withOpacity(0.2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    width: 120,
                    decoration: BoxDecoration(
                      color: selectedIndex == item["index"]
                          ? const Color(0xFF50B748).withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          item["icon"],
                          size: 30,
                          color: selectedIndex == item["index"] ? const Color(0xFF50B748) : Colors.black,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item["label"],
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedIndex == item["index"] ? const Color(0xFF50B748) : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
