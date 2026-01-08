


import 'package:dio/dio.dart';

class DashboardNetwork {
  static final Dio _dio = Dio(
    BaseOptions(baseUrl: 'https://dpdlab1.slt.lk:9126/api/get-data'),
  );

  static Dio get instance => _dio;
}