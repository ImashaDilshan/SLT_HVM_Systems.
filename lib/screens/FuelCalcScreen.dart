// screens/FuelCalcScreen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FuelCalcScreen extends StatelessWidget {
  const FuelCalcScreen({super.key});

  // Function to show popup and calculate
  Future<void> _showCalculationDialog(BuildContext context) async {
    final petrolController = TextEditingController();
    final dieselController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Calculate New Rates'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: petrolController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New Petrol Price (LKR)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dieselController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New Diesel Price (LKR)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final petrol = double.tryParse(petrolController.text);
                final diesel = double.tryParse(dieselController.text);

                if (petrol == null || diesel == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid numbers'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Call your backend
                  final response = await http.post(
                    Uri.parse('http://localhost:3000/api/calculaten'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'petrol': petrol, 'diesel': diesel}),
                  );

                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    final version = data['version'] ?? 'Unknown';

                    // Success
                    Navigator.of(context).pop(); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Success! Version: $version'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Failed: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Calculate'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Rate Calculator'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showCalculationDialog(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
          child: const Text('🔧 Calculate New Rates'),
        ),
      ),
    );
  }
}