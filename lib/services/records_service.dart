import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ivy_path/models/auth_model.dart';
import 'package:ivy_path/models/result_model.dart';

class RecordsService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://ivypath-server.vercel.app',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  final recordsBox = Hive.box<PracticeRecord>("results");
    final authBox = Hive.box<AuthResponse>("auth");

  /// Syncs draft records to backend, then fetches all records and saves to Hive.
  Future<void> syncDraftAndFetchRecords() async {
    final token = authBox.get('current_auth')?.token;

    if (token == null) {
      throw Exception('Not authenticated');
    }

    // 1. Post draft records to backend
    final drafts = recordsBox.values
        .where((record) => record.isDraft == true)
        .toList();

    for (var draft in drafts) {
      // print(draft.toJson());
      try {
        final response = await _dio.post(
          '/portal/records/',
          data: draft.toJson(),
          options: Options(
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Remove draft from Hive
          final key = recordsBox.keys.firstWhere((k) => recordsBox.get(k) == draft);
          await recordsBox.put(key, draft..isDraft = false);
        }
      } catch (e) {
        // Log or handle error, but continue with next draft
        print('Failed to sync draft: $e');
      }
    }

    // 2. Fetch all records from backend and save to Hive
    try {
      final response = await _dio.get(
        '/portal/records/',
        options: Options(
          headers: {
            'Authorization': 'Token $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        await recordsBox.clear();
        for (var data in response.data) {
          final PracticeRecord record = PracticeRecord.fromJson(data);
          await recordsBox.add(record);
        }
      }
    } catch (e) {
      print('Failed to fetch records: $e');
    }
  }

  Future<void> addDraftRecordToBackend (int recordKey) async {
    final token = authBox.get('current_auth')?.token;

    if (token == null) {
      throw Exception('Not authenticated');
    }

    final draft = recordsBox.get(recordKey);
    if (draft == null || draft.isDraft != true) {
      throw Exception('Draft record not found');
    }

    try {
      final response = await _dio.post(
        '/portal/records/',
        data: draft.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Set draft to false and update in Hive
        draft.isDraft = false;
        await recordsBox.put(recordKey, draft);
      }
    } catch (e) {
      print('Failed to add draft record: $e');
    }
  }
}