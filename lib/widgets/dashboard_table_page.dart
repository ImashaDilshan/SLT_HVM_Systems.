import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_event.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_state.dart';
import 'package:slt_hire_log/blocks/overlay/overlay_cubit.dart';
import 'package:slt_hire_log/extensions/role_extension.dart';
import 'package:slt_hire_log/models/dashboard_data_model.dart';
import 'package:slt_hire_log/widgets/dashboard_data_source.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class DashboardTablePage extends StatefulWidget {
  final String tableName;
  final String location;
  final String mode;
  final String role;

  const DashboardTablePage({
    super.key,
    required this.tableName,
    required this.location,
    required this.mode,
    required this.role,
  });

  @override
  State<DashboardTablePage> createState() => _DashboardTablePageState();
}

class _DashboardTablePageState extends State<DashboardTablePage> {
  late DashboardDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(
          FetchDashboardData(
            tableName: widget.tableName,
            location: widget.location,
            mode: widget.mode,
            role: widget.role.stepDown,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DashboardError) {
          if (state.message.contains("404") || state.message.contains("400")) {
            return const Center(child: Text("⚠️ No Records in System"));
          } else if (state.message.contains("500")) {
            return const Center(child: Text("❌ Server Error"));
          } else {
            return Center(
              child: Text(
                "⛔ Error: ${state.message}",
                textAlign: TextAlign.center,
              ),
            );
          }
        }

        if (state is DashboardLoaded) {
          final dataList = state.data
              .map((e) => DashboardData.fromJson(e))
              .toList();
          _dataSource = DashboardDataSource(dataList);

          return LayoutBuilder(
            builder: (context, constraints) {
              bool isscreenwidth = constraints.maxWidth < 1250;
              return SfDataGridTheme(
                data: SfDataGridThemeData(
                  // 🟦 Dark blue header
                  headerColor: Colors.blue.shade900,
                  rowHoverColor: const Color.fromARGB(26, 0, 56, 223),
                  rowHoverTextStyle: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                  selectionColor: Colors.blue.shade100,
                  gridLineColor: const Color.fromARGB(0, 158, 158, 158),
                ),
                child: SizedBox.expand(
                  child: SfDataGrid(
                    source: _dataSource,
                    columnWidthMode: isscreenwidth
                        ? ColumnWidthMode.fitByColumnName
                        : ColumnWidthMode.fill,
                    onCellTap: (DataGridCellTapDetails details) {
                      if (details.rowColumnIndex.rowIndex > 0) {
                        final rowIndex = details.rowColumnIndex.rowIndex - 1;
                        final tappedRow = _dataSource.effectiveRows[rowIndex].getCells();
                        final rowData = {
                          for (var cell in tappedRow) cell.columnName: cell.value,
                        };
                        context.read<OverlayCubit>().show(prefillData: rowData);
                      }
                    },
                    columns: [
                      GridColumn(
                        filterPopupMenuOptions: FilterPopupMenuOptions(),
                        columnName: 'SerNo',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Serial No',
                            style: TextStyle(color: Colors.white), // ⚪ White text
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'Vehicle_No',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Vehicle No',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'M_Year',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Manufacture year',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'Ref_No',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Ref No',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'Vehicle_Type',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Vehicle Type',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'Category',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Category',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'User_Name',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Sub User',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'Cost_Center',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Cost Center',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'From_Date',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'From',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'To_Date',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'To',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'Working_Days',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Working Days',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'OT',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'OT',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'Over_Night',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Over Night',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      GridColumn(
                        columnName: 'Actual_Km',
                        label: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'KM',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const Center(child: Text("Waiting for data..."));
      },
    );
  }
}