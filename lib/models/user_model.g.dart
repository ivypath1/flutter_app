// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as int,
      firstName: fields[1] as String,
      lastName: fields[2] as String,
      email: fields[3] as String,
      phone: fields[4] as String?,
      type: fields[5] as String,
      program: fields[6] as String,
      status: fields[7] as String,
      dateJoined: fields[8] as String,
      isStaff: fields[9] as bool,
      image: fields[10] as String,
      academic: fields[11] as Academics,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.firstName)
      ..writeByte(2)
      ..write(obj.lastName)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.program)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.dateJoined)
      ..writeByte(9)
      ..write(obj.isStaff)
      ..writeByte(10)
      ..write(obj.image)
      ..writeByte(11)
      ..write(obj.academic);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AcademicsAdapter extends TypeAdapter<Academics> {
  @override
  final int typeId = 8;

  @override
  Academics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Academics(
      jambScores: (fields[0] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      oLevelGrades: (fields[1] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
    );
  }

  @override
  void write(BinaryWriter writer, Academics obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.jambScores)
      ..writeByte(1)
      ..write(obj.oLevelGrades);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num).toInt(),
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      type: json['type'] as String,
      program: json['program'] as String,
      status: json['status'] as String,
      dateJoined: json['date_joined'] as String,
      isStaff: json['is_staff'] as bool,
      image: json['image'],
      academic: Academics.fromJson(json['academic'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'type': instance.type,
      'program': instance.program,
      'status': instance.status,
      'date_joined': instance.dateJoined,
      'is_staff': instance.isStaff,
      'image': instance.image,
      'academic': instance.academic,
    };

Academics _$AcademicsFromJson(Map<String, dynamic> json) => Academics(
      jambScores: (json['jamb_scores'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      oLevelGrades: (json['o_level_grades'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$AcademicsToJson(Academics instance) => <String, dynamic>{
      'jamb_scores': instance.jambScores,
      'o_level_grades': instance.oLevelGrades,
    };
