import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String type,
    required String program,
    required String status,
    required DateTime dateJoined,
    required bool isStaff,
    required String image,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}