import 'package:hive_ce/hive.dart';

part 'item_selection_model.g.dart';

@HiveType(typeId: 9)
class ItemSelectionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  final String partyName;

  @HiveField(2)
  String itemName;

  @HiveField(3)
  final double quantity;

  @HiveField(4)
  final String unit;

  @HiveField(5)
  final double rate;

  @HiveField(6)
  final double subTotal;

  @HiveField(7)
  final double discount;

  @HiveField(8)
  final double discountPercentage;

  @HiveField(9)
  final double taxAmount;

  @HiveField(10)
  final String taxType;

  @HiveField(11)
  final double totalAmount;

  @HiveField(12)
  final String? hsnCode;

  ItemSelectionModel({
    required this.id,
    required this.unit,
    required this.itemName,
    required this.quantity,
    required this.rate,
    required this.subTotal,
    required this.discount,
    required this.taxAmount,
    required this.totalAmount,
    required this.partyName,
    required this.discountPercentage,
    required this.taxType,
    required this.hsnCode,
  });

  factory ItemSelectionModel.fromMap(Map<String, dynamic> map) {
    return ItemSelectionModel(
      id: map['id'] as String,
      partyName: map['partyName'] as String,
      itemName: map['itemName'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      rate: (map['rate'] as num).toDouble(),
      subTotal: (map['subTotal'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      discountPercentage: (map['discountPercentage'] as num).toDouble(),
      taxAmount: (map['taxAmount'] as num).toDouble(),
      taxType: map['taxType'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      hsnCode: map['hsnCode'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partyName': partyName,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'subTotal': subTotal,
      'discount': discount,
      'discountPercentage': discountPercentage,
      'taxAmount': taxAmount,
      'taxType': taxType,
      'totalAmount': totalAmount,
      'hsnCode': hsnCode,
    };
  }

  @override
  String toString() {
    return 'ItemSelectionModel(id: $id, partyName: $partyName, itemName: $itemName, quantity: $quantity, unit: $unit, rate: $rate, subTotal: $subTotal, discount: $discount, discountPercentage: $discountPercentage, taxAmount: $taxAmount, type: $taxType, totalAmount: $totalAmount)';
  }

  ItemSelectionModel copyWith({
    String? id,
    String? partyName,
    String? itemName,
    double? quantity,
    String? unit,
    double? rate,
    double? subTotal,
    double? discount,
    double? discountPercentage,
    double? taxAmount,
    String? type,
    double? totalAmount,
    String? hsnCode,
  }) {
    return ItemSelectionModel(
      id: id ?? this.id,
      partyName: partyName ?? this.partyName,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      subTotal: subTotal ?? this.subTotal,
      discount: discount ?? this.discount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      taxAmount: taxAmount ?? this.taxAmount,
      taxType: type ?? taxType,
      totalAmount: totalAmount ?? this.totalAmount,
      hsnCode: hsnCode ?? this.hsnCode,
    );
  }
}
