

import 'package:dio/dio.dart';

class UserNetwork {
  static final Dio _dio = Dio(
    BaseOptions(baseUrl: 'http://localhost:3000/api'),
  );

  static Dio get instance => _dio;
}