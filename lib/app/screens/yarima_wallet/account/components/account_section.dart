// ignore_for_file: depend_on_referenced_packages
import 'package:account_book/app/data/helpers/color_helper.dart';
import 'package:account_book/app/data/helpers/icon_helper.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_functions.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_helper.dart';
import 'package:hive_ce/hive.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'account_tile.dart';
import 'package:collection/collection.dart';

class AccountSection extends StatefulWidget {
  const AccountSection({
    required this.transactionBox,
    required this.selectedMonth,
    super.key,
    this.onAccountAdded,
    required this.attendanceBox,
  });

  final Box<TransactionModel> transactionBox;
  final Box<AttendanceModel> attendanceBox;
  final DateTime selectedMonth;
  final VoidCallback? onAccountAdded;

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  final accountModel = AccountHelper();
  final StreamController<void> _accountChangesController =
      StreamController<void>.broadcast();
  late Stream<void> _combinedStream;
  @override
  void initState() {
    super.initState();
    accountModel.initializeDefaultAccounts();
    _combinedStream = Rx.merge([
      widget.transactionBox.watch().map((_) {}),
      widget.attendanceBox.watch().map((_) {}),
    ]);
  }

  @override
  void dispose() {
    _accountChangesController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _combinedStream,
      builder: (context, snapshot) {
        return _buildAccountSection(
          'Accounts',
          widget.transactionBox,
          widget.attendanceBox,
          ColorHelper().darkorWhite(context),
          accountModel,
          AccountHelper().allTransactionTypes,
        );
      },
    );
  }

  Widget _buildAccountSection(
    String title,
    Box<TransactionModel> transactionBox,
    Box<AttendanceModel> attendanceBox,
    Color color,
    AccountHelper accountModel,
    List<TransactionType> allTransactionTypes,
  ) {
    return StreamBuilder<void>(
      stream: _accountChangesController.stream,
      builder: (context, snapshot) {
        final List<Map<String, dynamic>> accounts = [];

        final box = GetStorage('accounts');
        final keys = box.getKeys();
        for (final key in keys) {
          final data = box.read(key);

          accounts.add({
            'name': key,
            'imagePath':
                data['imagePath'] ?? CustomIcons().getImagePathForAccounts(key),
            'initialAmount': data['initialAmount'] ?? 0.0,
            'subAccount': data['subAccount'] ?? [],
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: accounts.map<Widget>(
                (accountData) {
                  try {
                    final List<TransactionModel> allTransactions = [];
                    final List<AttendanceModel> allAttendanceTransactions = [];

                    for (int i = 0; i <= widget.selectedMonth.month; i++) {
                      final transactionsFromAccount =
                          AccountFuntions().getTransactionsOfAccounts(
                        DateTime(widget.selectedMonth.year, i + 1),
                        transactionBox,
                        allTransactionTypes,
                        accountData['name'],
                        accountData['name'],
                      );

                      allTransactions.addAll(transactionsFromAccount);
                    }
                    for (int i = 0; i <= widget.selectedMonth.month; i++) {
                      // Fetch all attendance records for the current month
                      final monthAttendance = attendanceBox.values
                          .where((attendance) =>
                              attendance.date.year ==
                                  widget.selectedMonth.year &&
                              attendance.date.month == i + 1 &&
                              attendance.account == accountData['name'])
                          .toList();

                      // Group attendance records by name, subName, and categoryName
                      final groupedAttendance = groupBy(
                          monthAttendance,
                          (AttendanceModel a) =>
                              '${a.name}|${a.subName}|${a.categoryName}');

                      // Process each group
                      groupedAttendance.forEach((key, attendanceList) {
                        final parts = key.split('|');
                        final name = parts[0];
                        final subName = parts[1];
                        final categoryName = parts[2];

                        final attendanceFromAccount =
                            AccountFuntions().getAttendanceTransactions(
                          attendanceBox,
                          accountData['name'],
                          name,
                          subName,
                          categoryName,
                          DateTime(widget.selectedMonth.year, i + 1),
                        );
                        allAttendanceTransactions.addAll(attendanceFromAccount);
                      });
                    }
                    double balance = AccountFuntions().calculateAccountBalance(
                      allTransactions.toSet(),
                      allAttendanceTransactions.toSet(),
                      accountData['name'],
                      accountData['name'],
                      accountData,
                    );

                    // Add initial amount to the balance
                    balance += (accountData['initialAmount'] ?? 0.0);

                    bool isDefaultAccount = accountModel.accountCategories.any(
                        (element) => element['name'] == accountData['name']);

                    return AccountListTile(
                      accountData: accountData,
                      balance: balance,
                      isDefaultAccount: isDefaultAccount,
                      transactionBox: transactionBox,
                      color: color,
                      selectedMonth: widget.selectedMonth,
                      onAccountAdded: widget.onAccountAdded,
                      attendanceBox: attendanceBox,
                      subcategories: accountData['subAccount'] ?? [],
                    );
                  } catch (e) {
                    debugPrint('Error while mapping account: $e');
                    return const SizedBox.shrink();
                  }
                },
              ).toList(),
            ),
          ],
        );
      },
    );
  }
}
