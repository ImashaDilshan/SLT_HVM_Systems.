import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart' as csv;

// Platform-specific imports
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'dart:io' as io; // For Windows

import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';

/// ---- CONFIG ----
const String kBaseUrl = 'https://dpdlab1.slt.lk:9126';

/// ---- MODELS ----
class TableSummaryPayload {
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> summary;
 // Add this near _selectedSupplier

  TableSummaryPayload({required this.rows, required this.summary});

  factory TableSummaryPayload.fromJson(Map<String, dynamic> json) {
    final rows = (json['rows'] as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>))
        .toList();
    final summary = (json['summary'] as Map<String, dynamic>);
    return TableSummaryPayload(rows: rows, summary: summary);
  }
}

/// ---- API ----
class TableSummaryApi {
  static Future<TableSummaryPayload> fetch({
    required String tableName,
    Map<String, dynamic>? filters,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/table-summary');

    final body = {
      "table": tableName,
      "filters": {
        "accept_role": "admin",
        ...?filters,
      },
      "includeVAT": true,
      "vatPercent": 18,
      "advancedPercent": 90,
    };

    final resp = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return TableSummaryPayload.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
  }

  static Future<String> downloadCsv({
    required String tableName,
    Map<String, dynamic>? filters,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/table-summary/csv');

    final body = {
      "table": tableName,
      "filters": {
        "accept_role": "admin",
        ...?filters,
      },
      "includeVAT": true,
      "vatPercent": 18,
      "advancedPercent": 90,
    };

    final resp = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return resp.body;
    } else {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
  }
}
  String? _selectedType;
/// ---- HELPERS ----
String formatNum(num? n, {int fraction = 2}) {
  if (n == null) return '-';
  final str = n.toStringAsFixed(fraction);
  final parts = str.split('.');
  final rgx = RegExp(r'\B(?=(\d{3})+(?!\d))');
  final left = parts[0].replaceAllMapped(rgx, (m) => ',');
  return parts.length > 1 ? '$left.${parts[1]}' : left;
}

Color get zebraA => const Color(0xFFF8FAFC);
Color get zebraB => const Color(0xFFFFFFFF);
const _darkBlue = Color(0xFF0A2540);
const _accentBlue = Color(0xFF0E4C92);

/// ---- SCREEN ----
class TableSummaryScreen extends StatefulWidget {
  const TableSummaryScreen({super.key});

  @override
 State<TableSummaryScreen> createState() => _TableSummaryScreenState();
}

class _TableSummaryScreenState extends State<TableSummaryScreen> {
  Future<TableSummaryPayload>? _future;
  final TextEditingController _costCenterController = TextEditingController();
  String? _selectedSupplier;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _load();
    
    _costCenterController.addListener(() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _load();
      });
    });
  }

  @override
  void dispose() {
    _costCenterController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

void _load() {
  final tableName = context.read<SharedDataCubit>().tableName;
  final filters = <String, dynamic>{};
  
  final costCenter = _costCenterController.text.trim();
  if (costCenter.isNotEmpty) {
    filters['cost_center'] = costCenter;
  }
  
  // Add Type filter
  if (_selectedType != null && _selectedType!.isNotEmpty) {
    filters['type'] = _selectedType;
  }
  
  if (_selectedSupplier != null && _selectedSupplier!.isNotEmpty) {
    filters['supplier'] = _selectedSupplier;
  }
  
  setState(() {
    _future = TableSummaryApi.fetch(
      tableName: tableName,
      filters: filters,
    );
  });
}

Future<void> _downloadCsv() async {
  try {
    final data = await _future;
    if (data == null) throw Exception('No data loaded');

    final csvData = _generateCsvFromData(data);
    final fileName = 'table_summary_${DateTime.now().toIso8601String().split('T').first}.csv';
    
    // Add Type filter to CSV generation if needed
    // (Your backend should handle this based on the filters sent)
    
    if (kIsWeb) {
      final blob = html.Blob([csvData], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final downloadsDir = await _getDownloadsDirectory();
      final filePath = '${downloadsDir.path}\\$fileName';
      final file = io.File(filePath);
      await file.writeAsString(csvData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV saved to Downloads folder'),
          action: SnackBarAction(
            label: 'Open Folder',
            onPressed: () async {
              await io.Process.run('explorer', ['/select,', filePath]);
            },
          ),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download failed: $e')),
    );
  }
}

String _generateCsvFromData(TableSummaryPayload data) {
  // Define headers matching your table columns
  const headers = [
    'Ser', 'User', 'Ref No', 'Vehicle #', 'Type', 'WD', 'KM', 
    'Rental', 'OT', 'O/N', 'Ex.KM', 'Ex.Amount', 'Absent', 
    'Total', 'VAT(18%)', 'Grand', 'Supplier', 'Fuel', 'RateCat', 'Period'
  ];
  
  // Convert rows to CSV format
  final rows = data.rows.map((row) {
    return [
      row['ser_no'] ?? '',
      row['user'] ?? '',
      row['ref_no'] ?? '',
      row['vehicle_no'] ?? '',
      row['vehicle_type'] ?? '',
      row['working_days'] ?? '',
      row['km_run'] ?? '',
      row['rental'] ?? '',
      row['ot_amount'] ?? '',
      row['overnight_amount'] ?? '',
      row['excess_km'] ?? '',
      row['excess_amount'] ?? '',
      row['absent_deduct_amount'] ?? '',
      row['total'] ?? '',
      row['tax_18_percent'] ?? '',
      row['grand_total'] ?? '',
      row['supplier'] ?? '',
      row['fuel_type'] ?? '',
      row['rate_category'] ?? '',
      row['rate_period'] ?? '',
    ];
  }).toList();
  
  // Generate CSV string
  return const csv.ListToCsvConverter().convert([headers, ...rows]);
}
  // Helper to get Downloads directory on Windows
  Future<io.Directory> _getDownloadsDirectory() async {
    // On Windows, try common Downloads path
    final homeDir = io.Platform.environment['USERPROFILE'];
    if (homeDir != null) {
      final downloadsDir = io.Directory('$homeDir\\Downloads');
      if (await downloadsDir.exists()) {
        return downloadsDir;
      }
    }
    // Fallback to documents
    return io.Directory('${io.Platform.environment['USERPROFILE']!}\\Documents');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildFilterControls(),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<TableSummaryPayload>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Failed to load: ${snap.error}',
                          style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }
                final data = snap.data!;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1200;
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: RecordsTable(rows: data.rows)),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: wide ? 380 : 320,
                            child: SummaryPanel(summary: data.summary),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

Widget _buildFilterControls() {
  const double borderRadius = 20.0;

  return Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16).copyWith(bottom: 0),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cost Center Filter
          Expanded(
            flex: 2,
            child: TextField(
              controller: _costCenterController,
              decoration: InputDecoration(
                labelText: 'Cost Center',
                hintText: 'Enter cost center number',
                prefixIcon: const Icon(Icons.numbers),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          
          // Type Filter - NEW DROPDOWN
          Expanded(
            flex: 2,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  hint: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text('Select Type'),
                  ),
                  isExpanded: true,
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.arrow_drop_down),
                  ),
                  menuMaxHeight: 250,
                  items: const [
                    'Self Vehicles',
                    'Non Self Vehicles',
                    'Short Period',
                  ].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                      _load();
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Supplier Filter
          Expanded(
            flex: 2,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Supplier',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSupplier,
                  hint: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text('Select Supplier'),
                  ),
                  isExpanded: true,
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.arrow_drop_down),
                  ),
                  menuMaxHeight: 300,
                  items: const [
                    'COMTEC SYSTEMS [PVT] LTD',
                    'PRIME TOURS AND ARRIVALS (PVT) LTD',
                    'SHAKYA CEYLON TRAVELS AND TOURS [PVT]LTD',
                  ].map((supplier) {
                    return DropdownMenuItem(
                      value: supplier,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          supplier,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSupplier = value;
                      _load();
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Download CSV Button
          ElevatedButton.icon(
            onPressed: _downloadCsv,
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('Download CSV',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
          
          // Clear Filters Button
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _costCenterController.clear();
                _selectedType = null; // Clear Type filter
                _selectedSupplier = null;
                _load();
              });
            },
            tooltip: 'Clear filters',
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[200],
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}}

/// ---- TABLE ----
class RecordsTable extends StatefulWidget {
  const RecordsTable({super.key, required this.rows});
  final List<Map<String, dynamic>> rows;

  @override
  State<RecordsTable> createState() => _RecordsTableState();
}

class _RecordsTableState extends State<RecordsTable> {
  final _hCtrl = ScrollController();
  final _vCtrl = ScrollController();
  static const double _cellHPad = 8.0;
  static const double _rowHeight = 44.0;

  late final List<_Col> columns;

  @override
  void initState() {
    super.initState();
    columns = [
      _Col('Ser', 'ser_no', width: 68, isNumeric: true),
      _Col('User', 'user', width: 180),
      _Col('Ref No', 'ref_no', width: 110),
      _Col('Vehicle #', 'vehicle_no', width: 120),
      _Col('Type', 'vehicle_type', width: 140),
      _Col('WD', 'working_days', width: 60, isNumeric: true),
      _Col('KM', 'km_run', width: 80, isNumeric: true),
      _Col('Rental', 'rental', width: 120, isMoney: true),
      _Col('OT', 'ot_amount', width: 110, isMoney: true),
      _Col('O/N', 'overnight_amount', width: 110, isMoney: true),
      _Col('Ex.KM', 'excess_km', width: 90, isNumeric: true),
      _Col('Ex.Amount', 'excess_amount', width: 120, isMoney: true),
      _Col('Absent', 'absent_deduct_amount', width: 120, isMoney: true),
      _Col('Total', 'total', width: 130, isMoney: true),
      _Col('VAT(18%)', 'tax_18_percent', width: 120, isMoney: true),
      _Col('Grand', 'grand_total', width: 130, isMoney: true),
      _Col('Supplier', 'supplier', width: 240),
      _Col('Fuel', 'fuel_type', width: 90),
      _Col('RateCat', 'rate_category', width: 150),
      _Col('Period', 'rate_period', width: 100),
    ];
  }

  double get tableWidth =>
      columns.fold<double>(0.0, (sum, c) => sum + c.width + 2 * _cellHPad);

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.blue.shade900,
              child: Row(
                children: [
                  const Icon(Icons.table_chart, color: Colors.white70),
                  const SizedBox(width: 8),
                  const Text('Records',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .2)),
                  const Spacer(),
                  Text('Rows: ${rows.length}',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                controller: _hCtrl,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _hCtrl,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: tableWidth),
                    child: SizedBox(
                      width: tableWidth,
                      child: Scrollbar(
                        controller: _vCtrl,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _vCtrl,
                          itemCount: rows.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return HeaderRow(columns: columns);
                            }
                            final row = rows[index - 1];
                            return DataRowWidget(
                              columns: columns,
                              row: row,
                              color: (index % 2 == 0) ? zebraA : zebraB,
                              cellHPad: _cellHPad,
                              height: _rowHeight,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderRow extends StatelessWidget {
  const HeaderRow({super.key, required this.columns});
  final List<_Col> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: const Color(0xFFE8EEF7),
      child: Row(
        children: columns.map((c) {
          return SizedBox(
            width: c.width + 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: _accentBlue)),
            ),
          );
        }).toList(),
      ),
    );
  }
}


