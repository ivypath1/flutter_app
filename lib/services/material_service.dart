// lib/services/material_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:ivy_path/models/auth_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../models/material_model.dart';

class MaterialService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://ivypath-server.vercel.app/',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  final _storage = const FlutterSecureStorage();
  final _key = encrypt.Key.fromLength(32);
  final _iv = encrypt.IV.fromLength(16);

  Future<List<Material>> getMaterials() async {
    try {
      final Box<AuthResponse> authBox = await Hive.openBox<AuthResponse>('auth');
      final token = authBox.get('current_auth')?.token;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _dio.get(
        '/api/admin/materials/',
        options: Options(
          headers: {
            'Authorization': 'Token $token',
          },
        ),
      );

      final materials = (response.data as List)
          .map((material) => Material.fromJson(material))
          .toList();

      // Cache materials
      // final materialsBox = await Hive.openBox<Material>('materials');
      // await materialsBox.clear();
      // await materialsBox.addAll(materials);

      return materials;
    } catch (e) {
      // Try to get cached materials
      try {
        final materialsBox = await Hive.openBox<Material>('materials');
        final materials = materialsBox.values.toList();
        return materials;
      } catch (_) {
        // If we can't get cached materials, rethrow the original error
      }
      rethrow;
    }
  }

  Future<bool> isDownloaded(int materialId) async {
    try {
      // Get application documents directory
      final directory = await _getPrivateDirectory();
      final filePath = '${directory.path}/$materialId.pdf';
      // print(filePath);
      return await File(filePath).exists();
    } catch(e) {
      return false;
    }

  }

  Future<String> downloadMaterial(Material material) async {
    try {
      // Get application documents directory
      final directory = await _getPrivateDirectory();
      final filePath = '${directory.path}/${material.id}.pdf';
      
      // Check if file already exists
      if (await File(filePath).exists()) {
        return filePath;
      }

      // Download file
      final response = await _dio.get(
        material.file,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      // Encrypt file data
      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final encrypted = encrypter.encryptBytes(response.data, iv: _iv);

      // Save encrypted file
      await File(filePath).writeAsBytes(encrypted.bytes);
      
      // Save encryption key securely
      await _storage.write(
        key: 'material_key_${material.id}',
        value: _key.base64,
      );

      await _storage.write(
        key: 'material_iv_${material.id}',
        value: _iv.base64,
      );

      // Cache materials
      final materialsBox = await Hive.openBox<Material>('materials');
      await materialsBox.add(material);

      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  Future<Directory> _getPrivateDirectory() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final directory = await getApplicationDocumentsDirectory();
      final materialsDir = Directory('${directory.path}/materials');
      if (!await materialsDir.exists()) {
        await materialsDir.create(recursive: true);
      }
      return materialsDir;
    } else if (Platform.isAndroid) {
      final directory = await getApplicationSupportDirectory();
      final materialsDir = Directory('${directory.path}/materials');
      if (!await materialsDir.exists()) {
        await materialsDir.create(recursive: true);
      }
      return materialsDir;
    } else if (Platform.isWindows || Platform.isLinux) {
      final directory = await getApplicationSupportDirectory();
      final materialsDir = Directory('${directory.path}/materials');
      if (!await materialsDir.exists()) {
        await materialsDir.create(recursive: true);
      }
      return materialsDir;
    } else {
      // Web platform - use IndexedDB through Hive
      throw UnimplementedError('Web platform not supported for file download');
    }
  }

  Future<File> getLocalMaterial(int materialId) async {
    // Read the saved key for this material
    final keyBase64 = await _storage.read(key: 'material_key_$materialId');
    final ivBase64 = await _storage.read(key: 'material_iv_$materialId');
    if (keyBase64 == null) {
      throw Exception('No encryption key found for material $materialId');
    }
    if (ivBase64 == null) {
      throw Exception('No encryption iv found for material $materialId');
    }

    final key = encrypt.Key.fromBase64(keyBase64);
    final iv = encrypt.IV.fromBase64(ivBase64);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    // Load encrypted file
    final directory = await _getPrivateDirectory();
    final encryptedFilePath = '${directory.path}/$materialId.pdf';
    final encryptedBytes = await File(encryptedFilePath).readAsBytes();

    // ecrypt
    final decryptedBytes = encrypter.decryptBytes(
      encrypt.Encrypted(encryptedBytes),
      iv: iv,
    );

    // Write to temp file and return
    final tempDir = await getTemporaryDirectory();
    final decryptedFile = File('${tempDir.path}/$materialId-decrypted.pdf');

    await decryptedFile.writeAsBytes(decryptedBytes);

    return decryptedFile;
  }

}
