import 'package:flutter/material.dart';
import '../widgets/settings_dialog.dart';

class SettingsIconButton extends StatelessWidget {
  const SettingsIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () => _showSettings(context),
    );
  }

  Future<void> _showSettings(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const SettingsPage(),
    );
  }
}