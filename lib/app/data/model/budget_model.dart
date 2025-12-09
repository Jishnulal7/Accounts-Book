import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
part 'budget_model.g.dart';

@HiveType(typeId: 5)
class BudgetModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String category;

  @HiveField(2)
  double plannedAmount;

  @HiveField(3)
  double actualAmount;

  @HiveField(4)
  DateTime startDate;

  @HiveField(5)
  DateTime endDate;

  @HiveField(6)
  BudgetPeriod period;

  @HiveField(7)
  String? subCategory;

  BudgetModel({
    String? id,
    required this.category,
    required this.plannedAmount,
    this.actualAmount = 0.0,
    required this.startDate,
    required this.endDate,
    required this.period,
    this.subCategory,
  }) : id = id ?? const Uuid().v4();
}

@HiveType(typeId: 6)
enum BudgetPeriod {
  @HiveField(0)
  weekly,
  @HiveField(1)
  monthly,
  @HiveField(2)
  yearly
}
