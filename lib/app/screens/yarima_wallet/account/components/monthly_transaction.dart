import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/color_helper.dart';
import 'package:account_book/app/data/helpers/enums/toast.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_functions.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_transaction_card.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/attendance_transaction_card.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/edit_attendance.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/dailytab.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/monthlytab.dart';
import 'package:account_book/app/screens/yarima_wallet/transaction/edit_transactions.dart';
import 'package:account_book/app/widgets/custom_confirmation.dart';
import 'package:account_book/app/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MonthlyTransaction extends StatelessWidget {
  const MonthlyTransaction({
    super.key,
    required this.month,
    required this.totalPaymentAmount,
    required this.totalReceiptAmount,
    required this.balance,
    required this.transactionsForMonth,
    required this.color,
    required this.selectedMonth,
    required this.transactionBox,
    required this.attendanceForMonth,
    required this.attendanceBox,
  });

  final String month;
  final double totalPaymentAmount;
  final double totalReceiptAmount;
  final double balance;
  final List<TransactionModel> transactionsForMonth;
  final Color color;
  final DateTime selectedMonth;
  final Box<TransactionModel> transactionBox;
  final List<AttendanceModel> attendanceForMonth;
  final Box<AttendanceModel> attendanceBox;

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.topCenter,
              child: Text(
                month,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              dense: true,
              title: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '⬆ $currencySymbol${totalPaymentAmount.toStringAsFixed(1)}',
                        style: TextStyle(color: AppColor.kRed),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '⬇ $currencySymbol${totalReceiptAmount.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: AppColor.kGreen,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Balance: $currencySymbol ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ColorHelper().darkorWhite(context),
                            fontSize: 13,
                          ),
                        ),
                        TextSpan(
                          text: balance.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColor.kPurple,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: color),
            Column(
              children: [
                ...transactionsForMonth.map<Widget>(
                  (transaction) =>
                      _buildTransactionListTile(context, transaction),
                ),
                ...attendanceForMonth.map<Widget>(
                  (attendance) => _buildAttendanceListTile(context, attendance),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionListTile(
      BuildContext context, TransactionModel transaction) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return GestureDetector(
      onTap: () {
        _accountTransactionCard(context, transaction.key, color);
      },
      child: ListTile(
        dense: true,
        leading: Image.asset(
          width: 30,
          AccountFuntions().getIcon(transaction),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AccountFuntions().transactionType(transaction),
            Text(
              '$currencySymbol${transaction.amount.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 16,
                color: ColorHelper().color(transaction),
              ),
            ),
          ],
        ),
        trailing: Text(
          DateFormat('dd MMM').format(transaction.date),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: AppColor.kGrayscale100,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceListTile(
      BuildContext context, AttendanceModel attendance) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AttendanceTransactionCard(
              attendance: attendance,
              color: Colors.blue,
              onEdit: () => _editAttendance(context, attendance),
              onDelete: () => _deleteAttendance(context, attendance),
              isEditable: true,
            );
          },
        );
      },
      child: ListTile(
        dense: true,
        leading: Image.asset(
          'assets/categories/profile.png',
          width: 30,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(attendance.subName),
            Text(
              '$currencySymbol${attendance.payment.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 16,
                color: AppColor.kRed, // Assuming attendance is always a payment
              ),
            ),
          ],
        ),
        trailing: Text(
          DateFormat('dd MMM').format(attendance.date),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: AppColor.kGrayscale100,
          ),
        ),
      ),
    );
  }

  void _accountTransactionCard(
      BuildContext context, dynamic transactionKey, Color color) {
    try {
      showDialog(
        context: context,
        builder: (context) => StreamBuilder<BoxEvent>(
          stream: transactionBox.watch(key: transactionKey),
          builder: (context, snapshot) {
            final transaction = transactionBox.get(transactionKey);
            if (transaction == null) {
              Navigator.of(context).pop();
              return const SizedBox.shrink();
            }
            return AccountTransactionCard(
              transaction: transaction,
              color: color,
              onEdit: () => _editTransactions(context, transaction),
              onDelete: () => _deleteTransactions(context, transaction),
              isEditable: true,
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('Error while opening dialog window: $e');
    }
  }

  void _deleteTransactions(BuildContext context, TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return ConfirmationDialog(
          title: 'Delete Transaction',
          content: 'Are you sure you want to delete this transaction?',
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () {
            _deleteTransactionsFromHive(transaction);
            Navigator.of(context).pop(true);
          },
          confirmButtonText: 'Delete',
          cancelButtonText: 'Cancel',
        );
      },
    );
  }

  void _deleteTransactionsFromHive(TransactionModel transaction) {
    try {
      transactionBox.delete(transaction.key);
      dailyTabKey.currentState?.loadTransactions();
      monthlyTabKey.currentState?.loadTransactionsAndAttendanceFromHive();
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
    }
  }

  void _editTransactions(BuildContext context, TransactionModel transaction) {
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: EditScreen(
            transaction: transaction,
            selectedDailyDate: selectedMonth,
            transactionBox: transactionBox,
          ),
        ),
      ).then((updatedTransaction) {
        if (updatedTransaction != null) {
          transactionBox.put(updatedTransaction.key, updatedTransaction);
          dailyTabKey.currentState?.loadTransactions();
          monthlyTabKey.currentState?.loadTransactionsAndAttendanceFromHive();
        }
      });
    } catch (e) {
      debugPrint('Error editing transaction: $e');
    }
  }

  void _deleteAttendance(BuildContext context, AttendanceModel attendance) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Attendance',
        content: 'Are you sure you want to delete this attendance record?',
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () async {
          await attendanceBox.delete(attendance.key);

          Navigator.of(context).pop();

          ToastService.show(
            context,
            message: 'Attendance deleted successfully',
            type: ToastType.success,
          );
        },
        confirmButtonText: 'Delete',
        cancelButtonText: 'Cancel',
      ),
    );
  }

  void _editAttendance(BuildContext context, AttendanceModel attendance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: EditAttendanceScreen(
          attendance: attendance,
          onSave: (updatedAttendance) async {
            await attendanceBox.put(updatedAttendance.key, updatedAttendance);

            Navigator.of(context).pop();

            ToastService.show(
              context,
              message: 'Attendance updated successfully',
              type: ToastType.success,
            );
          },
          selectedDailyDate: selectedMonth,
          transactionBox: transactionBox,
        ),
      ),
    );
  }
}
