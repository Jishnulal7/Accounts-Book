import 'package:account_book/app/data/model/sale_model.dart';
import 'package:account_book/app/data/model/purchase_model.dart';
import 'package:account_book/app/data/helpers/enums/transaction_type.dart';
import 'package:hive_ce/hive.dart';

class InvoiceNumberManager {
  // Cache for the last used invoice numbers
  static final Map<String, int> _lastUsedNumbers = {};

  static String _getTypeKey(TransactionType transType, dynamic subType) {
    return '${transType.toString()}_${subType.toString()}';
  }

  static Future<int> getNextInvoiceNumber(
    TransactionType transactionType,
    dynamic subType,
  ) async {
    final String typeKey = _getTypeKey(transactionType, subType);

    // If we have a cached number, return the next one
    if (_lastUsedNumbers.containsKey(typeKey)) {
      return _lastUsedNumbers[typeKey]! + 1;
    }

    // Otherwise, get the current max from the database
    final box = await _getAppropriateBox(transactionType);

    if (box.isEmpty) {
      _lastUsedNumbers[typeKey] = 0;
      return 1;
    }

    final transactionsOfType = box.values.where((transaction) {
      return transaction.type == subType;
    }).toList();

    if (transactionsOfType.isEmpty) {
      _lastUsedNumbers[typeKey] = 0;
      return 1;
    }

    // Find max invoice number
    int maxNumber = transactionsOfType
        .map((transaction) => int.tryParse(transaction.invoiceNumber) ?? 0)
        .reduce((curr, next) => curr > next ? curr : next);

    _lastUsedNumbers[typeKey] = maxNumber;
    return maxNumber + 1;
  }

  static Future<void> reserveInvoiceNumber(
    TransactionType transactionType,
    dynamic subType,
    int number,
  ) async {
    final String typeKey = _getTypeKey(transactionType, subType);
    _lastUsedNumbers[typeKey] = number;
  }

  static Future<Box> _getAppropriateBox(TransactionType type) async {
    switch (type) {
      case TransactionType.sale:
        return await Hive.openBox<SaleModel>('saleBox');
      case TransactionType.purchase:
        return await Hive.openBox<PurchaseModel>('purchaseBox');
    }
  }

  static Future<bool> isInvoiceNumberExists(
    String invoiceNumber,
    TransactionType transactionType,
    dynamic subType,
  ) async {
    final box = await _getAppropriateBox(transactionType);

    return box.values.any((transaction) =>
        transaction.type == subType &&
        transaction.invoiceNumber == invoiceNumber);
  }
}
