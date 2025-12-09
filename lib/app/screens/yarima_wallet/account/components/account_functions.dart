
import 'package:account_book/app/data/helpers/category_text.dart';
import 'package:account_book/app/data/helpers/icon_helper.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';



class AccountFuntions {
  getIcon(TransactionModel transactions) {
    try {
      if (transactions.transactionType == TransactionType.transfer) {
        return 'assets/categories/swap-hori.png';
      } else {
        return CustomIcons()
            .getImagePathForCategory(transactions.categoryName!);
      }
    } catch (e) {
      debugPrint('Error while getting icon: $e');
      return Icons.error;
    }
  }

  Widget transactionType(TransactionModel transactions) {
    try {
      if (transactions.transactionType == TransactionType.transfer) {
        return Expanded(
          child: Row(
            children: [
              Flexible(child: Text(transactions.fromAccount)),
              const Icon(Icons.arrow_right_alt),
              Flexible(child: Text(transactions.toAccount)),
            ],
          ),
        );
      } else {
        return Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  overflow: TextOverflow.ellipsis,
                  getCategoryText(transactions),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error while getting transaction type: $e');
      return const Text('Unknown');
    }
  }

  double calculateAccountBalance(
    Set<TransactionModel> transactions,
    Set<AttendanceModel> attendanceTransactions,
    String fromAccount,
    String toAccount,
    Map<String, dynamic>? categoryData,
  ) {
    try {
      double balance =
          categoryData != null ? categoryData['initialAmount'] ?? 0 : 0;

      for (final transaction in transactions) {
        if (transaction.transactionType == TransactionType.payment) {
          balance -= transaction.amount;
        } else if (transaction.transactionType == TransactionType.receipt) {
          balance += transaction.amount;
        } else if (transaction.transactionType == TransactionType.transfer) {
          if (transaction.fromAccount == fromAccount) {
            balance -= transaction.amount;
          } else if (transaction.toAccount == toAccount) {
            balance += transaction.amount;
          }
        }
      }

      for (final attendance in attendanceTransactions) {
        balance -= attendance.payment;
      }

      return balance;
    } catch (e) {
      debugPrint('Error while calculating account balance: $e');
      rethrow; // Rethrow the error instead of returning 0
    }
  }

  double calculateTotalPaymentAmountForAccounts(
    List<TransactionModel> transactions,
    String fromAccount,
    String toAccount,
    DateTime month,
  ) {
    double totalPayment = 0.0;
    for (var transaction in transactions) {
      if (transaction.date.year == month.year &&
          transaction.date.month == month.month) {
        if (transaction.transactionType == TransactionType.payment) {
          if (transaction.fromAccount == fromAccount ||
              transaction.toAccount == toAccount) {
            totalPayment += transaction.amount;
          }
        } else if (transaction.transactionType == TransactionType.transfer) {
          if (transaction.fromAccount == fromAccount) {
            totalPayment += transaction.amount;
          }
        }
      }
    }
    return totalPayment;
  }

  double calculateTotalReceiptAmountForAccounts(
    List<TransactionModel> transactions,
    String fromAccount,
    String toAccount,
    DateTime month,
  ) {
    double totalReceipt = 0.0;
    for (var transaction in transactions) {
      if (transaction.date.year == month.year &&
          transaction.date.month == month.month) {
        if (transaction.transactionType == TransactionType.receipt) {
          if (transaction.fromAccount == fromAccount ||
              transaction.toAccount == toAccount) {
            totalReceipt += transaction.amount;
          }
        } else if (transaction.transactionType == TransactionType.transfer) {
          if (transaction.toAccount == toAccount) {
            totalReceipt += transaction.amount;
          }
        }
      }
    }
    return totalReceipt;
  }

  List<AttendanceModel> getAttendanceTransactions(
    Box<AttendanceModel> attendanceBox,
    String account,
    String subAccount,
    String categoryName,
    String accountName,
    DateTime selectedMonth,
  ) {
    try {
      final attendanceTransactions = <AttendanceModel>[];
      for (final attendance in attendanceBox.values) {
        if (attendance.account == account ||
            attendance.subName == subAccount ||
            attendance.categoryName == categoryName ||
            attendance.name == accountName) {
          // Check if the attendance date falls within the selected month
          if (attendance.date.year == selectedMonth.year &&
              attendance.date.month == selectedMonth.month) {
            attendanceTransactions.add(attendance);
          }
        }
      }
      return attendanceTransactions;
    } catch (e) {
      debugPrint('Error while getting attendance transactions: $e');
      return [];
    }
  }

  List<TransactionModel> getTransactionsOfAccounts(
    DateTime selectedMonth,
    Box<TransactionModel> transactionBox,
    List<TransactionType> types,
    String fromAccount,
    String toAccount,
  ) {
    try {
      final transactions = <TransactionModel>[];

      for (final transaction in transactionBox.values) {
        if (types.contains(transaction.transactionType) &&
            ((transaction.fromAccount == fromAccount) ||
                (transaction.toAccount == toAccount))) {
          // Check if the transaction's date falls within the selected month
          if ((transaction.date.year == selectedMonth.year &&
                  transaction.date.month == selectedMonth.month) ||
              // Also include transactions from previous and next years
              (transaction.date.year < selectedMonth.year ||
                  transaction.date.month < selectedMonth.month) ||
              (transaction.date.year > selectedMonth.year ||
                  transaction.date.month > selectedMonth.month)) {
            transactions.add(transaction);
          }
        }
      }
      return transactions;
    } catch (e) {
      debugPrint('Error while getting transactions of accounts: $e');
      return [];
    }
  }

  double calculateSubAccountBalance(
    Set<TransactionModel> transactions,
    Set<AttendanceModel> attendanceTransactions,
    String mainAccount,
    String subAccount,
    Map<String, dynamic>? subAccountData,
  ) {
    try {
      double balance =
          subAccountData != null ? subAccountData['initialAmount'] ?? 0 : 0;

      for (final transaction in transactions) {
        if (transaction.fromAccount == '$mainAccount/$subAccount') {
          if (transaction.transactionType == TransactionType.payment) {
            balance -= transaction.amount;
          } else if (transaction.transactionType == TransactionType.transfer) {
            balance -= transaction.amount;
          }
        } else if (transaction.toAccount == '$mainAccount/$subAccount') {
          if (transaction.transactionType == TransactionType.receipt) {
            balance += transaction.amount;
          } else if (transaction.transactionType == TransactionType.transfer) {
            balance += transaction.amount;
          }
        }
      }

      for (final attendance in attendanceTransactions) {
        if (attendance.account == '$mainAccount/$subAccount') {
          balance -= attendance.payment;
        }
      }

      return balance;
    } catch (e) {
      debugPrint('Error while calculating sub-account balance: $e');
      rethrow;
    }
  }

  List<TransactionModel> getSubAccountTransactions(
    DateTime selectedMonth,
    Box<TransactionModel> transactionBox,
    List<TransactionType> types,
    String mainAccount,
    String subAccount,
  ) {
    try {
      final transactions = <TransactionModel>[];
      final fullAccountName = '$mainAccount/$subAccount';

      for (final transaction in transactionBox.values) {
        if (types.contains(transaction.transactionType) &&
            ((transaction.fromAccount == fullAccountName) ||
                (transaction.toAccount == fullAccountName))) {
          if ((transaction.date.year == selectedMonth.year &&
                  transaction.date.month == selectedMonth.month) ||
              (transaction.date.year < selectedMonth.year ||
                  transaction.date.month < selectedMonth.month) ||
              (transaction.date.year > selectedMonth.year ||
                  transaction.date.month > selectedMonth.month)) {
            transactions.add(transaction);
          }
        }
      }
      return transactions;
    } catch (e) {
      debugPrint('Error while getting sub-account transactions: $e');
      return [];
    }
  }
}
