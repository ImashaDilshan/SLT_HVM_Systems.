import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const CustomButton({super.key, required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(160, 48),
          backgroundColor: isPrimary ? Colors.yellow[300] : Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {},
        child: Text(label),
      ),
    );
  }
}