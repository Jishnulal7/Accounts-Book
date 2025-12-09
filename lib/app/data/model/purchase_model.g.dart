// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PurchaseModelAdapter extends TypeAdapter<PurchaseModel> {
  @override
  final typeId = 14;

  @override
  PurchaseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseModel(
      invoiceNumber: fields[0] as String,
      partyName: fields[1] as String,
      date: fields[2] as DateTime,
      item: (fields[3] as List).cast<ItemSelectionModel>(),
      totalAmount: (fields[4] as num).toDouble(),
      paidAmount: (fields[5] as num?)?.toDouble(),
      balanceAmount: (fields[6] as num).toDouble(),
      type: fields[7] as PurchaseType,
      paymentType: fields[8] as String?,
      id: fields[9] as String?,
      stateOfSupply: fields[10] as String?,
      transportaionDetails: (fields[11] as List?)?.cast<String>(),
      isRoundedOff: fields[12] == null ? false : fields[12] as bool,
      isFullyPaid: fields[13] == null ? false : fields[13] as bool,
      additionalCharges: (fields[17] as num?)?.toDouble(),
      shippingCharges: (fields[14] as num?)?.toDouble(),
      discounts: (fields[16] as num?)?.toDouble(),
      packingCharges: (fields[15] as num?)?.toDouble(),
      partyId: fields[18] as String?,
      invoicePrefix: fields[19] as String?,
      paymentHistory: (fields[20] as List?)?.cast<PaymentRecord>(),
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.invoiceNumber)
      ..writeByte(1)
      ..write(obj.partyName)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.item)
      ..writeByte(4)
      ..write(obj.totalAmount)
      ..writeByte(5)
      ..write(obj.paidAmount)
      ..writeByte(6)
      ..write(obj.balanceAmount)
      ..writeByte(7)
      ..write(obj.type)
      ..writeByte(8)
      ..write(obj.paymentType)
      ..writeByte(9)
      ..write(obj.id)
      ..writeByte(10)
      ..write(obj.stateOfSupply)
      ..writeByte(11)
      ..write(obj.transportaionDetails)
      ..writeByte(12)
      ..write(obj.isRoundedOff)
      ..writeByte(13)
      ..write(obj.isFullyPaid)
      ..writeByte(14)
      ..write(obj.shippingCharges)
      ..writeByte(15)
      ..write(obj.packingCharges)
      ..writeByte(16)
      ..write(obj.discounts)
      ..writeByte(17)
      ..write(obj.additionalCharges)
      ..writeByte(18)
      ..write(obj.partyId)
      ..writeByte(19)
      ..write(obj.invoicePrefix)
      ..writeByte(20)
      ..write(obj.paymentHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PurchaseTypeAdapter extends TypeAdapter<PurchaseType> {
  @override
  final typeId = 15;

  @override
  PurchaseType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PurchaseType.purchase;
      case 1:
        return PurchaseType.purchaseReturn;
      case 2:
        return PurchaseType.purchaseOrder;
      default:
        return PurchaseType.purchase;
    }
  }

  @override
  void write(BinaryWriter writer, PurchaseType obj) {
    switch (obj) {
      case PurchaseType.purchase:
        writer.writeByte(0);
      case PurchaseType.purchaseReturn:
        writer.writeByte(1);
      case PurchaseType.purchaseOrder:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
