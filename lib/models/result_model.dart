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
  final bool isDraft;

  @HiveField(4)
  final List<Result> results;

  @HiveField(5)
  final DateTime timestamp;

  PracticeRecord({
    required this.id,
    required this.duration,
    required this.mode,
    this.isDraft = true,
    required this.results,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PracticeRecord.fromJson(Map<String, dynamic> json){
      return PracticeRecord(
        id: json["id"], 
        duration: json["duration"], 
        mode: json["mode"], 
        results: (json['results'] as List?)
          ?.map((section) => Result.fromJson(section))
          .toList() ?? [],
    );
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
      answers: json["answers"], 
      score: json["score"], 
      timeSpent: json["time_spent"]
    );
  }
}