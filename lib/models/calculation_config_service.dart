import 'package:shared_preferences/shared_preferences.dart';

class CalculationConfigService {
  static const String _prefix = 'calc_config_';
  
  static const Map<String, dynamic> _defaults = {
    'billingDays': 30,
    'absentDayRate': 2000,
    'absentCapPercent': 10,
    'absencePenaltyThreshold': 5,
    'absencePenaltyPercent': 0,
    'includeVAT': true,
    'vatPercent': 18,
    'rateType': 'Monthly',
  };

  Future<Map<String, dynamic>> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'billingDays': prefs.getInt('${_prefix}billingDays') ?? _defaults['billingDays'],
      'absentDayRate': prefs.getInt('${_prefix}absentDayRate') ?? _defaults['absentDayRate'],
      'absentCapPercent': prefs.getInt('${_prefix}absentCapPercent') ?? _defaults['absentCapPercent'],
      'absencePenaltyThreshold': prefs.getInt('${_prefix}absencePenaltyThreshold') ?? _defaults['absencePenaltyThreshold'],
      'absencePenaltyPercent': prefs.getInt('${_prefix}absencePenaltyPercent') ?? _defaults['absencePenaltyPercent'],
      'includeVAT': prefs.getBool('${_prefix}includeVAT') ?? _defaults['includeVAT'],
      'vatPercent': prefs.getInt('${_prefix}vatPercent') ?? _defaults['vatPercent'],
      'rateType': prefs.getString('${_prefix}rateType') ?? _defaults['rateType'],
    };
  }

  Future<void> saveConfig(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    for (var entry in config.entries) {
      if (entry.value is int) {
        await prefs.setInt('$_prefix${entry.key}', entry.value);
      } else if (entry.value is bool) {
        await prefs.setBool('$_prefix${entry.key}', entry.value);
      } else if (entry.value is String) {
        await prefs.setString('$_prefix${entry.key}', entry.value);
      }
    }
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (String key in keys) {
      await prefs.remove(key);
    }
  }
}