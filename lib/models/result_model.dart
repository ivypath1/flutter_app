import 'package:hive/hive.dart';

part 'result_model.g.dart';


@HiveType(typeId: 6)
class PracticeRecord {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final double duration;

  @HiveField(2)
  final String mode;

  @HiveField(3)
  bool isDraft;

  @HiveField(4)
  final List<Result> results;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final double? aggregateScore;

  PracticeRecord({
    required this.id,
    required this.duration,
    required this.mode,
    this.isDraft = true,
    required this.results,
    DateTime? timestamp,
    this.aggregateScore,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PracticeRecord.fromJson(Map<String, dynamic> json){
      return PracticeRecord(
        id: json["id"], 
        duration: json["duration_in_seconds"]?.toDouble() ?? 0.0, 
        mode: json["mode"], 
        results: (json['results'] as List?)
          ?.map((result) => Result.fromJson(result))
          .toList() ?? [],
        timestamp: json["practice_date"] != null
          ? DateTime.parse(json["practice_date"])
          : DateTime.now(),
        isDraft: false,
      );
  }

  Map<String, dynamic> toJson() {
    return {
      "duration": duration,
      "mode": mode,
      "results": results.map((result) => result.toJson()).toList(),
      "is_draft": isDraft,
      "practice_date": timestamp.toIso8601String(),
    };
  }
  
}


@HiveType(typeId: 7)
class Result {
  @HiveField(0)
  final int subjectId;

  @HiveField(1)
  final Map<int, List> answers;

  @HiveField(2)
  final double score;

  @HiveField(3)
  final double timeSpent;

  Result({
    required this.subjectId,
    required this.answers,
    required this.score,
    required this.timeSpent,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      subjectId: json["subject_id"], 
      answers: json["answers"] != null 
        ? Map<int, List>.from(json["answers"].map((key, value) => MapEntry(int.parse(key), value)))
        : {},
      score: json["score"], 
      timeSpent: json["time_spent"]
    );
  }

  toJson() {
    return {
      "subject_id": subjectId,
      "answers": answers.map((key, value) => MapEntry(key.toString(), value)),
      "score": score,
      "time_spent": timeSpent,
    };
  }
}