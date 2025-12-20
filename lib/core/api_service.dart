// services/api_service.dart
import 'package:dio/dio.dart';
import '../models/ratecard.dart';

class ApiService {
  final Dio dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000/api',
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 15),
    contentType: 'application/json',
  ));

  Future<RateCardResponse> fetchRateCardsByDate(String date) async {
    try {
      final response = await dio.get('/ratecards/$date');
      if (response.statusCode == 200) {
        return RateCardResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to load rate cards');
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      if (e.response != null) print('↩️ ${e.response?.data}');
      throw Exception('Failed to fetch rate cards');
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }
}