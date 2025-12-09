// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_selection_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemSelectionModelAdapter extends TypeAdapter<ItemSelectionModel> {
  @override
  final typeId = 9;

  @override
  ItemSelectionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemSelectionModel(
      id: fields[0] as String,
      unit: fields[4] as String,
      itemName: fields[2] as String,
      quantity: (fields[3] as num).toDouble(),
      rate: (fields[5] as num).toDouble(),
      subTotal: (fields[6] as num).toDouble(),
      discount: (fields[7] as num).toDouble(),
      taxAmount: (fields[9] as num).toDouble(),
      totalAmount: (fields[11] as num).toDouble(),
      partyName: fields[1] as String,
      discountPercentage: (fields[8] as num).toDouble(),
      taxType: fields[10] as String,
      hsnCode: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ItemSelectionModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.partyName)
      ..writeByte(2)
      ..write(obj.itemName)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.rate)
      ..writeByte(6)
      ..write(obj.subTotal)
      ..writeByte(7)
      ..write(obj.discount)
      ..writeByte(8)
      ..write(obj.discountPercentage)
      ..writeByte(9)
      ..write(obj.taxAmount)
      ..writeByte(10)
      ..write(obj.taxType)
      ..writeByte(11)
      ..write(obj.totalAmount)
      ..writeByte(12)
      ..write(obj.hsnCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemSelectionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
