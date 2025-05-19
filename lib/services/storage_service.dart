import 'package:hive_flutter/hive_flutter.dart';
import 'package:ivy_path/models/auth_model.dart';
import 'package:ivy_path/models/user_model.dart';

class StorageService {
  static const String authBoxName = 'auth';
  late Box<AuthResponse> _authBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(AuthResponseAdapter());
    Hive.registerAdapter(UserAdapter());
    _authBox = await Hive.openBox<AuthResponse>(authBoxName);
  }

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