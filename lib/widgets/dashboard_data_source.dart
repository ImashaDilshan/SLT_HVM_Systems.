import 'package:flutter/material.dart';
import 'package:slt_hire_log/models/dashboard_data_model.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:intl/intl.dart';

class DashboardDataSource extends DataGridSource {
  final List<DashboardData> _rawData;

  DashboardDataSource(List<DashboardData> data) : _rawData = data;

  @override
  List<DataGridRow> get rows => _rawData.map((e) {
        return DataGridRow(
          cells: [
            DataGridCell<int>(columnName: 'SerNo', value: e.serNo),
            DataGridCell<String>(columnName: 'Vehicle_No', value: e.vehicleNo),
            DataGridCell<String>(columnName: 'M_Year', value: e.manufactureYear),
            DataGridCell<String>(columnName: 'Ref_No', value: e.refNo),
            DataGridCell<String>(columnName: 'Vehicle_Type', value: e.vehicleType),
            DataGridCell<String>(columnName: 'Category', value: e.category),
            DataGridCell<String>(columnName: 'User_Name', value: e.user),
            DataGridCell<String>(columnName: 'Cost_Center', value: e.costCenter),
            DataGridCell<String>(
                columnName: 'From_Date',
                value: DateFormat('yyyy-MM-dd').format(e.fromDate)),
            DataGridCell<String>(
                columnName: 'To_Date',
                value: DateFormat('yyyy-MM-dd').format(e.toDate)),
            DataGridCell<int>(columnName: 'Working_Days', value: e.workingDays),
            DataGridCell<double>(columnName: 'OT', value: e.otHrs),
            DataGridCell<int>(columnName: 'Over_Night', value: e.overnight),
            DataGridCell<double>(columnName: 'Actual_Km', value: e.kmRun),
          ],
        );
      }).toList();

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    // ✅ FIXED: Safe row index lookup
    final rowIndex = rows.indexOf(row);
    
    // ✅ FIXED: Add safety check
    if (rowIndex < 0 || rowIndex >= _rawData.length) {
      return DataGridRowAdapter(
        cells: row.getCells().map((cell) {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8.0),
            child: Text(cell.value?.toString() ?? ''),
          );
        }).toList(),
      );
    }

    final item = _rawData[rowIndex];
    
    // Alternating row color
    final baseColor = rowIndex % 2 == 1 
        ? Colors.green.shade50.withOpacity(0.4)
        : Colors.white;
    
    // Red overlay for removed items
    final rowColor = item.acceptRole == "Remove" 
        ? Colors.red.shade100 
        : baseColor;

    return DataGridRowAdapter(
      color: rowColor,
      cells: row.getCells().map((cell) {
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          child: Text(
            cell.value?.toString() ?? '',
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
    );
  }
}