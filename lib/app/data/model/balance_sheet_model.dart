import 'package:hive_ce/hive.dart';
part 'balance_sheet_model.g.dart';

@HiveType(typeId: 4)
class BalanceSheetModel extends HiveObject {
  @HiveField(0)
  final DateTime date;
  
  @HiveField(1)
  final Map<String, double> assets;
  
  @HiveField(2)
  final Map<String, double> liabilities;
  
  @HiveField(3)
  final double netWorth;

  BalanceSheetModel({
    required this.date,
    required this.assets,
    required this.liabilities,
    required this.netWorth,
  });
}