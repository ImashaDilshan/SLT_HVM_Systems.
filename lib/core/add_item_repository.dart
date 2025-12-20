

import 'package:dio/dio.dart';

class AddItemRepository {
  final Dio dio;

  AddItemRepository(this.dio);

  Future<Map<String, List<String>>> fetchVehicleData(int costCenter) async {
    final response = await dio.get('http://localhost:3000/api/vehicles/$costCenter');
    final data = response.data as List;

    final Set<String> refNos = {};
    final Set<String> gms = {};
    final Set<String> dgms = {};
    final Set<String> districts = {};

    for (var item in data) {
      refNos.add(item['ref_no'] ?? '');
      gms.add(item['gm'] ?? '');
      dgms.add(item['dgm'] ?? '');
      districts.add(item['District'] ?? '');
    }

    return {
      'refNos': refNos.where((e) => e.isNotEmpty).toList(),
      'gms': gms.where((e) => e.isNotEmpty).toList(),
      'dgms': dgms.where((e) => e.isNotEmpty).toList(),
      'districts': districts.where((e) => e.isNotEmpty).toList(),
    };
  }
}
