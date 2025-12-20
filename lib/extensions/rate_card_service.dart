import 'package:dio/dio.dart';
import 'package:slt_hire_log/models/rate_card_models.dart';

class RateCardService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000/api',
    connectTimeout: Duration(milliseconds: 30000),
    receiveTimeout: Duration(milliseconds: 30000),
  ));

  Future<List<CalculatedRateCard>> getCalculatedRateCards() async {
    try {
      final response = await _dio.get('/calculated-cards');
      return (response.data['data'] as List)
          .map((card) => CalculatedRateCard.fromJson(card))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch rate cards: ${e.message}');
    }
  }

  Future<List<RateCardSlab>> getRateSlabsByYomCategory(
      int calculatedCardId, String yomCategory) async {
    try {
      final response =
          await _dio.get('/calculated-cards/$calculatedCardId/yom/$yomCategory');
      List<RateCardSlab> slabs = (response.data['data'] as List)
          .map((slab) => RateCardSlab.fromJson(slab))
          .toList();
      return slabs.where((slab) => slab.hasValidData).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch slabs: ${e.message}');
    }
  }

  Future<Map<String, Map<String, Map<String, Map<String, List<RateCardSlab>>>>>>
      getOrganizedSlabs(int calculatedCardId, String yomCategory) async {
    try {
      final slabs = await getRateSlabsByYomCategory(calculatedCardId, yomCategory);
      Map<String, Map<String, Map<String, Map<String, List<RateCardSlab>>>>>
          organizedData = {};
      for (var slab in slabs) {
        organizedData
            .putIfAbsent(slab.serviceType, () => {})
            .putIfAbsent(slab.categoryCode, () => {})
            .putIfAbsent(slab.fuelType ?? 'GENERAL', () => {})
            .putIfAbsent(slab.rateType, () => [])
            .add(slab);
      }
      return organizedData;
    } catch (e) {
      throw Exception('Failed to organize slabs: $e');
    }
  }

  Future<List<String>> getCategories(
      int calculatedCardId, String yomCategory) async {
    try {
      final response = await _dio
          .get('/calculated-cards/$calculatedCardId/yom/$yomCategory/categories');
      return (response.data['data'] as List).cast<String>();
    } on DioException catch (e) {
      throw Exception('Failed to fetch categories: ${e.message}');
    }
  }
Future<List<dynamic>> calculateViaApi(List<Map<String, dynamic>> body) async {
  try {
    final response = await _dio.post('/calculate-rates', data: body);
    return response.data as List<dynamic>;
  } on DioException catch (e) {
    throw Exception('Failed to calculate via API: ${e.message}');
  }
}

  Future<List<String>> getServiceTypes(
      int calculatedCardId, String yomCategory) async {
    try {
      final response = await _dio.get(
          '/calculated-cards/$calculatedCardId/yom/$yomCategory/service-types');
      return (response.data['data'] as List).cast<String>();
    } on DioException catch (e) {
      throw Exception('Failed to fetch service types: ${e.message}');
    }
  }

  Future<List<String>> getFuelTypes(int calculatedCardId, String yomCategory,
      String categoryCode, String serviceType) async {
    try {
      final response = await _dio.get(
          '/calculated-cards/$calculatedCardId/yom/$yomCategory/category/$categoryCode/service/$serviceType/fuel-types');
      return (response.data['data'] as List).cast<String>();
    } on DioException catch (e) {
      throw Exception('Failed to fetch fuel types: ${e.message}');
    }
  }




  
}
