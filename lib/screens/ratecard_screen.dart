// screens/ratecard_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/ratecard/ratecard_bloc.dart';
import 'package:slt_hire_log/widgets/edit_rate_dialog.dart';
import '../models/ratecard.dart';

class RateCardScreen1 extends StatefulWidget {
  const RateCardScreen1({super.key});

  @override
  _RateCardScreen1State createState() => _RateCardScreen1State();
}

class _RateCardScreen1State extends State<RateCardScreen1>
    with TickerProviderStateMixin {
  String selectedDate = '2025-05-01';
  final List<String> availableDates = [
    '2024-12-01',
    '2025-04-01',
    '2025-05-01',
    '2024-05-01'
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<RateCardBloc>().add(LoadRateCardsByDate(selectedDate));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SLT Rate Cards'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Monthly Rates'), Tab(text: 'Daily Rates')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFullRateCardDialog,
        child: Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date Selector
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text('Effective Date:', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedDate,
                        isExpanded: true,
                        items:
                            availableDates.map((date) {
                              return DropdownMenuItem(
                                value: date,
                                child: Text(date),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDate = value!;
                          });
                          context.read<RateCardBloc>().add(
                            LoadRateCardsByDate(selectedDate),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // YOM Badge
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "YOM: Before 2000",
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildMonthlyTab(), _buildDailyTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTab() {
    return BlocBuilder<RateCardBloc, RateCardState>(
      builder: (context, state) {
        if (state is RateCardLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is RateCardLoaded) {
          final grouped = <String, List<MonthlyRate>>{};
          for (var r in state.monthlyRates) {
            String key = '${r.vehicle} - ${r.fuelType}';
            grouped.putIfAbsent(key, () => []);
            grouped[key]!.add(r);
          }
          return ListView.builder(
            itemCount: grouped.length,
            itemBuilder: (ctx, i) {
              final entry = grouped.entries.elementAt(i);
              return _buildMonthlyTable(entry.key, entry.value);
            },
          );
        }
        if (state is RateCardError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return Container();
      },
    );
  }

  Widget _buildMonthlyTable(String title, List<MonthlyRate> data) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.blue[700],
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('KM Slab')),
                DataColumn(label: Text('Base Rate (LKR)')),
                DataColumn(label: Text('Add/km (LKR)')),
                DataColumn(label: Text('OT (LKR)')),
                DataColumn(label: Text('Night (LKR)')),
                DataColumn(label: Text('Edit')),
              ],
              rows:
                  data.map((r) {
                    return DataRow(
                      cells: [
                        DataCell(Text(r.kmSlab)),
                        DataCell(Text(r.monthlyRentalLKR.toStringAsFixed(2))),
                        DataCell(
                          Text(
                            r.additionalKmRateLKR?.toStringAsFixed(2) ?? '—',
                          ),
                        ),
                        DataCell(Text(r.overTimeRateLKR.toStringAsFixed(2))),
                        DataCell(Text(r.nightAllowanceLKR.toStringAsFixed(2))),
                        DataCell(
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.blue,
                            ),
                            onPressed: () async {
                              final result = await showDialog(
                                context: context,
                                builder:
                                    (ctx) => EditRateDialog(
                                      rate: {
                                        'effectiveDate': selectedDate,
                                        'vehicle': r.vehicle,
                                        'fuelType': r.fuelType,
                                        'kmSlab': r.kmSlab,
                                        'monthlyRentalLKR': r.monthlyRentalLKR,
                                        'additionalKmRateLKR':
                                            r.additionalKmRateLKR,
                                        'overTimeRateLKR': r.overTimeRateLKR,
                                        'nightAllowanceLKR':
                                            r.nightAllowanceLKR,
                                      },
                                    ),
                              );
                              if (result != null) {
                                await _updateMonthlyRate(result);
                                context.read<RateCardBloc>().add(
                                  LoadRateCardsByDate(selectedDate),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTab() {
    return BlocBuilder<RateCardBloc, RateCardState>(
      builder: (context, state) {
        if (state is RateCardLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is RateCardLoaded) {
          final grouped = <String, List<DailyRate>>{};
          for (var r in state.dailyRates) {
            grouped.putIfAbsent(r.vehicle, () => []);
            grouped[r.vehicle]!.add(r);
          }
          return ListView.builder(
            itemCount: grouped.length,
            itemBuilder: (ctx, i) {
              final entry = grouped.entries.elementAt(i);
              return _buildDailyTable(entry.key, entry.value);
            },
          );
        }
        if (state is RateCardError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return Container();
      },
    );
  }

  Widget _buildDailyTable(String title, List<DailyRate> data) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.green[700],
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Fuel Type')),
                DataColumn(label: Text('Daily Rate (100 km)')),
                DataColumn(label: Text('Add/km (LKR)')),
                DataColumn(label: Text('Edit')),
              ],
              rows:
                  data.map((r) {
                    return DataRow(
                      cells: [
                        DataCell(Text(r.fuelType)),
                        DataCell(
                          Text('LKR ${r.dailyRateLKR.toStringAsFixed(2)}'),
                        ),
                        DataCell(
                          Text(
                            'LKR ${r.additionalKmRateLKR.toStringAsFixed(2)}',
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.blue,
                            ),
                            onPressed: () async {
                              final result = await showDialog(
                                context: context,
                                builder:
                                    (ctx) => EditRateDialog(
                                      rate: {
                                        'effectiveDate': selectedDate,
                                        'vehicle': r.vehicle,
                                        'fuelType': r.fuelType,
                                        'dailyRateLKR': r.dailyRateLKR,
                                        'additionalKmRateLKR':
                                            r.additionalKmRateLKR,
                                      },
                                      isDaily: true,
                                    ),
                              );
                              if (result != null) {
                                await _updateDailyRate(result);
                                context.read<RateCardBloc>().add(
                                  LoadRateCardsByDate(selectedDate),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMonthlyRate(Map<String, dynamic> data) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dpdlab1.slt.lk:9126/api'));
    try {
      await dio.put('/ratecards/monthly', data: data);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rate updated successfully')));
    } on DioException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: ${e.message}')));
    }
  }

  Future<void> _updateDailyRate(Map<String, dynamic> data) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dpdlab1.slt.lk:9126/api'));
    try {
      await dio.put('/ratecards/daily', data: data);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Daily rate updated')));
    } on DioException catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: ${e.message}')));
    }
  }

  Future<void> _addMonthlyRate(Map<String, dynamic> data) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dpdlab1.slt.lk:9126/api'));
    try {
      await dio.put('/ratecards/monthlys', data: data); // ✅ /monthly
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added')));
    } on DioException catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
    }
  }

  Future<void> _addDailyRate(Map<String, dynamic> data) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dpdlab1.slt.lk:9126/api'));
    try {
      await dio.put('/ratecards/dailys', data: data); // ✅ /daily
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added')));
    } on DioException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
    }
  }

  void _showAddFullRateCardDialog() {
  String effectiveDate = '2025-05-01';
  final monthlyRates = <Map<String, dynamic>>[];
  final dailyRates = <Map<String, dynamic>>[];

  // ✅ All vehicles with fuel
  final List<Map<String, String>> vehicleConfigs = [
    {'vehicle': 'Cars (sedan)', 'fuelType': 'Petrol'},
    {'vehicle': 'Vans (Field use)', 'fuelType': 'Diesel'},
    {'vehicle': 'Vans (Field use)', 'fuelType': 'Petrol'},
    {'vehicle': 'Passenger Vans', 'fuelType': 'Petrol'},
    {'vehicle': 'Double Cabs-2WD', 'fuelType': 'Diesel'},
    {'vehicle': 'Double Cabs-4WD', 'fuelType': 'Diesel'},
  ];

  final List<String> kmSlabs = [
    'Upto 1000 km',
    '1001-1500 km',
    '1501-2000 km',
    '2001-2500 km',
    'Above 2500 km'
  ];

  // ✅ Fill Monthly Rates
  for (var config in vehicleConfigs) {
    for (var slab in kmSlabs) {
      monthlyRates.add({
        'vehicle': config['vehicle'],
        'fuelType': config['fuelType'],
        'kmSlab': slab,
        'monthlyRentalLKR': 0.0,
        'additionalKmRateLKR': slab == 'Above 2500 km' ? 0.0 : null,
        'overTimeRateLKR': 78.75,
        'nightAllowanceLKR': 525.00,
      });
    }
  }

  // ✅ Daily Rates (only Vans - Diesel & Petrol)
  for (var config in vehicleConfigs) {
    if (config['vehicle'] == 'Vans (Field use)') {
      dailyRates.add({
        'vehicle': config['vehicle'],
        'fuelType': config['fuelType'],
        'dailyRateLKR': 0.0,
        'additionalKmRateLKR': 0.0,
      });
    }
  }

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Full Rate Card',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Enter effective date and fill all rates by vehicle',
                style: TextStyle(fontSize: 14, color: Colors.blue[600]),
              ),
            ],
          ),
          content: SizedBox(
            width: 900,
            height: 600,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // 📅 Effective Date
                  Card(
                    color: Colors.blue[700],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Text(
                            'Effective Date:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: effectiveDate,
                              onChanged: (v) => setState(() => effectiveDate = v),
                              decoration: InputDecoration(
                                hintText: 'YYYY-MM-DD',
                                filled: true,
                                fillColor: Colors.blue[100],
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // 🟦 Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(8),
                      
                    ),
                    child: TabBar(
                      labelColor: Colors.blue[800],
                      unselectedLabelColor: Colors.white,
                      indicator: BoxDecoration(
                        color: const Color.fromARGB(255, 187, 222, 251),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tabs: [
                        Tab(text: '  Monthly Rates  '),
                        Tab(text: '  Daily Rates  '),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),

                  // 📊 Tab Content
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 📅 MONTHLY: By Vehicle
                        SingleChildScrollView(
                          child: Column(
                            children: vehicleConfigs.map((config) {
                              final vehicleRates = monthlyRates
                                  .where((r) =>
                                      r['vehicle'] == config['vehicle'] &&
                                      r['fuelType'] == config['fuelType'])
                                  .toList();

                              return _buildVehicleMonthlySection(
                                '${config['vehicle']} - ${config['fuelType']}',
                                vehicleRates,
                              );
                            }).toList(),
                          ),
                        ),
                        // 📅 DAILY: By Fuel Type
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              for (var rate in dailyRates)
                                _buildDailyRateRow(rate),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Colors.blue[800])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final success = await _saveFullRateCard(effectiveDate, monthlyRates, dailyRates);
                if (success) {
                  Navigator.pop(ctx);
                }
              },
              child: Text('Save All'),
            ),
          ],
        );
      },
    ),
  );
}
Widget _buildDailyRateRow(Map<String, dynamic> rate) {
  return Card(
    margin: EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '${rate['vehicle']} - ${rate['fuelType']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: _numberField(rate['dailyRateLKR'].toString(), (v) {
              rate['dailyRateLKR'] = double.tryParse(v) ?? 0.0;
            }),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: _numberField(rate['additionalKmRateLKR'].toString(), (v) {
              rate['additionalKmRateLKR'] = double.tryParse(v) ?? 0.0;
            }),
          ),
        ],
      ),
    ),
  );
}