class DataRowWidget extends StatelessWidget {
  const DataRowWidget({
    super.key,
    required this.columns,
    required this.row,
    required this.color,
    required this.cellHPad,
    required this.height,
  });

  final List<_Col> columns;
  final Map<String, dynamic> row;
  final Color color;
  final double cellHPad;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: color,
      child: Row(
        children: columns.map((c) {
          final v = row[c.key];
          String text;
          if (c.isMoney) {
            text = formatNum((v is num) ? v : num.tryParse('$v') ?? 0);
          } else if (c.isNumeric) {
            text = (v == null) ? '-' : '$v';
          } else {
            text = (v == null) ? '-' : '$v';
          }
          final align =
              c.isMoney || c.isNumeric ? TextAlign.right : TextAlign.left;
          return SizedBox(
            width: c.width + 2 * cellHPad,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: cellHPad),
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: align,
                  style: const TextStyle(fontSize: 13.5)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Col {
  final String title;
  final String key;
  final bool isNumeric;
  final bool isMoney;
  final double width;

  _Col(this.title, this.key,
      {this.isNumeric = false, this.isMoney = false, this.width = 120});
}

/// ---- SUMMARY PANEL ----
class SummaryPanel extends StatelessWidget {
  const SummaryPanel({super.key, required this.summary});
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final items = <_SumItem>[
      _SumItem('Rental Amount', summary['rentalAmount']),
      _SumItem('O.T', summary['otAmount']),
      _SumItem('Over Night', summary['overnightAmount']),
      _SumItem('Excess Amount', summary['excessAmount']),
      _SumItem('Total', summary['total'], strong: true),
      _SumItem('Absentisem Deduction', summary['absentDeduction']),
      _SumItem('Absent After Total', summary['absentAfterTotal'], strong: true),
      _SumItem(summary['advanceLabel'] ?? 'Advanced', summary['advanceAmount']),
      _SumItem('Total after Advance', summary['balanceAfterAdvance'],
          strong: true),
      _SumItem('18% Tax', summary['vatAmount']),
      _SumItem('Net Amount', summary['netAmount'], strong: true, big: true),
    ];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.blue.shade900,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: const [
                Icon(Icons.summarize, color: Colors.white70),
                SizedBox(width: 8),
                Text('Summary',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 8),
              itemBuilder: (context, i) {
                final it = items[i];
                return Row(
                  children: [
                    Expanded(
                      child: Text(it.label,
                          style: TextStyle(
                              fontWeight:
                                  it.strong ? FontWeight.w700 : FontWeight.w500,
                              color:
                                  it.strong ? _accentBlue : Colors.black87)),
                    ),
                    Text(
                      formatNum((it.value is num)
                          ? it.value
                          : num.tryParse('${it.value}') ?? 0),
                      style: TextStyle(
                        fontWeight: it.big ? FontWeight.w800 : FontWeight.w700,
                        fontSize: it.big ? 18 : 14,
                        color: it.big ? _darkBlue : Colors.black87,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SumItem {
  final String label;
  final dynamic value;
  final bool strong;
  final bool big;
  _SumItem(this.label, this.value, {this.strong = false, this.big = false});
}