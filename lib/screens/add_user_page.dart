import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart'; // Fixed import
import 'package:slt_hire_log/constants/app_colors.dart';

// THEME COLORS
const Color primaryDarkBlue = Color(0xFF1E3A8A);
const Color cardBg = Colors.white;
const Color cardBorder = Color(0xFFE2E8F0);
const Color textMain = Color(0xFF0F172A);
const Color textSub = Color(0xFF64748B);
const Color dividerColor = Color(0xFFE5E7EB);
const Color highlightBg = Color(0xFFEFF6FF);
const Color successGreen = Color(0xFF10B981);
const Color errorRed = Color(0xFFEF4444);

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  // FORM CONTROLLERS
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _positionCtrl = TextEditingController();

  // All possible roles
  final List<String> _allRoles = ['Moderator', 'level01', 'level02', 'admin'];

  // Cost centers
  List<Map<String, dynamic>> _allCostCenters = [];
  final List<Map<String, dynamic>> _selectedCostCenters = [];

  // UI state
  bool _loading = false;
  bool _submitting = false;
  String? _errorMsg;
  String? _successMsg;
  String? _selectedRole;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  @override
  void initState() {
    super.initState();
    _fetchCostCenters();
  }

  // -------------------------------------------------
  // ROLE LOGIC - Filter roles based on current user
  // -------------------------------------------------
  List<String> get _availableRoles {
    final currentUserRole = context.watch<SharedDataCubit>().state.role ?? 'user';
    
    switch (currentUserRole) {
      case 'admin':
        return _allRoles; // All 4 roles
      case 'level02':
        return ['Moderator', 'level01'];
      case 'level01':
        return ['Moderator'];
      default:
        return []; // No role assignment permission
    }
  }

  // Get logged-in user's role
  String get _loggedInUserRole => context.read<SharedDataCubit>().state.role ?? 'user';

  // -------------------------------------------------
  // FETCH COST CENTERS
  // -------------------------------------------------
  Future<void> _fetchCostCenters() async {
    setState(() => _loading = true);
    try {
      final res = await _dio.get('http://localhost:3000/api/admin/cost-centers');
      final data = res.data;
      if (data['success'] == true) {
        setState(() {
          _allCostCenters = List<Map<String, dynamic>>.from(data['costCenters']);
        });
      }
    } catch (e) {
      setState(() => _errorMsg = 'Failed to load cost centers');
    } finally {
      setState(() => _loading = false);
    }
  }

  // -------------------------------------------------
  // COST CENTER SELECTION LOGIC
  // -------------------------------------------------
  bool _roleAllowsMultiSelect() {
    return !['Moderator', 'level01'].contains(_selectedRole);
  }

  void _toggleCostCenter(Map<String, dynamic> cc) {
    setState(() {
      final String id = cc['cost_center_id'].toString();
      
      final exists = _selectedCostCenters.any((c) => 
        c['cost_center_id'].toString() == id
      );

      if (exists) {
        _selectedCostCenters.removeWhere((c) => 
          c['cost_center_id'].toString() == id
        );
      } else {
        if (!_roleAllowsMultiSelect()) {
          _selectedCostCenters.clear();
        }
        _selectedCostCenters.add(cc);
      }
    });
  }

  // Build cost centers payload based on logged-in user's role
  List<Map<String, dynamic>> _buildCostCentersPayload() {
    if (_loggedInUserRole == 'level01') {
      // For level01 users: auto-assign their own cost center
      final locationId = context.read<SharedDataCubit>().state.location;
      if (locationId == null) {
        throw Exception("Your account must have a cost center assigned. Please contact admin.");
      }
      
      // Find the full cost center details from the fetched list
      final cc = _allCostCenters.firstWhere(
        (c) => c['cost_center_id'].toString() == locationId.toString(),
        orElse: () => {
          'cost_center_id': locationId,
          'region': 'N/A',
          'cost_center_name': 'N/A',
        },
      );
      return [cc];
    } else {
      // For other users: use the manually selected cost centers
      return _selectedCostCenters.map((cc) => {
        "cost_center_id": cc["cost_center_id"].toString(),
        "region": cc["region"] ?? '',
        "cost_center_name": cc["cost_center_name"] ?? '',
      }).toList();
    }
  }

  // -------------------------------------------------
  // SUBMIT
  // -------------------------------------------------
  Future<void> _submit() async {
    // Clear previous messages
    setState(() {
      _errorMsg = null;
      _successMsg = null;
    });

    // CORE VALIDATION
    if (_emailCtrl.text.trim().isEmpty || 
        _nameCtrl.text.trim().isEmpty || 
        _selectedRole == null) {
      setState(() => _errorMsg = 'Please complete all required fields');
      return;
    }

    // Email format validation
    if (!_emailCtrl.text.contains('@')) {
      setState(() => _errorMsg = 'Please enter a valid email');
      return;
    }

    // CONDITIONAL VALIDATION: Only validate fields that are visible
    if (_loggedInUserRole != 'level01') {
      // Position is only visible to non-level01 users
      if (_positionCtrl.text.trim().isEmpty) {
        setState(() => _errorMsg = 'Please complete the position field');
        return;
      }

      // Cost center selection is only visible to non-level01 users
      if (_selectedCostCenters.isEmpty) {
        setState(() => _errorMsg = 'Please select at least one cost center');
        return;
      }
      
      if (!_roleAllowsMultiSelect() && _selectedCostCenters.length != 1) {
        setState(() => _errorMsg = 'This role requires exactly one cost center');
        return;
      }
    }

    setState(() => _submitting = true);
    
    try {
      final tempPassword = _generateRandomPassword();
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: tempPassword,
      );

      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailCtrl.text.trim());
      
      final body = {
        "uid": credential.user!.uid,
        "name": _nameCtrl.text.trim(),
        "role": _selectedRole!,
        "position": _loggedInUserRole == 'level01' ? 'N/A' : _positionCtrl.text.trim(),
        "costCenters": _buildCostCentersPayload(),
      };

      await _dio.post(
        'http://localhost:3000/api/admin/user-with-costcenters',
        data: jsonEncode(body),
      );

      setState(() {
        _successMsg = 'User created successfully. Password reset email sent.';
      });
      
      _clearForm();
    } catch (e) {
      setState(() => _errorMsg = 'Error: ${e.toString()}');
    } finally {
      setState(() => _submitting = false);
      if (mounted) {
        FirebaseAuth.instance.signOut();
      }
    }
  }

  void _clearForm() {
    _emailCtrl.clear();
    _nameCtrl.clear();
    _positionCtrl.clear();
    setState(() {
      _selectedRole = null;
      _selectedCostCenters.clear();
    });
  }

  String _generateRandomPassword({int length = 12}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@#*!?';
    return List.generate(length, (_) => chars[Random.secure().nextInt(chars.length)]).join();
  }

  // -------------------------------------------------
  // COST CENTER PICKER (Modal)
  // -------------------------------------------------
  void _showCostCenterPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CostCenterPicker(
        costCenters: _allCostCenters,
        selectedIds: _selectedCostCenters.map((c) => c['cost_center_id'].toString()).toSet(),
        onToggle: _toggleCostCenter,
        multiSelect: _roleAllowsMultiSelect(),
      ),
    );
  }

  // -------------------------------------------------
  // UI BUILD
  // -------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Text(
                      'Add New User',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create user account and assign cost centers',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // MAIN FORM CARD
                    _buildCard(
                      title: 'Primary Information',
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _emailCtrl,
                            label: 'Email Address',
                            hint: 'user@example.com',
                            icon: Icons.email,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nameCtrl,
                            label: 'Full Name',
                            hint: 'Imasha Munasinghe',
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(),
                          const SizedBox(height: 16),
                          
                          // Position field is hidden for level01 users
                          _loggedInUserRole == 'level01'
                              ? Container()
                              : _buildTextField(
                                  controller: _positionCtrl,
                                  label: 'Position',
                                  hint: 'DGM-Provincial Operations',
                                  icon: Icons.work,
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cost Center Assignment card is hidden for level01 users
                    _loggedInUserRole == 'level01'
                        ? Container()
                        : _buildCard(
                            title: 'Cost Center Assignment',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _roleAllowsMultiSelect()
                                      ? 'Select multiple cost centers'
                                      : 'Select one cost center',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSub,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // SELECTED CHIPS
                                if (_selectedCostCenters.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _selectedCostCenters.map((cc) {
                                      return Chip(
                                        label: Text(cc['cost_center_name'].toString()),
                                        backgroundColor: highlightBg,
                                        side: BorderSide(color: primaryDarkBlue),
                                        deleteIcon: const Icon(Icons.close, size: 18),
                                        onDeleted: () => _toggleCostCenter(cc),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                
                                // PICKER BUTTON
                                ElevatedButton.icon(
                                  onPressed: _selectedRole == null
                                      ? null
                                      : _showCostCenterPicker,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Choose Cost Centers'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryDarkBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    
                    const SizedBox(height: 24),

                    // STATUS MESSAGES
                    if (_errorMsg != null)
                      _buildStatusMessage(_errorMsg!, isError: true),
                    if (_successMsg != null)
                      _buildStatusMessage(_successMsg!, isError: false),

const SizedBox(height: 20),

                    
                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Create User',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // UI HELPER METHODS
  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textMain,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: textSub) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryDarkBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown() {
    final availableRoles = _availableRoles;
    
    // Reset selection if current role is not in available list
    if (_selectedRole != null && !availableRoles.contains(_selectedRole)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedRole = null;
        });
      });
    }

    return DropdownButtonFormField<String>(
      initialValue: availableRoles.contains(_selectedRole) ? _selectedRole : null,
      decoration: InputDecoration(
        labelText: 'Role (Your permissions: $_loggedInUserRole)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryDarkBlue, width: 2),
        ),
        filled: true,
      ),
      items: availableRoles.map((role) => DropdownMenuItem(
        value: role,
        child: Text(role),
      )).toList(),
      onChanged: availableRoles.isEmpty ? null : (value) {
        setState(() {
          _selectedRole = value;
          if (!_roleAllowsMultiSelect() && _selectedCostCenters.length > 1) {
            _selectedCostCenters.removeRange(1, _selectedCostCenters.length);
          }
        });
      },
    );
  }

  Widget _buildStatusMessage(String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isError ? errorRed : successGreen).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isError ? errorRed : successGreen),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_rounded : Icons.check_circle_rounded,
            color: isError ? errorRed : successGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? errorRed : successGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CostCenterPicker widget remains unchanged
class CostCenterPicker extends StatefulWidget {
  final List<Map<String, dynamic>> costCenters;
  final Set<String> selectedIds;
  final Function(Map<String, dynamic>) onToggle;
  final bool multiSelect;

  const CostCenterPicker({
    super.key,
    required this.costCenters,
    required this.selectedIds,
    required this.onToggle,
    required this.multiSelect,
  });

  @override
  State<CostCenterPicker> createState() => _CostCenterPickerState();
}

class _CostCenterPickerState extends State<CostCenterPicker> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.costCenters;
    _searchCtrl.addListener(_filter);
  }

  void _filter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.costCenters.where((cc) {
        return cc['cost_center_name'].toString().toLowerCase().contains(query) ||
               cc['region'].toString().toLowerCase().contains(query) ||
               cc['dgm_title'].toString().toLowerCase().contains(query) ||
               cc['cost_center_id'].toString().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search cost centers...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done', style: TextStyle(color: primaryDarkBlue)),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No results found',
                      style: TextStyle(color: textSub),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final cc = _filtered[index];
                      final String id = cc['cost_center_id'].toString();
                      final isSelected = widget.selectedIds.contains(id);
                      
                      return ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          activeColor: primaryDarkBlue,
                          onChanged: (_) => widget.onToggle(cc),
                        ),
                        title: Text(
                          cc['cost_center_name'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${cc['region']} • ${cc['dgm_title']} • #${cc['cost_center_id']}',
                          style: TextStyle(fontSize: 12, color: textSub),
                        ),
                        onTap: () => widget.onToggle(cc),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}