

import 'package:dio/dio.dart';

class AddItemSubmitRepository {
  final Dio dio;

  AddItemSubmitRepository(this.dio);

  Future<String> submitAddItem(Map<String, dynamic> formData) async {
    final tableName = formData['tableName'];
    final supplier = formData['supplier'];

    // Remove tableName and supplier from individual row to avoid duplication
    final cleanData =
        Map<String, dynamic>.from(formData)
          ..remove('tableName')
          ..remove('supplier');

    final payload = {
      'tableName': tableName,
      'supplier': supplier,
      'data': [cleanData], // Backend expects a list of rows
    };
    final response = await dio.post(
      'http://localhost:3000/api/add_item',
      data: payload,
    );

    if (response.statusCode == 200) {
      print(payload);
      return response.data['message'] ?? 'Successfully submitted';
    } else {
      throw Exception('Failed to submit data');
    }
  }
  Future<String> updateItem(Map<String, dynamic> data) async {
    final response = await dio.put(
      'http://localhost:3000/api/update-data',
      data: data,
    );

    if (response.data['success']) {
      return response.data['message'] ?? "Successfully updated.";
    } else {
      throw response.data['message'] ?? "Unknown error while updating.";
    }
  }
}
