import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
part 'asset_model.g.dart';

@HiveType(typeId: 2)
class AssetModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category; // Fixed/Current/Intangible

  @HiveField(3)
  String subCategory; // Machinery, Vehicle, etc.

  @HiveField(4)
  DateTime purchaseDate;

  @HiveField(5)
  double purchaseValue;

  @HiveField(6)
  String? supplierId; // Links to PartyModel

  @HiveField(7)
  String? invoiceNumber; // Links to PurchaseModel

  @HiveField(8)
  double? currentValue;

  @HiveField(9)
  double? depreciationRate;

  @HiveField(10)
  String? depreciationMethod; // Straight-line/Written Down Value

  @HiveField(11)
  DateTime? disposalDate;

  @HiveField(12)
  double? disposalValue;

  @HiveField(13)
  String? location;

  @HiveField(14)
  String? description;

  @HiveField(15)
  bool isActive;

  AssetModel({
    String? id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.purchaseDate,
    required this.purchaseValue,
    this.supplierId,
    this.invoiceNumber,
    this.currentValue,
    this.depreciationRate,
    this.depreciationMethod,
    this.disposalDate,
    this.disposalValue,
    this.location,
    this.description,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4();
  AssetModel copyWith({
    String? id,
    String? name,
    String? category,
    String? subCategory,
    DateTime? purchaseDate,
    double? purchaseValue,
    String? supplierId,
    String? invoiceNumber,
    double? currentValue,
    double? depreciationRate,
    String? depreciationMethod,
    DateTime? disposalDate,
    double? disposalValue,
    String? location,
    String? description,
    bool? isActive,
  }) {
    return AssetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseValue: purchaseValue ?? this.purchaseValue,
      supplierId: supplierId ?? this.supplierId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      currentValue: currentValue ?? this.currentValue,
      depreciationRate: depreciationRate ?? this.depreciationRate,
      depreciationMethod: depreciationMethod ?? this.depreciationMethod,
      disposalDate: disposalDate ?? this.disposalDate,
      disposalValue: disposalValue ?? this.disposalValue,
      location: location ?? this.location,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
  // Add fromJson, toJson, copyWith methods similar to your other models
}
