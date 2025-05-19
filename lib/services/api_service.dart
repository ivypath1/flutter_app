import 'package:dio/dio.dart';
import 'package:ivy_path/models/auth_model.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://ivypath-server.vercel.app',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<AuthResponse> login({
    required String activationCode,
    required String deviceName,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post('/portal/login/', data: {
        'activation_code': activationCode,
        'name': deviceName,
        'unique_id': deviceId,
      });

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception(e.response?.data['detail'] ?? 'Authentication failed');
      }
      throw Exception('Failed to login. Please check your internet connection.');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }
}