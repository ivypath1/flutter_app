// lib/models/material_model.dart
import 'package:hive/hive.dart';

part 'material_model.g.dart';

@HiveType(typeId: 5)
class Material {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final int subject;

  @HiveField(3)
  final bool isDemo;

  @HiveField(4)
  final DateTime uploadedDate;

  @HiveField(5)
  final String fileSize;

  @HiveField(6)
  final String file;

  Material({
    required this.id,
    required this.title,
    required this.subject,
    required this.isDemo,
    required this.uploadedDate,
    required this.fileSize,
    required this.file,
  });

  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      id: json['id'],
      title: json['title'],
      subject: json['subject'],
      isDemo: json['is_demo'],
      uploadedDate: DateTime.parse(json['uploaded_date']),
      fileSize: json['file_size'],
      file: json['file'],
    );
  }
}
