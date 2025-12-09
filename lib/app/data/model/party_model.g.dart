// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PartyModelAdapter extends TypeAdapter<PartyModel> {
  @override
  final typeId = 11;

  @override
  PartyModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PartyModel(
      name: fields[1] as String?,
      id: fields[0] as String?,
      category: fields[2] as String?,
      contactNumber: fields[3] as String?,
      isCustomer: fields[4] as bool?,
      gstNumber: fields[5] as String?,
      panNumber: fields[6] as String?,
      openingBalance: (fields[7] as num?)?.toDouble(),
      isPayment: fields[8] as bool?,
      creditPeriod: fields[9] as String?,
      creditAmount: (fields[10] as num?)?.toDouble(),
      date: fields[11] as DateTime?,
      email: fields[12] as String?,
      billingStreet: fields[13] as String?,
      billingCity: fields[14] as String?,
      billingState: fields[15] as String?,
      billingPincode: fields[16] as String?,
      shippingStreet: fields[17] as String?,
      shippingCity: fields[18] as String?,
      shippingState: fields[19] as String?,
      shippingPincode: fields[20] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PartyModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.contactNumber)
      ..writeByte(4)
      ..write(obj.isCustomer)
      ..writeByte(5)
      ..write(obj.gstNumber)
      ..writeByte(6)
      ..write(obj.panNumber)
      ..writeByte(7)
      ..write(obj.openingBalance)
      ..writeByte(8)
      ..write(obj.isPayment)
      ..writeByte(9)
      ..write(obj.creditPeriod)
      ..writeByte(10)
      ..write(obj.creditAmount)
      ..writeByte(11)
      ..write(obj.date)
      ..writeByte(12)
      ..write(obj.email)
      ..writeByte(13)
      ..write(obj.billingStreet)
      ..writeByte(14)
      ..write(obj.billingCity)
      ..writeByte(15)
      ..write(obj.billingState)
      ..writeByte(16)
      ..write(obj.billingPincode)
      ..writeByte(17)
      ..write(obj.shippingStreet)
      ..writeByte(18)
      ..write(obj.shippingCity)
      ..writeByte(19)
      ..write(obj.shippingState)
      ..writeByte(20)
      ..write(obj.shippingPincode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartyModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
