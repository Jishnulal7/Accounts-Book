import 'package:hive_ce/hive.dart';
part 'account_model.g.dart';

@HiveType(typeId: 1)
class AccountModel {
  @HiveField(0)
   String name;
  
  @HiveField(1)
  final String imagePath;
  
  @HiveField(2)
   double initialAmount;
  
  @HiveField(3)
   List<String> subAccount;

  AccountModel({
    required this.name,
    required this.imagePath,
    required this.initialAmount,
    required this.subAccount,
  });
}