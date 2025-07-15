// lib/services/subject_service.dart
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ivy_path/models/auth_model.dart';
import 'package:ivy_path/models/subject_model.dart';

class SubjectService {
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://ivypath-server.vercel.app',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<List<Subject>> getSubjects() async {
    try {
      final Box<AuthResponse> authBox = await Hive.openBox<AuthResponse>('auth');
      final token = authBox.get('current_auth')?.token;
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
      // print(response.data);
      final subjects = (response.data as List)
          .map((subject) => Subject.fromJson(subject))
          .toList();

      // Store subjects in Hive
      final subjectsBox = await Hive.openBox<Subject>('subjects');
      for (var subject in subjects) {
        await subjectsBox.put(subject.id, subject);
      }

      // Start background sync of questions
      _syncQuestions(token, subjects);

      return subjects;
    } catch (e) {
      print(e);
      // Try to get cached subjects
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

  Future<void> _syncQuestions(String token, List<Subject> subjects) async {
    final questionsBox = await Hive.openBox<Question>('questions');
    final versionsBox = await Hive.openBox<int>('section_versions');

    for (var subject in subjects) {
      for (var section in subject.sections) {
        final currentVersion = versionsBox.get(section.id) ?? 0;
        
        if (section.version != currentVersion) {
          try {
            final response = await _dio.get(
              '/portal/sections/${section.id}/',
              queryParameters: {'version': currentVersion},
              options: Options(
                headers: {
                  'Authorization': 'Token $token',
                },
              ),
            );

            // Delete existing questions for this section
            final existingQuestions = questionsBox.values
                .where((q) => q.sectionId == section.id)
                .toList();
            for (var question in existingQuestions) {
              await questionsBox.delete(question.id);
            }

            // Add new questions
            final questions = (response.data['questions'] as List)
                .map((q) => Question.fromJson(q))
                .toList();
            for (var question in questions) {
              await questionsBox.put(question.id, question);
            }

            // Update version
            await versionsBox.put(section.id, response.data['version']);
          } catch (e) {
            print('Error syncing questions for section ${section.id}: $e');
            // Continue with next section even if this one fails
            continue;
          }
        }
      }
    }
  }

  Future<void> refreshQuestions() async {
    final subjectsBox = await Hive.openBox<Subject>('subjects');
    final subjects = subjectsBox.values.toList();
    
    final authBox = await Hive.openBox<AuthResponse>('auth');
    final token = authBox.get('current_auth')?.token;
    
    if (token != null) {
      await _syncQuestions(token, subjects);
    }
  }
}
