import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ivy_path/models/auth_response.dart';
import 'package:ivy_path/services/api_client.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  final _storage = const FlutterSecureStorage();
  final _deviceInfo = DeviceInfoPlugin();

  @override
  Future<AuthResponse?> build() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return null;
    
    // Here you might want to validate the token or fetch user data
    // For now, we'll just return null if there's no token
    return null;
  }

  Future<void> login(String activationCode) async {
    state = const AsyncLoading();
    
    try {
      final deviceInfo = await _getDeviceInfo();
      final apiClient = ApiClient();
      
      final response = await apiClient.login(
        activationCode: activationCode,
        deviceName: deviceInfo.name,
        deviceId: deviceInfo.id,
      );
      
      await _storage.write(key: 'token', value: response.token);
      state = AsyncData(response);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    state = const AsyncData(null);
  }

  Future<DeviceInfo> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return DeviceInfo(
          name: androidInfo.model,
          id: androidInfo.id,
        );
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return DeviceInfo(
          name: iosInfo.name ?? iosInfo.model ?? 'iOS Device',
          id: iosInfo.identifierForVendor ?? '',
        );
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        return DeviceInfo(
          name: macInfo.computerName,
          id: macInfo.systemGUID ?? '',
        );
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return DeviceInfo(
          name: windowsInfo.computerName,
          id: windowsInfo.deviceId,
        );
      }
      throw UnsupportedError('Unsupported platform');
    } catch (e) {
      throw Exception('Failed to get device info: $e');
    }
  }
}

class DeviceInfo {
  final String name;
  final String id;

  DeviceInfo({required this.name, required this.id});
}