import 'package:flutter/material.dart';
import 'package:slt_hire_log/constants/app_colors.dart';
import 'package:slt_hire_log/models/calculation_config_service.dart';
import 'package:toastification/toastification.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _configService = CalculationConfigService();
  Map<String, dynamic>? _config;
  
  final _billingDaysController = TextEditingController();
  final _absentDayRateController = TextEditingController();
  final _absentCapPercentController = TextEditingController();
  final _absencePenaltyThresholdController = TextEditingController();
  final _absencePenaltyPercentController = TextEditingController();
  final _vatPercentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _configService.getConfig();
    if (mounted) {
      setState(() {
        _config = config;
        _billingDaysController.text = config['billingDays'].toString();
        _absentDayRateController.text = config['absentDayRate'].toString();
        _absentCapPercentController.text = config['absentCapPercent'].toString();
        _absencePenaltyThresholdController.text = config['absencePenaltyThreshold'].toString();
        _absencePenaltyPercentController.text = config['absencePenaltyPercent'].toString();
        _vatPercentController.text = config['vatPercent'].toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundColor, // ✅ White background
      appBar: _buildModernAppBar(),
      body: _config == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
            child: SizedBox(
              width:500,
              height: 700,child: 
               _buildBody()),
          ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: AppColors.scaffoldBackgroundColor, // ✅ White app bar
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87), // ✅ Black icon
        onPressed: () => Navigator.pop(context),
      ),
      title: const Row(
        children: [
          Icon(Icons.settings_outlined, color: Color(0xFF0057A8)), // ✅ Dark blue accent
          SizedBox(width: 12),
          Text(
            'Calculation Settings',
            style: TextStyle(
              color: Colors.black87, // ✅ Black text
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.black12, // ✅ Black line separator
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('General Configuration'),
            const SizedBox(height: 16),
            _buildCleanTextField(_billingDaysController, 'Billing Days', Icons.calendar_today),
            const SizedBox(height: 16),
            _buildCleanTextField(_absentDayRateController, 'Absent Day Rate (Rs)', Icons.money_off),
            const SizedBox(height: 16),
            _buildCleanTextField(_absentCapPercentController, 'Absent Cap %', Icons.percent),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Penalty Rules'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildCleanTextField(_absencePenaltyThresholdController, 'Penalty Threshold', Icons.timer)),
                const SizedBox(width: 12),
                Expanded(child: _buildCleanTextField(_absencePenaltyPercentController, 'Penalty %', Icons.warning)),
              ],
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Tax Configuration'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildCleanTextField(_vatPercentController, 'VAT %', Icons.receipt)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSwitchTile('Include VAT', _config!['includeVAT'], (v) {
                    setState(() => _config!['includeVAT'] = v);
                  }),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0057A8), Colors.blue]), // ✅ Dark blue gradient
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black87, // ✅ Black text
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCleanTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.black87), // ✅ Dark text
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black54), // ✅ Dark gray label
        prefixIcon: Icon(icon, color: Color(0xFF0057A8)), // ✅ Dark blue icon
        filled: true,
        fillColor: Colors.grey.shade50, // ✅ Light gray fill
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black12), // ✅ Black border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black12), // ✅ Black border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF0057A8), width: 2), // ✅ Dark blue focus
        ),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black12), // ✅ Black border
        color: Colors.grey.shade50, // ✅ Light background
      ),
      child: Row(
        children: [
          Icon(Icons.toggle_on, color: Color(0xFF0057A8)), // ✅ Dark blue icon
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.black87)), // ✅ Black text
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Color(0xFF0057A8), // ✅ Dark blue switch
            inactiveTrackColor: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Reset button
        TextButton.icon(
          onPressed: () async {
            await _configService.resetToDefaults();
            await _loadConfig();
          },
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0057A8)), // ✅ Dark blue icon
          label: const Text(
            'Reset to Defaults',
            style: TextStyle(color: Color(0xFF0057A8)), // ✅ Dark blue text
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF0057A8)), // ✅ Dark blue border
            ),
          ),
        ),
        
        // Save button
        ElevatedButton.icon(
          icon: const Icon(Icons.save_rounded, color: Colors.white),
          label: const Text('Save Settings', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0057A8), // ✅ Dark blue button
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
          onPressed: _saveSettings,
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
 Future<void> saveSettings() async {
  if (!_formKey.currentState!.validate()) return;
  
  final config = _config!;
  config['billingDays'] = int.parse(_billingDaysController.text);
  config['absentDayRate'] = int.parse(_absentDayRateController.text);
  config['absentCapPercent'] = int.parse(_absentCapPercentController.text);
  config['absencePenaltyThreshold'] = int.parse(_absencePenaltyThresholdController.text);
  config['absencePenaltyPercent'] = int.parse(_absencePenaltyPercentController.text);
  config['vatPercent'] = int.parse(_vatPercentController.text);

  await _configService.saveConfig(config);
  
  if (mounted) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      title: const Text('Settings saved!'),
      description: const Text('Will be used in next calculation.'),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topRight,
    );
    Navigator.pop(context);
  }
}
  }
  @override
  void dispose() {
    _billingDaysController.dispose();
    _absentDayRateController.dispose();
    _absentCapPercentController.dispose();
    _absencePenaltyThresholdController.dispose();
    _absencePenaltyPercentController.dispose();
    _vatPercentController.dispose();
    super.dispose();
  }
}