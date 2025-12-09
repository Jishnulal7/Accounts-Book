import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';

class TransactionRepository {
  static const String _boxName = 'transactions';
  late Box<TransactionModel> box;

  Future<void> init() async {
    box = await Hive.openBox<TransactionModel>(_boxName);
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    return box.values.toList();
  }

  Future<List<TransactionModel>> getTransactionsForDay(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return box.values
        .where((transaction) =>
            DateFormat('yyyy-MM-dd').format(transaction.date) == dateKey)
        .toList();
  }

  Future<List<TransactionModel>> getTransactionsForMonth(DateTime date) async {
    final monthKey = DateFormat('yyyy-MM').format(date);
    return box.values
        .where((transaction) =>
            DateFormat('yyyy-MM').format(transaction.date) == monthKey)
        .toList();
  }

  Future<List<TransactionModel>> getTransactionsForYear(int year) async {
    return box.values
        .where((transaction) => transaction.date.year == year)
        .toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await box.add(transaction);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await box.put(transaction.id, transaction);
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    await box.delete(transaction.key);
  }

  Future<void> deleteTransactionsForDay(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final keysToDelete = box.values
        .where((transaction) =>
            DateFormat('yyyy-MM-dd').format(transaction.date) == dateKey)
        .map((transaction) => transaction.key)
        .toList();
    await box.deleteAll(keysToDelete);
  }

  Map<String, List<TransactionModel>> groupTransactionsByDay(
      List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> transactionsByDay = {};
    for (final transaction in transactions) {
      final dayKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      transactionsByDay.putIfAbsent(dayKey, () => []);
      if (!transactionsByDay[dayKey]!.contains(transaction)) {
        transactionsByDay[dayKey]!.add(transaction);
      }
    }
    return transactionsByDay;
  }

  Map<String, List<TransactionModel>> groupTransactionsByMonth(
      List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> transactionsByMonth = {};
    for (final transaction in transactions) {
      final monthKey = DateFormat('yyyy-MM').format(transaction.date);
      transactionsByMonth.putIfAbsent(monthKey, () => []);
      if (!transactionsByMonth[monthKey]!.contains(transaction)) {
        transactionsByMonth[monthKey]!.add(transaction);
      }
    }
    return transactionsByMonth;
  }
}
