// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_sheet_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BalanceSheetModelAdapter extends TypeAdapter<BalanceSheetModel> {
  @override
  final typeId = 4;

  @override
  BalanceSheetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BalanceSheetModel(
      date: fields[0] as DateTime,
      assets: (fields[1] as Map).cast<String, double>(),
      liabilities: (fields[2] as Map).cast<String, double>(),
      netWorth: (fields[3] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, BalanceSheetModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.assets)
      ..writeByte(2)
      ..write(obj.liabilities)
      ..writeByte(3)
      ..write(obj.netWorth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BalanceSheetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
