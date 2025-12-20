import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class FuelPriceUpdateDialog extends StatefulWidget {
  final Function()? onSuccess;

  const FuelPriceUpdateDialog({super.key, this.onSuccess});

  @override
  _FuelPriceUpdateDialogState createState() => _FuelPriceUpdateDialogState();
}

class _FuelPriceUpdateDialogState extends State<FuelPriceUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dieselController = TextEditingController();
  final TextEditingController _petrolController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  @override
  void dispose() {
    _dieselController.dispose();
    _petrolController.dispose();
    super.dispose();
  }

  Future<void> _updateFuelPrices() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final dio = Dio();
      final response = await dio.post(
        'http://localhost:3000/api/calculate',
        data: {
          'diesel_price': double.parse(_dieselController.text),
          'petrol_price': double.parse(_petrolController.text),
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isSuccess = true;
          _message = 'Fuel prices updated successfully!';
        });
        
        // Call success callback if provided
        widget.onSuccess?.call();
        
        // Auto-close after 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        setState(() {
          _isSuccess = false;
          _message = 'Failed to update prices: ${response.data['error'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 400,
        height: 320,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Update Fuel Prices',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  
                  TextFormField(
                    controller: _dieselController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Diesel Price (Rs.)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_gas_station),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter diesel price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  
                  TextFormField(
                    controller: _petrolController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Petrol Price (Rs.)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_gas_station),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter petrol price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  
                  if (_message.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                        border: Border.all(
                          color: _isSuccess ? Colors.green : Colors.red,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _message,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green : Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  if (_message.isNotEmpty) SizedBox(height: 15),
                  
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Cancel', style: TextStyle(
                                  color: const Color.fromARGB(255, 0, 11, 165)
                                ),),
                                
                              ),
                              
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _updateFuelPrices,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 0, 11, 165),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Update Prices'),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}