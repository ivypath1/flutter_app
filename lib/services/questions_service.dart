


import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:ivy_path/models/auth_model.dart';
import 'package:ivy_path/models/subject_model.dart';

class QuestionsService {
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://ivypath-server.vercel.app',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<List<Question>> getQuestions({int? sectionId, int? version}) async {
    try {
      final Box<AuthResponse> authBox = await Hive.openBox<AuthResponse>('auth');
      final token =  authBox.get('current_auth')?.token;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _dio.get(
        '/portal/sections/$sectionId/?version=$version',
        options: Options(
          headers: {
            'Authorization': 'Token $token',
          },
        ),
      );

      if (response.data.isEmpty) return [];

      final questions = (response.data["questions"] as List)
          .map((question) => Question.fromJson(question))
          .toList();
      
      // Cache the subjects
      final questionsBox = await Hive.openBox<Question>('questions');
      await questionsBox.clear();
      await questionsBox.addAll(questions);

      return questions;
    } catch(e) {
      try {
        final questionsBox = await Hive.openBox<Question>('questions');
        final questions = questionsBox.values.toList();
        if (questions.isNotEmpty) {
          return questions;
        }
      } catch (_) {
        // If we can't get cached subjects, rethrow the original error
      }
      rethrow;
    }

  }
}