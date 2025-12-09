import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:hive_ce/hive.dart';
part 'receipt_model.g.dart';

@HiveType(typeId: 16)
class Receipt extends TransactionModel {
  Receipt({
    required super.id,
    required super.amount,
    required super.description,
    required super.categoryName,
    required super.date,
    required super.fromAccount,
    required super.toAccount,
    required TransactionType transactionType,
    required super.iconData,
    required super.fromAccountImagePath,
    required super.toAccountImagePath,
    required super.subCategory,
    required super.generalCategory,
    required super.generalSubCategory,
    required super.fromSubAccount,
    required super.toSubAccount,
  }) : super(transactionType: TransactionType.receipt);

  factory Receipt.fromTransaction(TransactionModel transaction) {
    return Receipt(
      id: transaction.id,
      amount: transaction.amount,
      description: transaction.description,
      categoryName: transaction.categoryName,
      date: transaction.date,
      transactionType: TransactionType.receipt,
      iconData: transaction.iconData,
      fromAccount: transaction.fromAccount,
      toAccount: transaction.toAccount,
      fromAccountImagePath: transaction.fromAccountImagePath,
      toAccountImagePath: transaction.toAccountImagePath,
      subCategory: transaction.subCategory,
      generalCategory: transaction.generalCategory,
      generalSubCategory: transaction.generalSubCategory,
      fromSubAccount: transaction.fromSubAccount,
      toSubAccount: transaction.toSubAccount,
    );
  }
}
