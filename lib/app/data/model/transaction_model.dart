import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
part 'transaction_model.g.dart';

@HiveType(typeId: 23)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id = const Uuid().v4();

  @HiveField(1)
  double amount;

  @HiveField(2)
  String description;

  @HiveField(3)
  String? categoryName;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  TransactionType transactionType;

  @HiveField(6)
  String? iconData;

  @HiveField(7)
  String fromAccount;

  @HiveField(8)
  String fromAccountImagePath;

  @HiveField(9)
  String toAccount;

  @HiveField(10)
  String? toAccountImagePath;

  @HiveField(11)
  String? subCategory;

  @HiveField(12)
  String? generalCategory;

  @HiveField(13)
  String? generalSubCategory;

  @HiveField(14)
  String? fromSubAccount;

  @HiveField(15)
  String? toSubAccount;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.description,
    required this.categoryName,
    required this.date,
    required this.transactionType,
    required this.iconData,
    required this.fromAccount,
    required this.toAccount,
    required this.fromAccountImagePath,
    required this.toAccountImagePath,
    required this.subCategory,
    required this.generalCategory,
    required this.generalSubCategory,
    required this.fromSubAccount,
    required this.toSubAccount,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
        id: json['id'] ?? const Uuid().v4(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] ?? '',
        categoryName: json['category'] ?? '',
        date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
        transactionType: _parseTransactionType(json['transactionType'] ?? ''),
        iconData: json['iconData'] ?? '',
        fromAccount: json['fromAccount'] ?? '',
        toAccount: json['toAccount'] ?? '',
        fromAccountImagePath: json['fromAccountIconData'] ?? '',
        toAccountImagePath: json['toAccountIconData'] ?? '',
        subCategory: json['subCategory'],
        generalCategory: json['generalCategory'],
        generalSubCategory: json['generalCategoryImagePath'],
        fromSubAccount: json['fromSubAccount'],
        toSubAccount: json['toSubAccount']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'category': categoryName,
      'date': date.toIso8601String(),
      'transactionType': _getTypeString(transactionType),
      'iconData': iconData,
      'fromAccount': fromAccount,
      'toAccount': toAccount,
      'fromAccountIconData': fromAccountImagePath,
      'toAccountIconData': toAccountImagePath,
      'subCategory': subCategory,
      'generalCategoryImagePath': generalSubCategory,
      'generalCategory': generalCategory,
      'fromSubAccount': fromSubAccount,
      'toSubAccount': toSubAccount
    };
  }

  static TransactionType _parseTransactionType(String typeString) {
    switch (typeString) {
      case 'payment':
        return TransactionType.payment;
      case 'receipt':
        return TransactionType.receipt;
      case 'transfer':
        return TransactionType.transfer;
      case 'presentAttendance':
      default:
        throw ArgumentError('Invalid transaction type: $typeString');
    }
  }

  static String _getTypeString(TransactionType type) {
    switch (type) {
      case TransactionType.payment:
        return 'payment';
      case TransactionType.receipt:
        return 'receipt';
      case TransactionType.transfer:
        return 'transfer';
    }
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, description: $description, '
        'category: $categoryName, date: $date, type: ${_getTypeString(transactionType)}, '
        'iconData: $iconData, fromAccount: $fromAccount, toAccount: $toAccount, '
        'fromAccountIconData: $fromAccountImagePath, toAccountIconData: $toAccountImagePath, '
        'subCategory: $subCategory, )'
        'generalCategory : $generalCategory'
        'subAccount : $fromSubAccount'
        'toSubAccount :$toSubAccount'
        'generalSubCategory : $generalSubCategory';
  }
}

@HiveType(typeId: 24)
enum TransactionType {
  @HiveField(0)
  payment,

  @HiveField(1)
  receipt,

  @HiveField(2)
  transfer,
}
