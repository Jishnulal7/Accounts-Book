// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaleModelAdapter extends TypeAdapter<SaleModel> {
  @override
  final typeId = 17;

  @override
  SaleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleModel(
      invoiceNumber: fields[0] as String,
      partyName: fields[1] as String,
      date: fields[2] as DateTime,
      item: (fields[3] as List).cast<ItemSelectionModel>(),
      totalAmount: (fields[4] as num).toDouble(),
      receivedAmount: (fields[5] as num?)?.toDouble(),
      balanceAmount: (fields[6] as num).toDouble(),
      type: fields[7] as SalesType,
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
  void write(BinaryWriter writer, SaleModel obj) {
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
      ..write(obj.receivedAmount)
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
      other is SaleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SalesTypeAdapter extends TypeAdapter<SalesType> {
  @override
  final typeId = 18;

  @override
  SalesType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SalesType.sale;
      case 1:
        return SalesType.salesReturn;
      case 2:
        return SalesType.estimation;
      case 3:
        return SalesType.deliveryChallan;
      case 4:
        return SalesType.proforma;
      case 5:
        return SalesType.salesOrder;
      default:
        return SalesType.sale;
    }
  }

  @override
  void write(BinaryWriter writer, SalesType obj) {
    switch (obj) {
      case SalesType.sale:
        writer.writeByte(0);
      case SalesType.salesReturn:
        writer.writeByte(1);
      case SalesType.estimation:
        writer.writeByte(2);
      case SalesType.deliveryChallan:
        writer.writeByte(3);
      case SalesType.proforma:
        writer.writeByte(4);
      case SalesType.salesOrder:
        writer.writeByte(5);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
