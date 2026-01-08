// widgets/edit_rate_dialog.dart
import 'package:flutter/material.dart';

class EditRateDialog extends StatefulWidget {
  final Map<String, dynamic> rate;
  final bool isDaily;

  const EditRateDialog({super.key, required this.rate, this.isDaily = false});

  @override
  _EditRateDialogState createState() => _EditRateDialogState();
}

class _EditRateDialogState extends State<EditRateDialog> {
  late Map<String, dynamic> editedRate;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    editedRate = Map.from(widget.rate);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Rate'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isDaily)
                TextFormField(
                  initialValue: editedRate['monthlyRentalLKR'].toString(),
                  decoration: InputDecoration(labelText: 'Base Rate (LKR)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => editedRate['monthlyRentalLKR'] = double.tryParse(v) ?? 0.0,
                ),
              TextFormField(
                initialValue: editedRate['additionalKmRateLKR']?.toString() ?? '',
                decoration: InputDecoration(labelText: 'Add/km Rate (LKR)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => editedRate['additionalKmRateLKR'] = double.tryParse(v),
              ),
              if (!widget.isDaily) ...[
                TextFormField(
                  initialValue: editedRate['overTimeRateLKR'].toString(),
                  decoration: InputDecoration(labelText: 'Over Time Rate (LKR)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => editedRate['overTimeRateLKR'] = double.tryParse(v) ?? 78.75,
                ),
                TextFormField(
                  initialValue: editedRate['nightAllowanceLKR'].toString(),
                  decoration: InputDecoration(labelText: 'Night Allowance (LKR)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => editedRate['nightAllowanceLKR'] = double.tryParse(v) ?? 525.00,
                ),
              ],
              if (widget.isDaily)
                TextFormField(
                  initialValue: editedRate['dailyRateLKR'].toString(),
                  decoration: InputDecoration(labelText: 'Daily Rate (LKR)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => editedRate['dailyRateLKR'] = double.tryParse(v) ?? 0.0,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, editedRate);
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}