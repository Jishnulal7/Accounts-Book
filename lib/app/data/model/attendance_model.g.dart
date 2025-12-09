// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceModelAdapter extends TypeAdapter<AttendanceModel> {
  @override
  final typeId = 3;

  @override
  AttendanceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceModel(
      date: fields[0] as DateTime,
      isPresent: fields[1] as bool,
      name: fields[2] as String,
      wage: (fields[3] as num).toDouble(),
      siteName: fields[4] as String,
      extraCharges: (fields[5] as num).toDouble(),
      description: fields[6] as String,
      payment: (fields[7] as num).toDouble(),
      balance: (fields[8] as num).toDouble(),
      account: fields[10] as String,
      openingBalance: (fields[9] as num).toDouble(),
      subName: fields[11] as String,
      accountPath: fields[15] as String,
      categoryPath: fields[14] as String,
      generalCategoryName: fields[16] as String?,
      generalSubCategory: fields[18] as String?,
      subCategory: fields[17] as String?,
      subAccount: fields[19] as String?,
      id: fields[12] as String?,
      categoryName: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.isPresent)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.wage)
      ..writeByte(4)
      ..write(obj.siteName)
      ..writeByte(5)
      ..write(obj.extraCharges)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.payment)
      ..writeByte(8)
      ..write(obj.balance)
      ..writeByte(9)
      ..write(obj.openingBalance)
      ..writeByte(10)
      ..write(obj.account)
      ..writeByte(11)
      ..write(obj.subName)
      ..writeByte(12)
      ..write(obj.id)
      ..writeByte(13)
      ..write(obj.categoryName)
      ..writeByte(14)
      ..write(obj.categoryPath)
      ..writeByte(15)
      ..write(obj.accountPath)
      ..writeByte(16)
      ..write(obj.generalCategoryName)
      ..writeByte(17)
      ..write(obj.subCategory)
      ..writeByte(18)
      ..write(obj.generalSubCategory)
      ..writeByte(19)
      ..write(obj.subAccount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
