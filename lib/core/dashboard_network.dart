


import 'package:dio/dio.dart';

class DashboardNetwork {
  static final Dio _dio = Dio(
    BaseOptions(baseUrl: 'http://localhost:3000/api/get-data'),
  );

  static Dio get instance => _dio;
}