import 'package:flutter/material.dart';

class StatusBox extends StatelessWidget {
  final String statusText;

  const StatusBox({super.key, required this.statusText});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 6,
            backgroundColor: Colors.orange,
          ),
          const SizedBox(width: 10),
          Text("Status: $statusText", style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}