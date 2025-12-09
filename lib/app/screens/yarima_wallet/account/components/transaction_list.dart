import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_functions.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/monthly_transaction.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({
    super.key,
    required this.sortedMonths,
    required this.allTransactions,
    required this.fromAccount,
    required this.toAccount,
    required this.color,
    required this.selectedMonth,
    required this.transactionBox,
    required this.attendanceBox,
    required this.allAttendanceTransactions,
  });

  final List<String> sortedMonths;
  final Set<TransactionModel> allTransactions;
  final Set<AttendanceModel> allAttendanceTransactions;
  final String fromAccount;
  final String toAccount;
  final Color color;
  final DateTime selectedMonth;
  final Box<TransactionModel> transactionBox;
  final Box<AttendanceModel> attendanceBox;

  @override
  Widget build(BuildContext context) {
    final allMonths = _getAllMonths();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allMonths
          .map<Widget>(
            (month) {
              final DateTime monthDate = DateFormat('MMMM yyyy').parse(month);
              final transactionsForMonth = allTransactions
                  .where((transaction) =>
                      transaction.date.year == monthDate.year &&
                      transaction.date.month == monthDate.month)
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));
              final attendanceForMonth = allAttendanceTransactions
                  .where((attendance) =>
                      attendance.date.year == monthDate.year &&
                      attendance.date.month == monthDate.month)
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

              // Only create a MonthlyTransaction if there are transactions or attendance records
              if (transactionsForMonth.isNotEmpty ||
                  attendanceForMonth.isNotEmpty) {
                final double totalPaymentAmount = AccountFuntions()
                    .calculateTotalPaymentAmountForAccounts(
                        transactionsForMonth,
                        fromAccount,
                        toAccount,
                        monthDate);
                final double totalReceiptAmount = AccountFuntions()
                    .calculateTotalReceiptAmountForAccounts(
                        transactionsForMonth,
                        fromAccount,
                        toAccount,
                        monthDate);
                final double totalAttendancePayment = attendanceForMonth
                    .map((attendance) => attendance.payment)
                    .fold(0, (prev, amount) => prev + amount);
                final double balance = totalReceiptAmount -
                    totalPaymentAmount -
                    totalAttendancePayment;

                return MonthlyTransaction(
                  month: month,
                  totalPaymentAmount:
                      totalPaymentAmount + totalAttendancePayment,
                  totalReceiptAmount: totalReceiptAmount,
                  balance: balance,
                  transactionsForMonth: transactionsForMonth,
                  color: color,
                  selectedMonth: selectedMonth,
                  transactionBox: transactionBox,
                  attendanceForMonth: attendanceForMonth,
                  attendanceBox: attendanceBox,
                );
              } else {
                return const SizedBox
                    .shrink(); // Return an empty widget if no data for this month
              }
            },
          )
          .whereType<MonthlyTransaction>()
          .toList(), // Filter out empty widgets
    );
  }

  List<String> _getAllMonths() {
    final Set<DateTime> allDates = {};

    // Add dates from transactions
    allDates.addAll(
        allTransactions.map((t) => DateTime(t.date.year, t.date.month)));

    // Add dates from attendance records
    allDates.addAll(allAttendanceTransactions
        .map((a) => DateTime(a.date.year, a.date.month)));

    final sortedDates = allDates.toList()..sort((a, b) => b.compareTo(a));
    return sortedDates
        .map((date) => DateFormat('MMMM yyyy').format(date))
        .toList();
  }
}
