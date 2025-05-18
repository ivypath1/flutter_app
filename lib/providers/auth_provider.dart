import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _deviceInfo = DeviceInfoPlugin();
  bool _isAuthenticated = false;
  String? _deviceId;

  bool get isAuthenticated => _isAuthenticated;
  String? get deviceId => _deviceId;

  Future<void> initialize() async {
    await _getDeviceId();
    final storedActivationCode = await _storage.read(key: 'activation_code');
    _isAuthenticated = storedActivationCode != null;
    notifyListeners();
  }

  Future<void> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor;
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }
  }

  Future<bool> activateWithCode(String code) async {
    // TODO: Implement actual activation code verification
    if (code.length == 6) {
      await _storage.write(key: 'activation_code', value: code);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'activation_code');
    _isAuthenticated = false;
    notifyListeners();
  }
}