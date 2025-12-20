import 'package:flutter/material.dart';
import 'package:slt_hire_log/extensions/rate_card_service.dart';
import 'package:slt_hire_log/models/rate_card_models.dart';
import 'package:toastification/toastification.dart';

class RentalCalculatorScreen extends StatefulWidget {
  const RentalCalculatorScreen({super.key});

  @override
  State<RentalCalculatorScreen> createState() => _RentalCalculatorScreenState();
}

class _RentalCalculatorScreenState extends State<RentalCalculatorScreen> {
  final RateCardService _rateCardService = RateCardService();
  final _formKey = GlobalKey<FormState>();

  List<CalculatedRateCard> _rateCards = [];
  CalculatedRateCard? _selectedRateCard;

  String _selectedYomCategory = 'AFTER_2000';
  String? _selectedCategory;
  String? _selectedServiceType;
  String? _selectedFuelType;

  List<String> _categories = [];
  List<String> _serviceTypes = [];
  List<String> _fuelTypes = [];

  // Controllers (with sensible defaults)
  final TextEditingController _billingDaysController =
      TextEditingController(text: '30'); // int
  final TextEditingController _workingDaysController =
      TextEditingController(text: '28.5'); // double
  final TextEditingController _kmRunController = TextEditingController(text: '0'); // int
  final TextEditingController _overtimeController =
      TextEditingController(text: '0'); // int
  final TextEditingController _overnightController =
      TextEditingController(text: '0'); // int
  final TextEditingController _absentController =
      TextEditingController(text: '0'); // double
  final TextEditingController _absentDayRateController =
      TextEditingController(text: '0'); // int
  final TextEditingController _vatPercentController =
      TextEditingController(text: '18'); // double

  bool _includeVAT = true;

