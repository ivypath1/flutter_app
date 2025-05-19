import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ivy_path/models/user_model.dart';

part 'auth_model.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class AuthResponse {
  @HiveField(0)
  final String token;

  @HiveField(1)
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}