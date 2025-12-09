import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/payment_model.dart';
import 'package:account_book/app/data/model/receipt_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/data/model/transfer_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';

class CalculationManager {
  // Cache formatters to avoid recreating them
  final DateFormat _monthYearFormatter = DateFormat('yyyy-MM');
  final DateFormat _fullDateFormatter = DateFormat('yyyy-MM-dd');
  final DateFormat _monthNameFormatter = DateFormat('MMMM yyyy');

  // Constants
  static const String _cashAccount = 'Cash';

  // Group transactions by month from transactions grouped by date
  Map<String, List<TransactionModel>> groupTransactionsByMonth(
      Map<String, List<TransactionModel>> transactionsByDate) {
    try {
      final Map<String, List<TransactionModel>> transactionsByMonth = {};

      transactionsByDate.forEach((dateKey, transactions) {
        final monthYear =
            _monthYearFormatter.format(_fullDateFormatter.parse(dateKey));

        transactionsByMonth.putIfAbsent(monthYear, () => []);
        transactionsByMonth[monthYear]!.addAll(transactions);
      });
      return transactionsByMonth;
    } catch (e) {
      debugPrint('Error grouping transactions by month: $e');
      return {};
    }
  }

  // Group transactions by date
  Map<String, List<TransactionModel>> groupTransactionsByDate(
      List<TransactionModel> transactions) {
    try {
      final Map<String, List<TransactionModel>> transactionsByDate = {};

      for (final transaction in transactions) {
        final dateKey = _fullDateFormatter.format(transaction.date);
        transactionsByDate.putIfAbsent(dateKey, () => []);
        transactionsByDate[dateKey]!.add(transaction);
      }

      return transactionsByDate;
    } catch (e) {
      debugPrint('Error grouping transactions by date: $e');
      return {};
    }
  }

  // Helper method to truncate DateTime to day precision
  DateTime _truncateToDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Calculate balance for a specific day
  double calculateBalanceForDay(
    DateTime selectedDate,
    double openingBalance,
    Box<TransactionModel> transactionBox,
    Box<AttendanceModel> attendanceBox,
  ) {
    try {
      double balance = openingBalance;
      final truncatedSelectedDate = _truncateToDay(selectedDate);

      // Process transactions
      _processTransactionsForBalance(
          transactionBox.values,
          truncatedSelectedDate,
          (transaction) =>
              balance += _getTransactionBalanceImpact(transaction));

      // Process attendance payments
      _processAttendanceForBalance(attendanceBox.values, truncatedSelectedDate,
          (attendance) => balance -= attendance.payment);

      return balance;
    } catch (e) {
      debugPrint('Error calculating balance for date: $e');
      return openingBalance;
    }
  }

  // Helper method to process transactions for balance calculation
  void _processTransactionsForBalance(Iterable<TransactionModel> transactions,
      DateTime truncatedDate, Function(TransactionModel) processTransaction) {
    for (final transaction in transactions) {
      final truncatedTransactionDate = _truncateToDay(transaction.date);

      if (truncatedTransactionDate
              .isBefore(truncatedDate.add(const Duration(days: 1))) ||
          truncatedTransactionDate.isAtSameMomentAs(truncatedDate)) {
        processTransaction(transaction);
      }
    }
  }

  // Helper method to process attendance records for balance calculation
  void _processAttendanceForBalance(Iterable<AttendanceModel> attendanceRecords,
      DateTime truncatedDate, Function(AttendanceModel) processAttendance) {
    for (final attendance in attendanceRecords) {
      final truncatedAttendanceDate = _truncateToDay(attendance.date);

      if (truncatedAttendanceDate
              .isBefore(truncatedDate.add(const Duration(days: 1))) ||
          truncatedAttendanceDate.isAtSameMomentAs(truncatedDate)) {
        processAttendance(attendance);
      }
    }
  }

  // Helper to calculate balance impact based on transaction type
  double _getTransactionBalanceImpact(TransactionModel transaction) {
    if (transaction.transactionType == TransactionType.receipt) {
      return transaction.amount;
    } else if (transaction.transactionType == TransactionType.payment) {
      return -transaction.amount;
    }
    return 0.0; // Transfers don't affect balance
  }

  // Calculate balance for an entire month
  double calculateBalanceForMonth(
    DateTime month,
    double openingBalance,
    Box<TransactionModel> transactionBox,
    Box<AttendanceModel> attendanceBox,
  ) {
    try {
      final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
      // Just calculate the balance for the last day of the month
      return calculateBalanceForDay(
          lastDayOfMonth, openingBalance, transactionBox, attendanceBox);
    } catch (e) {
      debugPrint('Error calculating balance for month: $e');
      return openingBalance;
    }
  }

