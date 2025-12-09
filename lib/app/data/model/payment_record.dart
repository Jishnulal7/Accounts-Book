import 'package:hive_ce/hive.dart';
part 'payment_record.g.dart';

@HiveType(typeId: 13)
class PaymentRecord {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String method;

  @HiveField(3)
  final String? reference;

  PaymentRecord({
    required this.amount,
    required this.date,
    required this.method,
    this.reference,
  });
}
