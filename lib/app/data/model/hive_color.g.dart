// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_color.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveColorAdapter extends TypeAdapter<HiveColor> {
  @override
  final typeId = 7;

  @override
  HiveColor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveColor(
      fields[0] == null ? 0 : (fields[0] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveColor obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveColorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