  // Calculate previous month balance
  double calculatePreviousMonthBalance(
    DateTime month,
    double openingBalance,
    Box<TransactionModel> transactionBox,
    Box<AttendanceModel> attendanceBox,
  ) {
    try {
      final previousMonthEndDate = DateTime(month.year, month.month, 0);
      return calculateBalanceForDay(
          previousMonthEndDate, openingBalance, transactionBox, attendanceBox);
    } catch (e) {
      debugPrint('Error calculating previous month balance: $e');
      return openingBalance;
    }
  }

  // Calculate yearly data summaries
  Map<String, Map<String, double>> calculateYearlyData(
    Map<String, List<TransactionModel>> transactionsByMonth,
    double openingBalance,
    Box<TransactionModel> transactionBox,
    Box<AttendanceModel> attendanceBox,
  ) {
    try {
      final Map<String, Map<String, double>> yearlyData = {};

      for (var monthData in transactionsByMonth.entries) {
        if (monthData.value.isNotEmpty) {
          final DateTime monthDate = monthData.value[0].date;
          final String month = _monthNameFormatter.format(monthDate);

          yearlyData[month] = {
            'totalReceipts':
                calculateTotalReceiptAmountForMonth(monthDate, transactionBox),
            'totalPayments': calculateTotalPaymentAmountForMonth(
                monthDate, transactionBox, attendanceBox),
            'totalTransfers':
                calculateTotalTransferAmountForMonth(monthDate, transactionBox),
            'balance': calculateBalanceForMonth(
                monthDate, openingBalance, transactionBox, attendanceBox),
            'closingBalance': calculatePreviousMonthBalance(
                monthDate, openingBalance, transactionBox, attendanceBox)
          };
        }
      }

      return yearlyData;
    } catch (e) {
      debugPrint('Error calculating yearly data: $e');
      return {};
    }
  }

  // Helper method to filter transactions by date and type
  List<TransactionModel> _filterTransactionsByDateAndType(
      Iterable<TransactionModel> transactions,
      DateTime date,
      TransactionType type,
      {bool matchDay = true,
      bool matchMonth = true,
      bool matchYear = true}) {
    return transactions.where((transaction) {
      bool dateMatch = true;
      if (matchYear) {
        dateMatch = dateMatch && transaction.date.year == date.year;
      }
      if (matchMonth) {
        dateMatch = dateMatch && transaction.date.month == date.month;
      }
      if (matchDay) dateMatch = dateMatch && transaction.date.day == date.day;

      return dateMatch && transaction.transactionType == type;
    }).toList();
  }

  // Daily totals calculation methods
  double calculateTotalPaymentAmount(
      DateTime selectedDailyDate, Box<TransactionModel> transactionBox) {
    try {
      return transactionBox.values
          .where((transaction) =>
              _fullDateFormatter.format(transaction.date) ==
                  _fullDateFormatter.format(selectedDailyDate) &&
              transaction.transactionType == TransactionType.payment)
          .fold(0.0, (total, transaction) => total + transaction.amount);
    } catch (e) {
      debugPrint('Error calculating total payment amount: $e');
      return 0.0;
    }
  }

  double calculateTotalReceiptAmount(
      DateTime selectedDailyDate, Box<TransactionModel> transactionBox) {
    try {
      return transactionBox.values
          .where((transaction) =>
              _fullDateFormatter.format(transaction.date) ==
                  _fullDateFormatter.format(selectedDailyDate) &&
              transaction.transactionType == TransactionType.receipt)
          .fold(0.0, (total, transaction) => total + transaction.amount);
    } catch (e) {
      debugPrint('Error calculating total receipt amount: $e');
      return 0.0;
    }
  }

  // Monthly totals calculation methods
  double calculateTotalPaymentAmountForMonth(
    DateTime selectedMonth,
    Box<TransactionModel> transactionBox,
    Box<AttendanceModel> attendanceBox,
  ) {
    try {
      // Calculate payments from transactions
      final double transactionPayments = _filterTransactionsByDateAndType(
              transactionBox.values, selectedMonth, TransactionType.payment,
              matchDay: false)
          .fold(0.0, (total, transaction) => total + transaction.amount);

      // Calculate payments from attendance
      final double attendancePayments = attendanceBox.values
          .where((attendance) =>
              attendance.date.month == selectedMonth.month &&
              attendance.date.year == selectedMonth.year)
          .fold(0.0, (total, attendance) => total + attendance.payment);

      return transactionPayments + attendancePayments;
    } catch (e) {
      debugPrint('Error calculating total payment amount for month: $e');
      return 0.0;
    }
  }

