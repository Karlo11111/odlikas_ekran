// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whiteboard_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WhiteboardDataAdapter extends TypeAdapter<WhiteboardData> {
  @override
  final int typeId = 0;

  @override
  WhiteboardData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WhiteboardData(
      id: fields[0] as String,
      name: fields[1] as String,
      lastModified: fields[2] as DateTime,
      paths: (fields[3] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      transformationMatrix: (fields[4] as List).cast<double>(),
      currentScale: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, WhiteboardData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.lastModified)
      ..writeByte(3)
      ..write(obj.paths)
      ..writeByte(4)
      ..write(obj.transformationMatrix)
      ..writeByte(5)
      ..write(obj.currentScale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhiteboardDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