Widget _buildVehicleMonthlySection(String title, List<Map<String, dynamic>> rates) {
  return Card(
    margin: EdgeInsets.only(bottom: 16),
    elevation: 3,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          color: Colors.blue[700],
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        DataTable(
          headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.blue[700]!),
          dataRowHeight: 48,
          columns: [
            DataColumn(label: Text('KM Slab', style: _headerStyle())),
            DataColumn(label: Text('Base (LKR)', style: _headerStyle())),
            DataColumn(label: Text('Add/km', style: _headerStyle())),
            DataColumn(label: Text('OT (LKR)', style: _headerStyle())),
            DataColumn(label: Text('Night (LKR)', style: _headerStyle())),
          ],
          rows: rates.map((rate) {
            return DataRow(
              cells: [
                DataCell(Text(rate['kmSlab']!, style: _cellStyle())),
                DataCell(_numberField(rate['monthlyRentalLKR'].toString(), (v) {
                  rate['monthlyRentalLKR'] = double.tryParse(v) ?? 0.0;
                })),
                DataCell(
                  rate['kmSlab'] == 'Above 2500 km'
                      ? _numberField((rate['additionalKmRateLKR'] ?? '').toString(), (v) {
                          rate['additionalKmRateLKR'] = double.tryParse(v);
                        })
                      : Text('—', style: TextStyle(color: Colors.grey)),
                ),
                DataCell(_numberField(rate['overTimeRateLKR'].toString(), (v) {
                  rate['overTimeRateLKR'] = double.tryParse(v) ?? 78.75;
                })),
                DataCell(_numberField(rate['nightAllowanceLKR'].toString(), (v) {
                  rate['nightAllowanceLKR'] = double.tryParse(v) ?? 525.00;
                })),
              ],
            );
          }).toList(),
        ),
      ],
    ),
  );
}
TextStyle _headerStyle() {
  return TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );
}

TextStyle _cellStyle() {
  return TextStyle(fontSize: 13);
}

Widget _numberField(String value, Function(String) onChanged) {
  return SizedBox(
    width: 90,
    child: TextFormField(
      initialValue: value,
      onChanged: onChanged,
      style: TextStyle(fontSize: 13),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
    ),
  );
}

  Future<bool> _saveFullRateCard(
    String effectiveDate,
    List<Map<String, dynamic>> monthlyRates,
    List<Map<String, dynamic>> dailyRates,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dpdlab1.slt.lk:9126/api'));

    try {
      await dio.put(
        '/ratecards/monthlys',
        data: {'effectiveDate': effectiveDate, 'rates': monthlyRates},
      );

      await dio.put(
        '/ratecards/dailys',
        data: {'effectiveDate': effectiveDate, 'rates': dailyRates},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Full rate card added successfully')),
      );

      // Refresh UI
      context.read<RateCardBloc>().add(LoadRateCardsByDate(effectiveDate));

      return true; // ✅ Success
    } on DioException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: ${e.message}')));
      return false; // ❌ Failed
    }
  }
}