  double calculateTotalReceiptAmountForMonth(
      DateTime selectedMonth, Box<TransactionModel> transactionBox) {
    try {
      return _filterTransactionsByDateAndType(
              transactionBox.values, selectedMonth, TransactionType.receipt,
              matchDay: false)
          .fold(0.0, (total, transaction) => total + transaction.amount);
    } catch (e) {
      debugPrint('Error calculating total receipt amount for month: $e');
      return 0.0;
    }
  }

  double calculateTotalTransferAmountForMonth(
      DateTime selectedMonth, Box<TransactionModel> transactionBox) {
    try {
      return _filterTransactionsByDateAndType(
              transactionBox.values, selectedMonth, TransactionType.transfer,
              matchDay: false)
          .fold(0.0, (total, transaction) => total + transaction.amount);
    } catch (e) {
      debugPrint('Error calculating total transfer amount for month: $e');
      return 0.0;
    }
  }

  // Get transaction lists methods
  // These methods convert TransactionModel to specific transaction types
  List<Payment> getPaymentsForMonth(
      DateTime selectedMonth, Box<TransactionModel> transactionBox) {
    try {
      return _filterTransactionsByDateAndType(
              transactionBox.values, selectedMonth, TransactionType.payment,
              matchDay: false)
          .map(_convertToPayment)
          .toList();
    } catch (e) {
      debugPrint('Error getting payments for month: $e');
      return [];
    }
  }

  List<Payment> getPaymentsForYear(
      DateTime selectedYear, Box<TransactionModel> transactionBox) {
    try {
      return _filterTransactionsByDateAndType(
              transactionBox.values, selectedYear, TransactionType.payment,
              matchDay: false, matchMonth: false)
          .map(_convertToPayment)
          .toList();
    } catch (e) {
      debugPrint('Error getting payments for year: $e');
      return [];
    }
  }

  // Helper method to convert TransactionModel to Payment
  Payment _convertToPayment(TransactionModel transaction) {
    return Payment(
      subCategory: transaction.subCategory,
      id: transaction.id,
      amount: transaction.amount,
      description: transaction.description,
      categoryName: transaction.categoryName,
      date: transaction.date,
      transactionType: TransactionType.payment,
      iconData: transaction.iconData,
      fromAccount: transaction.fromAccount,
      toAccount: transaction.toAccount,
      fromAccountImagePath: transaction.fromAccountImagePath,
      toAccountImagePath: transaction.toAccountImagePath,
      generalCategory: transaction.generalCategory,
      generalSubCategory: transaction.generalSubCategory,
      fromSubAccount: transaction.fromSubAccount,
      toSubAccount: transaction.toSubAccount,
    );
  }

  List<Receipt> getReceiptsForMonth(
      DateTime selectedMonth, Box<TransactionModel> transactionBox) {
    try {
      return _filterTransactionsByDateAndType(
              transactionBox.values, selectedMonth, TransactionType.receipt,
              matchDay: false)
          .map(_convertToReceipt)
          .toList();
    } catch (e) {
      debugPrint('Error getting receipts for month: $e');
      return [];
    }
  }

  List<Receipt> getReceiptsForYear(
      DateTime selectedYear, Box<TransactionModel> transactionBox) {
    try {
      return _filterTransactionsByDateAndType(
              transactionBox.values, selectedYear, TransactionType.receipt,
              matchDay: false, matchMonth: false)
          .map(_convertToReceipt)
          .toList();
    } catch (e) {
      debugPrint('Error getting receipts for year: $e');
      return [];
    }
  }

