import 'package:flutter/material.dart';
import 'package:slt_hire_log/models/user_model.dart';


class DashboardPage1 extends StatelessWidget {
  final UserModel user;

  const DashboardPage1({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome, ${user.name}")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Role: ${user.role}"),
          Text("Position: ${user.position}"),
          const SizedBox(height: 20),
          const Text("Cost Centers:"),
          ...user.costCenters.map((e) => Text("- ${e.name}")),
        ],
      ),
    );
  }
}
