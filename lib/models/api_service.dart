import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  
  static Future<Map<String, dynamic>> calculateBulkRates(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/calculate-rates/table'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed: ${response.body}');
    }
  }
}