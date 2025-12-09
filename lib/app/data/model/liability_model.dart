import 'package:hive_ce/hive.dart';
part 'liability_model.g.dart';

@HiveType(typeId: 10)
class LiabilityModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String? partyId;

  @HiveField(6)
  final String? description;

  @HiveField(7)
  final double? interestRate;

  @HiveField(8)
  final String? paymentTerms;

  LiabilityModel({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.date,
    this.partyId,
    this.description,
    this.interestRate,
    this.paymentTerms,
  });
}
