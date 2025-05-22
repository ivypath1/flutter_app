import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ivy_path/models/auth_model.dart';
import 'package:ivy_path/models/subject_model.dart';
import 'package:ivy_path/services/storage_service.dart';

class SubjectService {
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://ivypath-server.vercel.app',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<List<Subject>> getSubjects() async {
    try {
      final Box<AuthResponse> authBox = await Hive.openBox<AuthResponse>('auth');
     final token =  authBox.get('current_auth')?.token;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _dio.get(
        '/portal/subjects/',
        options: Options(
          headers: {
            'Authorization': 'Token $token',
          },
        ),
      );

      

      final subjects = (response.data as List)
          .map((subject) => Subject.fromJson(subject))
          .toList();

      print(subjects);

      // Cache the subjects
      final subjectsBox = await Hive.openBox<Subject>('subjects');
      await subjectsBox.clear();
      await subjectsBox.addAll(subjects);

      return subjects;
    } catch (e) {
      print(e);
      // If there's an error, try to get cached subjects
      try {
        final subjectsBox = await Hive.openBox<Subject>('subjects');
        final subjects = subjectsBox.values.toList();
        if (subjects.isNotEmpty) {
          return subjects;
        }
      } catch (_) {
        // If we can't get cached subjects, rethrow the original error
      }
      rethrow;
    }
  }
}