  // Helper method to convert TransactionModel to Receipt
  Receipt _convertToReceipt(TransactionModel transaction) {
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

  // Get transactions for a specific day
  List<Receipt> getReceiptsFromHive(
      Box<dynamic> monthlyTransactionBox, DateTime selectedDate) {
    try {
      final receipts = <Receipt>[];

      for (final transaction in monthlyTransactionBox.values) {
        if (transaction is TransactionModel &&
            transaction.transactionType == TransactionType.receipt &&
            _isSameDay(transaction.date, selectedDate)) {
          receipts.add(_convertToReceipt(transaction));
        }
      }

      return receipts;
    } catch (e) {
      debugPrint('Error getting receipts from Hive: $e');
      return [];
    }
  }

  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  List<AttendanceModel> getAttendanceTransactionsFromHive(
      Box<dynamic> attendanceBox, DateTime selectedDate) {
    try {
      return attendanceBox.values
          .whereType<AttendanceModel>()
          .where((attendance) =>
              _isSameDay(attendance.date, selectedDate) &&
              attendance.payment >= 0 &&
              attendance.subName.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error getting attendance transactions: $e');
      return [];
    }
  }

  // Helper method to convert TransactionModel to Transfer
  Transfer _convertToTransfer(TransactionModel transaction) {
    return Transfer(
      id: transaction.id,
      amount: transaction.amount,
      description: transaction.description,
      categoryName: transaction.categoryName,
      date: transaction.date,
      transactionType: TransactionType.transfer,
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

  List<Transfer> getTransfersFromHive(
      Box<dynamic> monthlyTransactionBox, DateTime selectedDate) {
    try {
      final transfers = <Transfer>[];

      for (final transaction in monthlyTransactionBox.values) {
        if (transaction is TransactionModel &&
            transaction.transactionType == TransactionType.transfer &&
            _isSameDay(transaction.date, selectedDate)) {
          transfers.add(_convertToTransfer(transaction));
        }
      }

      return transfers;
    } catch (e) {
      debugPrint('Error getting transfers from Hive: $e');
      return [];
    }
  }

  List<Transfer> getTransfersForMonth(
      Box<dynamic> monthlyTransactionBox, DateTime selectedDate) {
    try {
      final transfers = <Transfer>[];

      for (final transaction in monthlyTransactionBox.values) {
        if (transaction is TransactionModel &&
            transaction.transactionType == TransactionType.transfer &&
            transaction.date.year == selectedDate.year &&
            transaction.date.month == selectedDate.month) {
          transfers.add(_convertToTransfer(transaction));
        }
      }

      return transfers;
    } catch (e) {
      debugPrint('Error getting transfers for month: $e');
      return [];
    }
  }

  List<Transfer> getTransfersForYear(
      Box<dynamic> monthlyTransactionBox, DateTime selectedDate) {
    try {
      final transfers = <Transfer>[];

      for (final transaction in monthlyTransactionBox.values) {
        if (transaction is TransactionModel &&
            transaction.transactionType == TransactionType.transfer &&
            transaction.date.year == selectedDate.year) {
          transfers.add(_convertToTransfer(transaction));
        }
      }

      return transfers;
    } catch (e) {
      debugPrint('Error getting transfers for year: $e');
      return [];
    }
  }

  List<Payment> getPaymentsFromHive(
      Box<dynamic> monthlyTransactionBox, DateTime selectedDate) {
    try {
      final payments = <Payment>[];

      for (final transaction in monthlyTransactionBox.values) {
        if (transaction is TransactionModel &&
            transaction.transactionType == TransactionType.payment &&
            _isSameDay(transaction.date, selectedDate)) {
          payments.add(_convertToPayment(transaction));
        }
      }

      return payments;
    } catch (e) {
      debugPrint('Error getting payments from Hive: $e');
      return [];
    }
  }

  // Calculate cash account balance
  double calculateCashAccountBalance(
    Box<TransactionModel> transactionBox,
    DateTime selectedDate,
  ) {
    try {
      double balance = 0.0;
      _truncateToDay(selectedDate);

      final cashTransactions = transactionBox.values.where((transaction) =>
          _isSameDay(transaction.date, selectedDate) &&
          (transaction.fromAccount == _cashAccount ||
              transaction.toAccount == _cashAccount));

      for (final transaction in cashTransactions) {
        if (transaction.transactionType == TransactionType.payment) {
          if (transaction.fromAccount == _cashAccount) {
            balance -= transaction.amount;
          }
        } else if (transaction.transactionType == TransactionType.receipt) {
          if (transaction.toAccount == _cashAccount) {
            balance += transaction.amount;
          }
        } else if (transaction.transactionType == TransactionType.transfer) {
          if (transaction.fromAccount == _cashAccount) {
            balance -= transaction.amount;
          } else if (transaction.toAccount == _cashAccount) {
            balance += transaction.amount;
          }
        }
      }

      return balance;
    } catch (e) {
      debugPrint('Error calculating Cash account balance: $e');
      return 0.0;
    }
  }
}
