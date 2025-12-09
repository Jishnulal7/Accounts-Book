// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemModelAdapter extends TypeAdapter<ItemModel> {
  @override
  final typeId = 8;

  @override
  ItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemModel(
      itemName: fields[0] as String?,
      id: fields[9] as String?,
      unit: fields[1] as String?,
      itemType: fields[2] as String?,
      amount: (fields[3] as num?)?.toDouble(),
      hsn: fields[4] as String?,
      gst: fields[5] as String?,
      stockQuantity: (fields[8] as num?)?.toInt(),
      itemDescription: fields[6] as String?,
      itemCategory: fields[7] as String?,
      lowStockQuantity: (fields[10] as num?)?.toInt(),
      lowStockQuantityAlert: fields[11] as bool?,
      date: fields[12] as DateTime?,
      subCategory: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ItemModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.itemName)
      ..writeByte(1)
      ..write(obj.unit)
      ..writeByte(2)
      ..write(obj.itemType)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.hsn)
      ..writeByte(5)
      ..write(obj.gst)
      ..writeByte(6)
      ..write(obj.itemDescription)
      ..writeByte(7)
      ..write(obj.itemCategory)
      ..writeByte(8)
      ..write(obj.stockQuantity)
      ..writeByte(9)
      ..write(obj.id)
      ..writeByte(10)
      ..write(obj.lowStockQuantity)
      ..writeByte(11)
      ..write(obj.lowStockQuantityAlert)
      ..writeByte(12)
      ..write(obj.date)
      ..writeByte(13)
      ..write(obj.subCategory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
