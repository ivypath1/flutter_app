// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'result_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PracticeRecordAdapter extends TypeAdapter<PracticeRecord> {
  @override
  final int typeId = 6;

  @override
  PracticeRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PracticeRecord(
      id: fields[0] as int,
      duration: fields[1] as double,
      mode: fields[2] as String,
      isDraft: fields[3] as bool,
      results: (fields[4] as List).cast<Result>(),
      timestamp: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PracticeRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.duration)
      ..writeByte(2)
      ..write(obj.mode)
      ..writeByte(3)
      ..write(obj.isDraft)
      ..writeByte(4)
      ..write(obj.results)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ResultAdapter extends TypeAdapter<Result> {
  @override
  final int typeId = 7;

  @override
  Result read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Result(
      subjectId: fields[0] as int,
      answers: (fields[1] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as int, (v as List).cast<dynamic>())),
      score: fields[2] as double,
      timeSpent: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Result obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.subjectId)
      ..writeByte(1)
      ..write(obj.answers)
      ..writeByte(2)
      ..write(obj.score)
      ..writeByte(3)
      ..write(obj.timeSpent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
