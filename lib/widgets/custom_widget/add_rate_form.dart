// widgets/custom_widget/add_rate_form.dart
import 'package:flutter/material.dart';

class AddRateForm extends StatelessWidget {
  final bool isDaily;
  final String? initialDate; // Optional: prefill if needed
  final Function(Map<String, dynamic>) onAdd;

  const AddRateForm({
    super.key,
    required this.isDaily,
    this.initialDate,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final Map<String, dynamic> formData = {};
    String? effectiveDate = initialDate;

    List<String> getVehicleOptions() {
      if (isDaily) return ['Field Van'];
      return [
        'Cars (sedan)',
        'Vans (Field use)',
        'Passenger Vans',
        'Double Cabs-2WD',
        'Double Cabs-4WD'
      ];
    }

    List<String> getFuelOptions(String? vehicle) {
      if (vehicle == 'Passenger Vans') return ['Petrol'];
      if (isDaily && vehicle == 'Field Van') return ['Diesel', 'Petrol'];
      return ['Petrol', 'Diesel'];
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOM: Before 2000',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // ✅ Effective Date Input
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Effective Date (YYYY-MM-DD)',
                  hintText: 'e.g., 2025-05-01',
                ),
                initialValue: effectiveDate,
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (!v.contains(RegExp(r'\d{4}-\d{2}-\d{2}'))) {
                    return 'Enter valid date: YYYY-MM-DD';
                  }
                  return null;
                },
                onChanged: (v) => effectiveDate = v,
              ),
              SizedBox(height: 12),

              DropdownButtonFormField<String>(
                hint: Text('Select Vehicle'),
                items: getVehicleOptions().map((v) {
                  return DropdownMenuItem(value: v, child: Text(v));
                }).toList(),
                onChanged: (value) {
                  formData['vehicle'] = value;
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              SizedBox(height: 12),

              DropdownButtonFormField<String>(
                hint: Text('Select Fuel Type'),
                items: getFuelOptions(formData['vehicle']).map((f) {
                  return DropdownMenuItem(value: f, child: Text(f));
                }).toList(),
                onChanged: (value) {
                  formData['fuelType'] = value;
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              SizedBox(height: 12),

              if (!isDaily)
                DropdownButtonFormField<String>(
                  hint: Text('Select KM Slab'),
                  items: [
                    'Upto 1000 km',
                    '1001-1500 km',
                    '1501-2000 km',
                    '2001-2500 km',
                    'Above 2500 km'
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (value) {
                    formData['kmSlab'] = value;
                    if (value != 'Above 2500 km') {
                      formData['additionalKmRateLKR'] = null;
                    }
                  },
                  validator: (v) => v == null ? 'Required' : null,
                ),
              SizedBox(height: 12),

              TextFormField(
                decoration: InputDecoration(
                  labelText: isDaily ? 'Daily Rate (100 km)' : 'Base Rate (LKR)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onChanged: (v) => formData[isDaily ? 'dailyRateLKR' : 'monthlyRentalLKR'] = double.tryParse(v) ?? 0.0,
              ),
              SizedBox(height: 12),

              TextFormField(
                decoration: InputDecoration(labelText: 'Additional/km (LKR)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => formData['additionalKmRateLKR'] = double.tryParse(v),
              ),
              SizedBox(height: 12),

              if (!isDaily) ...[
                TextFormField(
                  decoration: InputDecoration(labelText: 'Over Time (LKR)'),
                  keyboardType: TextInputType.number,
                  initialValue: '78.75',
                  onChanged: (v) => formData['overTimeRateLKR'] = double.tryParse(v) ?? 78.75,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Night Allowance (LKR)'),
                  keyboardType: TextInputType.number,
                  initialValue: '525.00',
                  onChanged: (v) => formData['nightAllowanceLKR'] = double.tryParse(v) ?? 525.00,
                ),
                SizedBox(height: 12),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        formData['effectiveDate'] = effectiveDate;
                        onAdd(formData);
                      }
                    },
                    child: Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}