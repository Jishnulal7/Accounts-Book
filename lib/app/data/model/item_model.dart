import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
part 'item_model.g.dart';

@HiveType(typeId: 8)
class ItemModel extends HiveObject {
  @HiveField(0)
  String? itemName;

  @HiveField(1)
  String? unit;

  @HiveField(2)
  String? itemType;

  @HiveField(3)
  double? amount;

  @HiveField(4)
  String? hsn;

  @HiveField(5)
  String? gst;

  @HiveField(6)
  String? itemDescription;

  @HiveField(7)
  String? itemCategory;

  @HiveField(8)
  int? stockQuantity;

  @HiveField(9)
  String? id = const Uuid().v4();

  @HiveField(10)
  int? lowStockQuantity;

  @HiveField(11)
  bool? lowStockQuantityAlert;

  @HiveField(12)
  DateTime? date;

  @HiveField(13)
  String? subCategory;

  ItemModel({
    this.itemName,
    this.id,
    this.unit,
    this.itemType,
    this.amount,
    this.hsn,
    this.gst,
    this.stockQuantity,
    this.itemDescription,
    this.itemCategory,
    this.lowStockQuantity,
    this.lowStockQuantityAlert,
    this.date,
    this.subCategory,
  });
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      itemName: json['itemName'] ?? '',
      id: json['id'] ?? const Uuid().v4(),
      unit: json['unit'],
      itemType: json['itemType'],
      amount: json['amount'],
      hsn: json['hsn'],
      gst: json['gst'],
      itemDescription: json['itemDescription'],
      itemCategory: json['itemCategory'],
      stockQuantity: json['stockQuantity'],
      lowStockQuantity: json['lowStockQuantity'],
      lowStockQuantityAlert: json['lowStockQuantityAlert'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      subCategory: json['subCategory'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'unit': unit,
      'itemType': itemType,
      'amount': amount?.toString(),
      'hsn': hsn,
      'gst': gst,
      'itemDescription': itemDescription,
      'itemCategory': itemCategory,
      'stockQuantity': stockQuantity?.toString(),
      'id': id,
      'lowStockQuantity': lowStockQuantity?.toString(),
      'date': date.toString(),
      'lowStockQuantityAlert': lowStockQuantityAlert.toString(),
      'subCategory': subCategory,
    };
  }

  @override
  String toString() {
    return 'ItemModel{ itemName: $itemName, unit: $unit, itemType: $itemType, amount: ${amount?.toString()}, hsn: $hsn, gst: $gst, itemDescription: $itemDescription, itemCategory: $itemCategory, stockQuantity: ${stockQuantity?.toString()}, id: $id, lowStockQuantity: ${lowStockQuantity?.toString()}, date: ${date.toString()}, lowStockQuantityAlert: $lowStockQuantityAlert ,itemSubcategory : $subCategory,}';
  }

  ItemModel copyWith({
    String? itemName,
    String? unit,
    String? itemType,
    double? amount,
    String? hsn,
    String? gst,
    String? itemDescription,
    String? itemCategory,
    int? stockQuantity,
    String? id,
    int? lowStockQuantity,
    bool? lowStockQuantityAlert,
    DateTime? date,
    String? subCategory,
  }) {
    return ItemModel(
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      itemType: itemType ?? this.itemType,
      amount: amount ?? this.amount,
      hsn: hsn ?? this.hsn,
      gst: gst ?? this.gst,
      itemDescription: itemDescription ?? this.itemDescription,
      itemCategory: itemCategory ?? this.itemCategory,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      id: id ?? this.id,
      lowStockQuantity: lowStockQuantity ?? this.lowStockQuantity,
      lowStockQuantityAlert:
          lowStockQuantityAlert ?? this.lowStockQuantityAlert,
      date: date ?? this.date,
      subCategory: subCategory ?? this.subCategory,
    );
  }
}
