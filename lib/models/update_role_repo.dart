
import 'package:dio/dio.dart';

Future<String> bulkUpdateRole({
  required String tableName,
  required String location,
  required String mode,
  required String currentRole,
  required String newRole,
}) async {
  final response = await Dio().post(
    'https://dpdlab1.slt.lk:9126/api/bulk-update-role',
    data: {
      'tableName': tableName,
      'location': location,
      'mode': mode,
      'role': currentRole,
      'newRole': newRole,
    },
  );
  return response.data['message'];
}