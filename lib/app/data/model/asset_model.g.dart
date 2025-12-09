// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetModelAdapter extends TypeAdapter<AssetModel> {
  @override
  final typeId = 2;

  @override
  AssetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      category: fields[2] as String,
      subCategory: fields[3] as String,
      purchaseDate: fields[4] as DateTime,
      purchaseValue: (fields[5] as num).toDouble(),
      supplierId: fields[6] as String?,
      invoiceNumber: fields[7] as String?,
      currentValue: (fields[8] as num?)?.toDouble(),
      depreciationRate: (fields[9] as num?)?.toDouble(),
      depreciationMethod: fields[10] as String?,
      disposalDate: fields[11] as DateTime?,
      disposalValue: (fields[12] as num?)?.toDouble(),
      location: fields[13] as String?,
      description: fields[14] as String?,
      isActive: fields[15] == null ? true : fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AssetModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.subCategory)
      ..writeByte(4)
      ..write(obj.purchaseDate)
      ..writeByte(5)
      ..write(obj.purchaseValue)
      ..writeByte(6)
      ..write(obj.supplierId)
      ..writeByte(7)
      ..write(obj.invoiceNumber)
      ..writeByte(8)
      ..write(obj.currentValue)
      ..writeByte(9)
      ..write(obj.depreciationRate)
      ..writeByte(10)
      ..write(obj.depreciationMethod)
      ..writeByte(11)
      ..write(obj.disposalDate)
      ..writeByte(12)
      ..write(obj.disposalValue)
      ..writeByte(13)
      ..write(obj.location)
      ..writeByte(14)
      ..write(obj.description)
      ..writeByte(15)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
