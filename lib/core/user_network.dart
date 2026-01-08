

import 'package:dio/dio.dart';

class UserNetwork {
  static final Dio _dio = Dio(
    BaseOptions(baseUrl: 'https://dpdlab1.slt.lk:9126/api'),
  );

  static Dio get instance => _dio;
}