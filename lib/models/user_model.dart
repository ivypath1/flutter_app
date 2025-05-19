import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class User {
  @HiveField(0)
  final int id;

  @HiveField(1)
  @JsonKey(name: 'first_name')
  final String firstName;

  @HiveField(2)
  @JsonKey(name: 'last_name')
  final String lastName;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String phone;

  @HiveField(5)
  final String type;

  @HiveField(6)
  final String program;

  @HiveField(7)
  final String status;

  @HiveField(8)
  @JsonKey(name: 'date_joined')
  final String dateJoined;

  @HiveField(9)
  @JsonKey(name: 'is_staff')
  final bool isStaff;

  @HiveField(10)
  final String image;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.type,
    required this.program,
    required this.status,
    required this.dateJoined,
    required this.isStaff,
    required this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}