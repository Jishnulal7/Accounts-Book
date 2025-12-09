import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:hive_ce/hive.dart';
part 'transfer_model.g.dart';

@HiveType(typeId: 25)
class Transfer extends TransactionModel {
  Transfer({
    required super.id,
    required super.amount,
    required super.description,
    super.categoryName,
    required super.date,
    required super.fromAccount,
    required super.toAccount,
    required TransactionType transactionType,
    super.iconData,
    required super.fromAccountImagePath,
    required super.toAccountImagePath,
    super.subCategory,
    super.generalCategory,
    super.generalSubCategory,
    required super.fromSubAccount,
    required super.toSubAccount,
  }) : super(
          transactionType: TransactionType.transfer,
        );

  factory Transfer.fromTransaction(TransactionModel transaction) {
    return Transfer(
      id: transaction.id,
      amount: transaction.amount,
      description: transaction.description,
      date: transaction.date,
      transactionType: TransactionType.transfer,
      fromAccount: transaction.fromAccount,
      toAccount: transaction.toAccount,
      fromAccountImagePath: transaction.fromAccountImagePath,
      toAccountImagePath: transaction.toAccountImagePath,
      fromSubAccount: transaction.fromSubAccount,
      toSubAccount: transaction.toSubAccount,
    );
  }
}
