import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_bloc.dart';
import 'package:slt_hire_log/blocks/Dashboard/dashboard_event.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';
import 'package:slt_hire_log/blocks/add_item_load/add_item_load_bloc.dart';
import 'package:slt_hire_log/blocks/add_item_load/add_item_load_state.dart';
import 'package:slt_hire_log/blocks/add_item_submit/add_item_submit_bloc.dart';
import 'package:slt_hire_log/blocks/add_item_submit/add_item_submit_event.dart';
import 'package:slt_hire_log/blocks/overlay/overlay_cubit.dart';
import 'package:slt_hire_log/constants/app_colors.dart';
import 'package:slt_hire_log/constants/app_styles.dart';
import 'package:slt_hire_log/extensions/role_extension.dart';
import 'package:slt_hire_log/widgets/custom_widget/dropdown_widget.dart';
import 'package:intl/intl.dart';
import 'package:slt_hire_log/widgets/custom_widget/textarea_widget.dart';

class AddItem extends StatefulWidget {
  const AddItem({super.key});

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  bool _didPrefill = false;
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? prefillData;
  bool get isEditing => prefillData != null && prefillData!['ref_no'] != null;

  // Controllers
  String? selectedRefNo;
  String? selectedSupplier;
  String? selectedBranding = 'Yes';
  String? selectedTracking = 'Yes';

  final TextEditingController subUserController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController absentDaysController = TextEditingController();
  final TextEditingController otHoursController = TextEditingController();
  final TextEditingController overnightController = TextEditingController();
  final TextEditingController kmRunController = TextEditingController();
  final TextEditingController brandingOthercon = TextEditingController();
  final TextEditingController trackingOthercon = TextEditingController();
  final TextEditingController workingDaysController = TextEditingController();

  // Updated supplier list
  final List<String> suppliers = [
    'COMTEC SYSTEMS [PVT] LTD',
    'PRIME TOURS AND ARRIVALS (PVT) LTD',
    'SHAKYA CEYLON TRAVELS AND TOURS [PVT]LTD'
  ];