  Map<String, dynamic>? _apiResult;
  bool _isLoading = false;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _loadRateCards();
  }

  void _showToast(String message, {bool success = false}) {
    toastification.show(
      context: context,
      title: Text(message),
      type: success ? ToastificationType.success : ToastificationType.error,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  Future<void> _loadRateCards() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final rateCards = await _rateCardService.getCalculatedRateCards();
      setState(() {
        _rateCards = rateCards;
        if (rateCards.isNotEmpty) {
          _selectedRateCard = rateCards.first;
          _loadCategories();
        }
        _isLoading = false;
      });
    } catch (e) {
      _showToast('Failed to load rate cards: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    if (_selectedRateCard == null) return;
    try {
      final categories =
          await _rateCardService.getCategories(_selectedRateCard!.id, _selectedYomCategory);
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) {
          _selectedCategory = categories.first;
          _loadServiceTypes();
        }
      });
    } catch (e) {
      _showToast('Failed to load categories: $e');
    }
  }

  Future<void> _loadServiceTypes() async {
    if (_selectedRateCard == null || _selectedCategory == null) return;
    try {
      final serviceTypes =
          await _rateCardService.getServiceTypes(_selectedRateCard!.id, _selectedYomCategory);
      setState(() {
        _serviceTypes = serviceTypes;
        if (serviceTypes.isNotEmpty) {
          _selectedServiceType = serviceTypes.first;
          _loadFuelTypes();
        }
      });
    } catch (e) {
      _showToast('Failed to load service types: $e');
    }
  }

  Future<void> _loadFuelTypes() async {
    if (_selectedRateCard == null ||
        _selectedCategory == null ||
        _selectedServiceType == null) {
      return;
    }
    try {
      final fuelTypes = await _rateCardService.getFuelTypes(
        _selectedRateCard!.id,
        _selectedYomCategory,
        _selectedCategory!,
        _selectedServiceType!,
      );
      setState(() {
        _fuelTypes = fuelTypes;
        if (fuelTypes.isNotEmpty) {
          _selectedFuelType = fuelTypes.first;
        }
      });
    } catch (e) {
      _showToast('Failed to load fuel types: $e');
    }
  }

  int _reqInt(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    if (v == null) throw 'Invalid integer for "${c.text}"';
    return v;
  }

  double _reqDouble(TextEditingController c) {
    final v = double.tryParse(c.text.trim());
    if (v == null) throw 'Invalid number for "${c.text}"';
    return v;
  }

  Future<void> _calculateRental() async {
    if (_selectedRateCard == null ||
        _selectedCategory == null ||
        _selectedServiceType == null ||
        _selectedFuelType == null) {
      _showToast('Please select all required options');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      _showToast('Please fix validation errors');
      return;
    }

    try {
      final body = [
        {
          "calculatedCardId": _selectedRateCard!.id,
          "yomCategory": _selectedYomCategory,
          "categoryCode": _selectedCategory!,
          "serviceType": _selectedServiceType!,
          "fuelType": _selectedFuelType!,
          "rateType": "Monthly",
          "kmRun": _reqInt(_kmRunController),
          "billingDays": _reqInt(_billingDaysController),
          "workingDays": _reqDouble(_workingDaysController),
          "absentDays": _reqDouble(_absentController),
          "absentDayRate": _reqInt(_absentDayRateController),
          "overtimeHours": _reqInt(_overtimeController),
          "overnightStays": _reqInt(_overnightController),
          "includeVAT": _includeVAT,
          "vatPercent": _reqDouble(_vatPercentController),
        }
      ];

      setState(() {
        _isCalculating = true;
      });

      final result = await _rateCardService.calculateViaApi(body);

      setState(() {
        _apiResult = (result.isNotEmpty ? result.first : null) as Map<String, dynamic>?;
        _isCalculating = false;
      });

      if (_apiResult != null) {
        _showToast('Rental calculation successful!', success: true);
      } else {
        _showToast('No result from API');
      }
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
      _showToast('Calculation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F7FB),
        title: const Text('Vehicle Rental Calculator', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Selections
                        DropdownButtonFormField<CalculatedRateCard>(
                          initialValue: _selectedRateCard,
                          items: _rateCards
                              .map((card) => DropdownMenuItem(
                                    value: card,
                                    child: Text(
                                        '${card.baseName} — ${card.calculationDate.toString().substring(0, 10)}'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRateCard = value;
                              _loadCategories();
                            });
                          },
                          decoration: const InputDecoration(labelText: 'Rate Card'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedYomCategory,
                          items: const [
                            DropdownMenuItem(value: 'AFTER_2000', child: Text('After 2000')),
                            DropdownMenuItem(value: 'BEFORE_2000', child: Text('Before 2000')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedYomCategory = val!;
                              _loadCategories();
                            });
                          },
                          decoration: const InputDecoration(labelText: 'Vehicle Age Category'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          items: _categories
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCategory = val;
                              _loadServiceTypes();
                            });
                          },
                          decoration: const InputDecoration(labelText: 'Vehicle Category'),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedServiceType,
                          items: _serviceTypes
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedServiceType = val;
                              _loadFuelTypes();
                            });
                          },
                          decoration: const InputDecoration(labelText: 'Service Type'),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedFuelType,
                          items: _fuelTypes
                              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedFuelType = val),
                          decoration: const InputDecoration(labelText: 'Fuel Type'),
                          validator: (v) => v == null ? 'Required' : null,
                        ),

                        const SizedBox(height: 20),

                        // Inputs grid
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _numField(_kmRunController, 'KM Run', intOnly: true),
                            _numField(_billingDaysController, 'Billing Days', intOnly: true),
                            _numField(_workingDaysController, 'Working Days (e.g. 28.5)'),
                            _numField(_overtimeController, 'Overtime Hours', intOnly: true),
                            _numField(_overnightController, 'Overnight Stays', intOnly: true),
                            _numField(_absentController, 'Absent Days (e.g. 1.5)'),
                            _numField(_absentDayRateController, 'Absent Day Rate', intOnly: true),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Switch(
                              activeThumbColor: const Color.fromARGB(255, 14, 11, 189),
                              value: _includeVAT,
                              onChanged: (v) => setState(() => _includeVAT = v),
                            ),
                            const SizedBox(width: 8),
                            const Text('Include VAT'),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _numField(_vatPercentController, 'VAT % (e.g. 18)'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Calculate button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isCalculating ? null : _calculateRental,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 7, 30, 160),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isCalculating
                                ? const SizedBox(
                                    width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
                                : const Text(
                                    'Calculate Rental',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        if (_apiResult != null) _buildApiResult(_apiResult!),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ---- helpers ----

  Widget _numField(TextEditingController c, String label, {bool intOnly = false}) {
    return SizedBox(
      width: 220,
      child: TextFormField(
        controller: c,
        keyboardType: intOnly
            ? TextInputType.number
            : const TextInputType.numberWithOptions(decimal: true, signed: false),
        validator: (v) {
          final t = (v ?? '').trim();
          if (t.isEmpty) return 'Please enter $label';
          if (intOnly) {
            if (int.tryParse(t) == null) return 'Enter a whole number';
          } else {
            if (double.tryParse(t) == null) return 'Enter a valid number';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildApiResult(Map<String, dynamic> r) {
    // safe read + simple formatter
    String n(dynamic v) {
      if (v == null) return '-';
      if (v is int) return v.toString();
      if (v is double) return v.toStringAsFixed(2);
      return v.toString();
    }

    TableRow row(String label, dynamic value, {bool highlight = false}) {
      return TableRow(children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.green : Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            'Rs. ${n(value)}',
            style: TextStyle(
              color: highlight ? Colors.green : Colors.black,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ]);
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'API Rental Calculation Result',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (r['slabLabel'] != null)
              Text('Slab: ${r['slabLabel']}  |  Agreed KM: ${n(r['agreedKm'])}'),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1)},
              children: [
                row('Base Rental (Prorated)', r['baseRental']),
                row('Base Rental (Full)', r['baseRentalFull']),
                row('Extra Charge', r['extraCharge']),
                row('Overtime Cost', r['overtimeCost']),
                row('Overnight Cost', r['overnightCost']),
                row('Absent Deduction', r['absentDeduction']),
                row('Other Additions', r['otherAdditions']),
                row('Other Deductions', r['otherDeductions']),
                row('Total', r['total'], highlight: true),
                if (r['includeVAT'] == true || r['vat'] != null) row('VAT', r['vat']),
                if (r['grandTotal'] != null)
                  row('Grand Total', r['grandTotal'], highlight: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
