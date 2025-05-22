import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ivy_path/models/auth_model.dart';
import 'package:ivy_path/services/api_service.dart';
import 'package:ivy_path/services/storage_service.dart';
import 'dart:io';

class AuthProvider extends ChangeNotifier {
  final _storage = StorageService();
  final _api = ApiService();
  final _deviceInfo = DeviceInfoPlugin();
  
  
  bool _isLoading = false;
  String? _error;
  AuthResponse? _authData;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _storage.isAuthenticated;
  AuthResponse? get authData => _authData;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _storage.init();
    _authData = _storage.getAuthData();
    _isInitialized = true;
    notifyListeners();
  }

  Future<String> _getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.name;
      } else if (Platform.isMacOS) {
        final macOsInfo = await _deviceInfo.macOsInfo;
        return macOsInfo.computerName;
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return windowsInfo.computerName;
      }
      
      return 'Unknown Device';
    } catch (e) {
      return 'abcd';
      return 'Unknown Device';
    }
  }

  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      } else if (Platform.isMacOS) {
        final macOsInfo = await _deviceInfo.macOsInfo;
        return macOsInfo.systemGUID ?? 'unknown';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return windowsInfo.deviceId;
      }
      
      return 'unknown';
    } catch (e) {
      return '1234';
      return 'unknown';
    }
  }

  Future<bool> login(String activationCode) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final deviceName = await _getDeviceName();
      final deviceId = await _getDeviceId();

      print(deviceId);
      print(deviceName);

      final authResponse = await _api.login(
        activationCode: activationCode,
        deviceName: deviceName,
        deviceId: deviceId,
      );

      await _storage.saveAuthData(authResponse);
      _authData = authResponse;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearAuthData();
    _authData = null;
    notifyListeners();
  }
}