  Future<void> _selectDate(TextEditingController controller, {bool isFromDate = false}) async {
    DateTime initialDate = DateTime.now();
    if (controller.text.isNotEmpty) {
      final parsed = DateTime.tryParse(controller.text);
      if (parsed != null) initialDate = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isFromDate ? 'SELECT START DATE' : 'SELECT END DATE',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: const Color.fromARGB(255, 0, 46, 127),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        // Auto-calculate when both dates are set
        if (fromDateController.text.isNotEmpty && toDateController.text.isNotEmpty) {
          _autoCalculateWorkingDays();
        }
      });
    }
  }

  void _autoCalculateWorkingDays() {
    try {
      final fromDate = DateTime.parse(fromDateController.text);
      final toDate = DateTime.parse(toDateController.text);
      final totalDays = toDate.difference(fromDate).inDays + 1;
      
      setState(() {
        workingDaysController.text = totalDays.toString();
        absentDaysController.text = '0';
      });
    } catch (e) {
      debugPrint('Date parsing error: $e');
    }
  }

  String? _validateForm() {
    // Required field validation
    if (subUserController.text.trim().isEmpty ||
        selectedRefNo == null || selectedRefNo!.isEmpty ||
        fromDateController.text.trim().isEmpty ||
        toDateController.text.trim().isEmpty ||
        kmRunController.text.trim().isEmpty ||
        otHoursController.text.trim().isEmpty ||
        overnightController.text.trim().isEmpty ||
        absentDaysController.text.trim().isEmpty ||
        selectedSupplier == null || selectedSupplier!.isEmpty ||
        selectedBranding == null || selectedBranding!.isEmpty ||
        (selectedBranding == 'Other' && brandingOthercon.text.trim().isEmpty) ||
        selectedTracking == null || selectedTracking!.isEmpty ||
        (selectedTracking == 'Other' && trackingOthercon.text.trim().isEmpty) ||
        workingDaysController.text.trim().isEmpty) {
      return '⚠️ All fields are required. Please fill in all fields.';
    }

    // Date validation
    final fromDate = DateTime.tryParse(fromDateController.text);
    final toDate = DateTime.tryParse(toDateController.text);
    if (fromDate == null || toDate == null) {
      return '⚠️ Invalid date format.';
    }
    if (!toDate.isAfter(fromDate)) {
      return '⚠️ To date must be after From date.';
    }

    // Working + Absent days validation
    final workingDays = int.tryParse(workingDaysController.text) ?? 0;
    final absentDays = int.tryParse(absentDaysController.text) ?? 0;
    
    if (workingDays + absentDays != 30) {
      return '⚠️ Working Days ($workingDays) + Absent Days ($absentDays) must equal 30 days.';
    }

    // Non-negative validation
    if (workingDays < 0 || absentDays < 0 ||
        (int.tryParse(kmRunController.text) ?? 0) < 0 ||
        (int.tryParse(otHoursController.text) ?? 0) < 0 ||
        (int.tryParse(overnightController.text) ?? 0) < 0) {
      return '⚠️ Numeric fields cannot be negative.';
    }

    return null; // Validation passed
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
  }) {
    return styledTextField(
      controller: controller,
      label: label,
      type: TextInputType.number,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double dialogWidth = screenWidth < 600 ? screenWidth * 0.9 : 500;
    prefillData = context.watch<OverlayCubit>().state;

    if (!_didPrefill && prefillData != null && prefillData!.isNotEmpty) {
      _didPrefill = true;
      subUserController.text = prefillData!['user'] ?? '';
      selectedRefNo = prefillData!['ref_no'];
      fromDateController.text = prefillData!['from_date'] ?? '';
      toDateController.text = prefillData!['to_date'] ?? '';
      kmRunController.text = prefillData!['actchual_Km']?.toString() ?? '';
      otHoursController.text = prefillData!['ot']?.toString() ?? '';
      overnightController.text = prefillData!['Over_night']?.toString() ?? '';
      absentDaysController.text = prefillData!['working_days']?.toString() ?? '';
      selectedSupplier = prefillData!['supplier'];
      selectedBranding = prefillData!['branding'] ?? 'Yes';
      brandingOthercon.text = prefillData!['brandingOther'] ?? '';
      selectedTracking = prefillData!['tracking'] ?? 'Yes';
      trackingOthercon.text = prefillData!['trackingOther'] ?? '';
    }

    return BlocBuilder<AddItemLoadBloc, AddItemLoadState>(
      builder: (context, state) {
        if (state is AddItemLoaded) {
          return Center(
            child: SingleChildScrollView(
              child: Container(
                width: dialogWidth,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? "Edit Entry" : "Add New Entry",
                        style: AppStyles.heading.copyWith(
                          color: const Color.fromARGB(255, 0, 1, 88),
                        ),
                      ),
                      const SizedBox(height: 20),

                      styledTextField(
                        controller: subUserController,
                        label: 'Sub User',
                      ),
                      const SizedBox(height: 15),
                      
                      styledDropdown(
                        label: 'Ref No',
                        value: selectedRefNo,
                        items: state.refNos,
                        onChanged: (val) => setState(() => selectedRefNo = val),
                      ),
                      const SizedBox(height: 15),
                      
                      Row(
                        children: [
                          Expanded(
                            child: styledTextField(
                              controller: fromDateController,
                              label: 'From Date',
                              readOnly: true,
                              onTap: () => _selectDate(fromDateController, isFromDate: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: styledTextField(
                              controller: toDateController,
                              label: 'To Date',
                              readOnly: true,
                              onTap: () => _selectDate(toDateController, isFromDate: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      Row(
                        children: [
                          Expanded(child: _buildNumberField(controller: kmRunController, label: 'KM Run')),
                          const SizedBox(width: 5),
                          Expanded(child: _buildNumberField(controller: otHoursController, label: 'OT Hours')),
                          const SizedBox(width: 5),
                          Expanded(child: _buildNumberField(controller: overnightController, label: 'Overnight')),
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      Row(
                        children: [
                          Expanded(child: _buildNumberField(controller: workingDaysController, label: 'Working Days')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildNumberField(controller: absentDaysController, label: 'Absent Days')),
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      styledDropdown(
                        label: 'Supplier',
                        value: selectedSupplier,
                        items: suppliers,
                        onChanged: (value) => setState(() => selectedSupplier = value),
                      ),
                      const SizedBox(height: 15),
                      
                      styledDropdown(
                        label: 'Branding',
                        value: selectedBranding,
                        items: ['Yes', 'No', 'Other'],
                        onChanged: (value) => setState(() => selectedBranding = value),
                      ),
                      if (selectedBranding == 'Other')
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: styledTextField(
                            controller: brandingOthercon,
                            label: 'Specify Branding',
                          ),
                        ),
                      const SizedBox(height: 15),
                      
                      styledDropdown(
                        label: 'Tracking',
                        value: selectedTracking,
                        items: ['Yes', 'No', 'Other'],
                        onChanged: (value) => setState(() => selectedTracking = value),
                      ),
                      if (selectedTracking == 'Other')
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: styledTextField(
                            controller: trackingOthercon,
                            label: 'Specify Tracking',
                          ),
                        ),
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () => context.read<OverlayCubit>().hide(),
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 0, 46, 127),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                            ),
                            onPressed: () {
                              final validationError = _validateForm();
                              
                              if (validationError != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(validationError, style: const TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                                return;
                              }

                              final sharedDataCubit = context.read<SharedDataCubit>();
                              final sharedData = context.read<SharedDataCubit>().state;

                              final formData = {
                                'mode': isEditing ? 'update' : 'create',
                                'tableName': sharedDataCubit.tableName,
                                'type': sharedData.mode,
                                'subUser': subUserController.text.trim(),
                                'refNo': selectedRefNo,
                                'fromDate': fromDateController.text,
                                'toDate': toDateController.text,
                                'kmRun': kmRunController.text,
                                'otHours': otHoursController.text,
                                'overnight': overnightController.text,
                                'absentDays': absentDaysController.text,
                                'supplier': selectedSupplier,
                                'branding': selectedBranding,
                                'brandingOther': brandingOthercon.text.trim(),
                                'tracking': selectedTracking,
                                'trackingOther': trackingOthercon.text.trim(),
                                'role': 'Moderetor',
                                'rateCategory': sharedData.mode == "None Self Vehicles" 
                                    ? "WITHOUT_DRIVER_FUEL" 
                                    : "WITH_DRIVER_FUEL",
                                'working_days': workingDaysController.text,
                                'ratePeriod': 'Monthly',
                                'created_date': DateTime.now().toIso8601String(),
                              };

                              context.read<AddItemSubmitBloc>().add(SubmitAddItem(formData));
                              
                              final stepDown = sharedData.role!.stepDown;
                              context.read<OverlayCubit>().hide();

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                
                                context.read<DashboardBloc>().add(ResetDashboard());
                                context.read<DashboardBloc>().add(
                                  FetchDashboardData(
                                    tableName: sharedDataCubit.tableName,
                                    location: sharedData.location!,
                                    mode: sharedData.mode!,
                                    role: stepDown,
                                  ),
                                );
                              });
                            },
                            child: Text(isEditing ? "Update" : "Add Entry", 
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  void dispose() {
    subUserController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    absentDaysController.dispose();
    otHoursController.dispose();
    overnightController.dispose();
    kmRunController.dispose();
    brandingOthercon.dispose();
    trackingOthercon.dispose();
    workingDaysController.dispose();
    super.dispose();
  }
}