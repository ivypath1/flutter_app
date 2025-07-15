import 'package:hive_flutter/hive_flutter.dart';
import 'package:ivy_path/models/auth_model.dart';

class StorageService {
  final Box<AuthResponse> _authBox = Hive.box<AuthResponse>("auth");

  Future<void> saveAuthData(AuthResponse authData) async {
    await _authBox.put('current_auth', authData);
  }

  AuthResponse? getAuthData() {
    return _authBox.get('current_auth');
  }

  Future<void> clearAuthData() async {
    await _authBox.clear();
  }

  bool get isAuthenticated => getAuthData() != null;
}