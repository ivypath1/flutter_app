// lib/models/subject_model.dart
import 'package:hive/hive.dart';

part 'subject_model.g.dart';

@HiveType(typeId: 2)
class Subject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<Section> sections;

  Subject({
    required this.id,
    required this.name,
    required this.sections,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      sections: (json['sections'] as List?)
          ?.map((section) => Section.fromJson(section))
          .toList() ?? [],
    );
  }
}

@HiveType(typeId: 3)
class Section {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int subjectId;

  @HiveField(3)
  final int version;

  Section({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.version,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    print(json['version'].runtimeType );
    print(json['subject_id'].runtimeType );
    print(json['id'].runtimeType );
    return Section(
      id: json['id'],
      name: json['name'],
      subjectId: json['subject_id'],
      version: json['version'] ?? 0,
    );
  }
}

@HiveType(typeId: 4)
class Question {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String question;

  @HiveField(2)
  final List<Map<String, String>> options;

  @HiveField(3)
  final String answer;

  @HiveField(4)
  final String solution;

  @HiveField(5)
  final int sectionId;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.solution,
    required this.sectionId,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'],
      options: (json['options'] as List).map((option) => {
        'id': option['id'] as String,
        'text': option['text'] as String,
      }).toList(),
      answer: json['answer'],
      solution: json['solution'],
      sectionId: json['section'],
    );
  }
}
