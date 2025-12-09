// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_adjustment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockAdjustmentModelAdapter extends TypeAdapter<StockAdjustmentModel> {
  @override
  final typeId = 19;

  @override
  StockAdjustmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockAdjustmentModel(
      id: fields[0] as String,
      itemId: fields[1] as String,
      date: fields[2] as DateTime,
      quantity: (fields[3] as num).toDouble(),
      rate: (fields[4] as num).toDouble(),
      amount: (fields[5] as num).toDouble(),
      reason: fields[6] as String,
      type: fields[7] as AdjustmentType,
    );
  }

  @override
  void write(BinaryWriter writer, StockAdjustmentModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.rate)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.reason)
      ..writeByte(7)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockAdjustmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AdjustmentTypeAdapter extends TypeAdapter<AdjustmentType> {
  @override
  final typeId = 20;

  @override
  AdjustmentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AdjustmentType.addition;
      case 1:
        return AdjustmentType.reduction;
      default:
        return AdjustmentType.addition;
    }
  }

  @override
  void write(BinaryWriter writer, AdjustmentType obj) {
    switch (obj) {
      case AdjustmentType.addition:
        writer.writeByte(0);
      case AdjustmentType.reduction:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdjustmentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
