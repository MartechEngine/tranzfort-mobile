import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  // For Android emulator, use 10.0.2.2. For Windows, localhost works.
  // In production, this would be your actual API URL.
  static const String baseUrl = 'http://localhost:3000';

  ApiClient() : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Handle global errors like 401 Unauthorized
          if (e.response?.statusCode == 401) {
            // TODO: Handle logout or refresh token logic
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

final apiClient = ApiClient();
