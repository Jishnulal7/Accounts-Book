import 'package:account_book/app/data/helpers/category_text.dart';
import 'package:account_book/app/data/helpers/icon_helper.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_helper.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_transaction_card.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/account_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/all_sub_account_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/sub_account_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/dailytab.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/monthlytab.dart';
import 'package:account_book/app/screens/yarima_wallet/transaction/edit_transactions.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


class AccountInfo extends StatefulWidget {
  const AccountInfo({
    super.key,
    required this.context,
    required this.account,
    required this.color,
    required this.balance,
    required this.transactionBox,
    required this.attendanceBox,
    required this.selectedMonth,
    required this.subcategories,
  });

  final BuildContext context;
  final Map<String, dynamic> account;
  final Color color;
  final double balance;
  final Box<TransactionModel> transactionBox;
  final Box<AttendanceModel> attendanceBox;
  final DateTime selectedMonth;
  final List<dynamic> subcategories;

  @override
  State<AccountInfo> createState() => _AccountInfoState();
}

class _AccountInfoState extends State<AccountInfo> {
  late String originalAccountName;
  late List<String> subAccount;

  @override
  void initState() {
    super.initState();
    originalAccountName = widget.account['name'];
    subAccount = widget.account['subAccount'] != null
        ? List<String>.from(widget.account['subAccount'])
        : [];
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: widget.color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    widget.account['imagePath'],
                    width: 35,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.account['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    // Adjust the end date to include the entire day
                    final adjustedEndDate = picked.end
                        .add(const Duration(days: 1))
                        .subtract(const Duration(seconds: 1));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return AccountPDFScreen(
                            accountName: widget.account['name'],
                            transactions: _filterTransactionsByDateRange(
                              picked.start,
                              adjustedEndDate,
                              widget.transactionBox.values.toList(),
                            ),
                            attendanceRecords: _filterAttendanceByDateRange(
                              picked.start,
                              adjustedEndDate,
                              widget.attendanceBox.values.toList(),
                            ),
                            startDate: picked.start,
                            endDate: adjustedEndDate,
                          );
                        },
                      ),
                    );
                  }
                },
                label: const Text('View PDF'),
                icon: const Icon(Icons.picture_as_pdf),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'Balance: ',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '$currencySymbol${widget.balance.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
          TextButton(
              onPressed: () {
                _showSubAccountDialog(context);
              },
              child: Text('View Sub Accounts')),
        ],
      ),
    );
  }

  List<TransactionModel> _filterTransactionsByDateRange(DateTime startDate,
      DateTime endDate, List<TransactionModel> transactions) {
    final adjustedEndDate = endDate.add(const Duration(days: 1));
    return transactions
        .where((transaction) =>
            (transaction.date.isAtSameMomentAs(startDate) ||
                transaction.date.isAfter(startDate)) &&
            transaction.date.isBefore(adjustedEndDate))
        .toList();
  }

  List<AttendanceModel> _filterAttendanceByDateRange(DateTime startDate,
      DateTime endDate, List<AttendanceModel> attendanceRecords) {
    final adjustedEndDate = endDate.add(const Duration(days: 1));
    return attendanceRecords
        .where((attendance) =>
            attendance.account == widget.account['name'] &&
            ((attendance.date.isAtSameMomentAs(startDate) ||
                    attendance.date.isAfter(startDate)) &&
                attendance.date.isBefore(adjustedEndDate)))
        .toList();
  }

  void _showSubAccountDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) {
          return Column(
            children: [
              AppBar(
                title: Text('${widget.account['name']} Sub Account'),
                actions: [
                  IconButton(
                    onPressed: () {
                      _showAddSubAccountDialog(context);
                    },
                    icon: const Icon(Icons.add),
                  ),
                  if ((widget.account['subAccount']?.length ?? 0) > 0)
                    IconButton(
                      onPressed: () {
                        generateAllSubAccountPDf();
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                    )
                ],
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: (widget.account['subAccount']?.isEmpty ?? true)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No sub accounts found',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showAddSubAccountDialog(context);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Sub Account'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: widget.account['subAccount']?.length ?? 0,
                        itemBuilder: (context, index) {
                          final subAccount =
                              widget.account['subAccount'][index];
                          return ListTile(
                            title: Text(subAccount),
                            onTap: () {
                              _showAccountTransactions(context, subAccount);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddSubAccountDialog(BuildContext context) {
    final TextEditingController subAccountController = TextEditingController();
    final accountHelper = AccountHelper();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sub Account'),
        content: TextField(
          controller: subAccountController,
          decoration: const InputDecoration(
            labelText: 'Sub Account Name',
            hintText: 'Enter sub account name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newSubAccount = subAccountController.text.trim();
              if (newSubAccount.isNotEmpty) {
                setState(() {
                  accountHelper.addSubAccount(
                      parentAccountName: originalAccountName,
                      subAccountName: newSubAccount);
                  widget.account['subAccount'].add(newSubAccount);
                });
                // Close both dialogs
                Navigator.pop(context); // Close add sub account dialog
                Navigator.pop(context); // Close sub account list dialog
                // Reopen the sub account list dialog to show the updated list
                _showSubAccountDialog(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  List<TransactionModel> _getSubAccountTransactions(String subAccount) {
    return widget.transactionBox.values
        .where((transaction) =>
            // Check both fromSubAccount and toSubAccount
            (transaction.fromAccount == widget.account['name'] &&
                transaction.fromSubAccount == subAccount) ||
            (transaction.toAccount == widget.account['name'] &&
                transaction.toSubAccount == subAccount))
        .toList();
  }

  void _showAccountTransactions(BuildContext context, String subAccount) {
    final accountTransactions = _getSubAccountTransactions(subAccount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) {
          return Column(
            children: [
              AppBar(
                title: Text('$subAccount Transactions'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      onPressed: () {
                        generateSubAccountPDF(subAccount);
                      }),
                ],
              ),
              Expanded(
                child: accountTransactions.isEmpty
                    ? const Center(child: Text('No transactions found'))
                    : ListView.builder(
                        controller: controller,
                        itemCount: accountTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = accountTransactions[index];
                          return _buildTransactionTile(transaction, context);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  generateSubAccountPDF(String subAccount) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final subcategoryTransactions = _filterTransactionsByDateRange(
        picked.start,
        picked.end,
        widget.transactionBox.values
            .where((transaction) =>
                // Check both fromSubAccount and toSubAccount
                (transaction.fromAccount == widget.account['name'] &&
                    transaction.fromSubAccount == subAccount) ||
                (transaction.toAccount == widget.account['name'] &&
                    transaction.toSubAccount == subAccount))
            .toList(),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubAccountPdf(
            accountName: widget.account['name'],
            subAccountName: subAccount,
            transactions: subcategoryTransactions,
            startDate: picked.start,
            endDate: picked.end,
          ),
        ),
      );
    }
  }

  generateAllSubAccountPDf() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final subcategoryTransactions = <String, List<TransactionModel>>{};

      for (var subAccount in widget.account['subAccount']) {
        final transactions = _filterTransactionsByDateRange(
          picked.start,
          picked.end,
          widget.transactionBox.values
              .where((transaction) =>
                  // Check both fromSubAccount and toSubAccount
                  (transaction.fromAccount == widget.account['name'] &&
                      transaction.fromSubAccount == subAccount) ||
                  (transaction.toAccount == widget.account['name'] &&
                      transaction.toSubAccount == subAccount))
              .toList(),
        );
        subcategoryTransactions[subAccount] = transactions;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AllSubAccountPdf(
            accountName: widget.account['name'],
            subcAccountTransactions: subcategoryTransactions,
            startDate: picked.start,
            endDate: picked.end,
          ),
        ),
      );
    }
  }

  Widget _buildTransactionTile(
      TransactionModel transaction, BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return GestureDetector(
      onTap: () => _showTransactionDialog(transaction.key, context),
      child: ListTile(
        dense: true,
        title: Row(
          children: [
            Text(DateFormat('dd MMM').format(transaction.date)),
            const SizedBox(width: 10),
            Image.asset(
              CustomIcons()
                  .getImagePathForCategory(transaction.categoryName ?? ''),
              width: 30,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(getCategoryText(transaction),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        trailing: Text(
          '$currencySymbol${transaction.amount.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  void _showTransactionDialog(dynamic transactionKey, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder(
        stream: widget.transactionBox.watch(key: transactionKey),
        builder: (context, snapshot) {
          final transaction = widget.transactionBox.get(transactionKey);
          if (transaction == null) {
            Navigator.of(context).pop();
            return const SizedBox.shrink();
          }
          return AccountTransactionCard(
            transaction: transaction,
            color: widget.color,
            onEdit: () => _editTransaction(transaction, context),
            onDelete: () => _deleteTransaction(transaction, context),
            isEditable: false,
          );
        },
      ),
    );
  }

  void _editTransaction(TransactionModel transaction, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: EditScreen(
          transaction: transaction,
          selectedDailyDate: widget.selectedMonth,
          transactionBox: widget.transactionBox,
        ),
      ),
    ).then((updatedTransaction) {
      if (updatedTransaction != null) {
        widget.transactionBox.put(updatedTransaction.key, updatedTransaction);
      }
    });
  }

  void _deleteTransaction(TransactionModel transaction, BuildContext context) {
    widget.transactionBox.delete(transaction.key);
    dailyTabKey.currentState?.loadTransactions();
    monthlyTabKey.currentState?.loadTransactionsAndAttendanceFromHive();
    Navigator.of(context).pop();
  }
}
