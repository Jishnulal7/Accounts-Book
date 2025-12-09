import 'package:hive_ce/hive.dart';
part 'stock_adjustment_model.g.dart';

@HiveType(typeId: 19)
class StockAdjustmentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String itemId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final double quantity;

  @HiveField(4)
  final double rate;

  @HiveField(5)
  final double amount;

  @HiveField(6)
  final String reason;

  @HiveField(7)
  final AdjustmentType type;

  StockAdjustmentModel({
    required this.id,
    required this.itemId,
    required this.date,
    required this.quantity,
    required this.rate,
    required this.amount,
    required this.reason,
    required this.type,
  });
}

@HiveType(typeId: 20)
enum AdjustmentType {
  @HiveField(0)
  addition,

  @HiveField(1)
  reduction
}