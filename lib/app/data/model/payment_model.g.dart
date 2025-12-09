// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final typeId = 12;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      id: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
      description: fields[2] as String,
      categoryName: fields[3] as String?,
      date: fields[4] as DateTime,
      transactionType: fields[5] as TransactionType,
      fromAccount: fields[7] as String,
      toAccount: fields[9] as String,
      iconData: fields[6] as String?,
      fromAccountImagePath: fields[8] as String,
      subCategory: fields[11] as String?,
      toAccountImagePath: fields[10] as String?,
      generalCategory: fields[12] as String?,
      generalSubCategory: fields[13] as String?,
      fromSubAccount: fields[14] as String?,
      toSubAccount: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.categoryName)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.transactionType)
      ..writeByte(6)
      ..write(obj.iconData)
      ..writeByte(7)
      ..write(obj.fromAccount)
      ..writeByte(8)
      ..write(obj.fromAccountImagePath)
      ..writeByte(9)
      ..write(obj.toAccount)
      ..writeByte(10)
      ..write(obj.toAccountImagePath)
      ..writeByte(11)
      ..write(obj.subCategory)
      ..writeByte(12)
      ..write(obj.generalCategory)
      ..writeByte(13)
      ..write(obj.generalSubCategory)
      ..writeByte(14)
      ..write(obj.fromSubAccount)
      ..writeByte(15)
      ..write(obj.toSubAccount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
