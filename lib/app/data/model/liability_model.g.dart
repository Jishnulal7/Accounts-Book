// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liability_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LiabilityModelAdapter extends TypeAdapter<LiabilityModel> {
  @override
  final typeId = 10;

  @override
  LiabilityModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LiabilityModel(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      amount: (fields[3] as num).toDouble(),
      date: fields[4] as DateTime,
      partyId: fields[5] as String?,
      description: fields[6] as String?,
      interestRate: (fields[7] as num?)?.toDouble(),
      paymentTerms: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LiabilityModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.partyId)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.interestRate)
      ..writeByte(8)
      ..write(obj.paymentTerms);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiabilityModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
