import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:ivy_path/models/auth_response.dart';

class ApiClient {
  final Dio _dio;
  static const String baseUrl = 'https://ivypath-server.vercel.app';

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 3),
        ))..interceptors.add(PrettyDioLogger(
            requestHeader: true,
            requestBody: true,
            responseBody: true,
            responseHeader: false,
            error: true,
            compact: true,
          ));

  Future<AuthResponse> login({
    required String activationCode,
    required String deviceName,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post(
        '/portal/login/',
        data: {
          'activation_code': activationCode,
          'name': deviceName,
          'unique_id': deviceId,
        },
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid activation code or device not authorized');
      }
      throw Exception('Failed to login: ${e.message}');
    }
  }
}