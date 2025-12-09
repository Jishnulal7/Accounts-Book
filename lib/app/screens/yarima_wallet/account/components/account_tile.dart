import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_functions.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_info.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/bottom_sheet_header.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/transaction_list.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/dailytab.dart';
import 'package:account_book/app/widgets/custom_confirmation.dart';
import 'package:account_book/app/widgets/no_records.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';
import 'package:provider/provider.dart';

class AccountListTile extends StatefulWidget {
  const AccountListTile({
    required this.accountData,
    required this.balance,
    required this.isDefaultAccount,
    required this.transactionBox,
    required this.color,
    required this.selectedMonth,
    super.key,
    this.onAccountAdded,
    required this.attendanceBox,
    required this.subcategories,
  });

  final VoidCallback? onAccountAdded;
  final Map<String, dynamic> accountData;
  final double balance;
  final bool isDefaultAccount;
  final Box<TransactionModel> transactionBox;
  final Box<AttendanceModel> attendanceBox;
  final Color color;
  final DateTime selectedMonth;
  final List<dynamic> subcategories;

  @override
  State<AccountListTile> createState() => _AccountListTileState();
}

class _AccountListTileState extends State<AccountListTile> {
  String boxName = 'accounts';
  final accountsBox = GetStorage('accounts');
  late List<String> subAccounts;
  late Stream<void> _combinedStream;
  late ValueNotifier<Set<TransactionModel>> _transactionsNotifier;
  late ValueNotifier<Set<AttendanceModel>> _attendanceNotifier;
  late TextEditingController _editingController;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedYear = DateTime.now().year;
    _editingController = TextEditingController();
    _transactionsNotifier = ValueNotifier<Set<TransactionModel>>({});
    _attendanceNotifier = ValueNotifier<Set<AttendanceModel>>({});
    _setupStreams();
  }

  void _setupStreams() {
    _combinedStream = Rx.merge([
      widget.transactionBox.watch().map((_) => _updateTransactions()),
      widget.attendanceBox.watch().map((_) => _updateAttendance()),
    ]);

    _combinedStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });

    // Initial load
    _updateTransactions();
    _updateAttendance();
  }

  void _updateTransactions() {
    if (!mounted) return;

    final transactions = _getAllTransactions(
      widget.transactionBox,
      widget.accountData['name'],
      widget.accountData['name'],
    );

    _transactionsNotifier.value = transactions;
  }

  void _updateAttendance() {
    _attendanceNotifier.value = _getAllAttendanceTransactions(
      widget.attendanceBox,
      widget.accountData['name'],
    );
  }

  // @override
  // void dispose() {
  //   _transactionsNotifier.dispose();
  //   _attendanceNotifier.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return StatefulBuilder(
      builder: (context, setState) {
        double calculatedBalance = _calculateTotalBalance(
          _transactionsNotifier.value,
          _attendanceNotifier.value,
        );
        return Slidable(
          endActionPane: widget.isDefaultAccount
              ? null
              : ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) =>
                          _editAccount(widget.accountData['name'], context),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                    SlidableAction(
                      onPressed: (_) =>
                          _deleteAccount(widget.accountData['name']),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
          child: ListTile(
            onTap: () {
              _accountTransactions(
                context,
                widget.accountData,
                widget.transactionBox,
                widget.attendanceBox,
                widget.accountData['name'],
                widget.accountData['name'],
                widget.color,
              );
            },
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  widget.accountData['name'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'Balance : $currencySymbol${calculatedBalance.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 13),
                )
              ],
            ),
            leading: Image.asset(
              widget.accountData['imagePath'],
              width: 25,
            ),
          ),
        );
      },
    );
  }

  double _calculateTotalBalance(
      Set<TransactionModel> transactions, Set<AttendanceModel> attendance) {
    return AccountFuntions().calculateAccountBalance(
      transactions,
      attendance,
      widget.accountData['name'],
      widget.accountData['name'],
      widget.accountData,
    );
  }

  void _accountTransactions(
    BuildContext context,
    Map<String, dynamic> category,
    Box<TransactionModel> monthlyTransactionBox,
    Box<AttendanceModel> attendanceBox,
    String fromAccount,
    String toAccount,
    Color color,
  ) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return ValueListenableBuilder<Set<TransactionModel>>(
          valueListenable: _transactionsNotifier,
          builder: (context, transactions, _) {
            return ValueListenableBuilder<Set<AttendanceModel>>(
              valueListenable: _attendanceNotifier,
              builder: (context, attendance, _) {
                return _buildBottomSheetContent(
                  context,
                  category,
                  transactions,
                  attendance,
                  fromAccount,
                  toAccount,
                  color,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetContent(
    BuildContext context,
    Map<String, dynamic> category,
    Set<TransactionModel> allTransactions,
    Set<AttendanceModel> allAttendanceTransactions,
    String fromAccount,
    String toAccount,
    Color color,
  ) {
    final List<String> sortedMonths = _getSortedMonths(allTransactions);
    final Set<int> availableYears = allTransactions
        .map((transaction) => transaction.date.year)
        .toSet()
      ..add(DateTime.now().year);
    final List<int> sortedYears = availableYears.toList()
      ..sort((a, b) => b.compareTo(a));

    double balance = AccountFuntions().calculateAccountBalance(
      allTransactions,
      allAttendanceTransactions,
      fromAccount,
      toAccount,
      category,
    );

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BottomSheetHeader(
              context: context,
              category: category,
              color: color,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Year:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  underline: SizedBox(),
                  value: selectedYear,
                  items: sortedYears.map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (year) {
                    if (year != null) {
                      setState(() {
                        selectedYear = year;
                        _updateTransactions();
                        _updateAttendance();
                      });
                    }
                  },
                ),
              ],
            ),
            AccountInfo(
              context: context,
              account: category,
              color: color,
              balance: balance,
              transactionBox: widget.transactionBox,
              selectedMonth: widget.selectedMonth,
              attendanceBox: widget.attendanceBox,
              subcategories: category['subAccount'] ?? [],
            ),
            allTransactions.isEmpty && allAttendanceTransactions.isEmpty
                ? const NoRecordsWidget()
                : TransactionList(
                    sortedMonths: sortedMonths,
                    allTransactions: _filterTransactionsByYear(allTransactions),
                    fromAccount: fromAccount,
                    toAccount: toAccount,
                    color: color,
                    selectedMonth: widget.selectedMonth,
                    transactionBox: widget.transactionBox,
                    attendanceBox: widget.attendanceBox,
                    allAttendanceTransactions:
                        _filterAttendanceByYear(allAttendanceTransactions),
                  ),
          ],
        ),
      ),
    );
  }

  Set<TransactionModel> _filterTransactionsByYear(
      Set<TransactionModel> transactions) {
    return transactions
        .where((transaction) => transaction.date.year == selectedYear)
        .toSet();
  }

  Set<AttendanceModel> _filterAttendanceByYear(
      Set<AttendanceModel> attendance) {
    return attendance
        .where((record) => record.date.year == selectedYear)
        .toSet();
  }

  Set<TransactionModel> _getAllTransactions(
    Box<TransactionModel> monthlyTransactionBox,
    String fromAccount,
    String toAccount,
  ) {
    final Set<TransactionModel> allTransactions = {};

    for (var transaction in monthlyTransactionBox.values) {
      if (transaction.fromAccount == fromAccount ||
          transaction.toAccount == fromAccount) {
        allTransactions.add(transaction);
      }
    }

    return allTransactions;
  }

  Set<AttendanceModel> _getAllAttendanceTransactions(
    Box<AttendanceModel> attendanceBox,
    String fromAccount,
  ) {
    final Set<AttendanceModel> allAttendanceTransactions = {};
    for (int i = 0; i <= widget.selectedMonth.month; i++) {
      final monthAttendance = attendanceBox.values
          .where((attendance) =>
              attendance.date.year == widget.selectedMonth.year &&
              attendance.date.month == i + 1 &&
              attendance.account == fromAccount)
          .toList();

      final groupedAttendance = groupBy(monthAttendance,
          (AttendanceModel a) => '${a.name}|${a.subName}|${a.categoryName}');

      groupedAttendance.forEach((key, attendanceList) {
        final parts = key.split('|');
        final name = parts[0];
        final subName = parts[1];
        final categoryName = parts[2];

        final attendanceFromAccount =
            AccountFuntions().getAttendanceTransactions(
          attendanceBox,
          fromAccount,
          name,
          subName,
          categoryName,
          DateTime(widget.selectedMonth.year, i + 1),
        );
        allAttendanceTransactions.addAll(attendanceFromAccount);
      });
    }
    return allAttendanceTransactions;
  }

  List<String> _getSortedMonths(Set<TransactionModel> allTransactions) {
    final List<String> uniqueMonths = allTransactions
        .map((transaction) => DateFormat('MMMM yyyy').format(transaction.date))
        .toSet()
        .toList();

    final List<DateTime> dateTimeMonths = uniqueMonths
        .map((month) => DateFormat('MMMM yyyy').parse(month))
        .toList();

    dateTimeMonths.sort((a, b) => b.compareTo(a)); // Sort in descending order

    return dateTimeMonths
        .map((dateTime) => DateFormat('MMMM yyyy').format(dateTime))
        .toList();
  }

  void _deleteAccount(String accountName) {
    try {
      showDialog(
        context: context,
        builder: (context) => ConfirmationDialog(
          title: 'Confirm Deletion',
          content: 'Are you sure you want to delete this Account?',
          onCancel: () {
            Navigator.of(context).pop();
          },
          onConfirm: () {
            _removeAccountFromStorage(accountName);
            widget.onAccountAdded?.call();
            setState(() {});
            dailyTabKey.currentState
                ?.removeTransactionsWithRemovedAccount(accountName);
            Navigator.of(context).pop();
          },
          confirmButtonText: 'Yes',
          cancelButtonText: 'No',
        ),
      );
    } catch (e) {
      debugPrint('Error deleting Account: $e');
    }
  }

  void _removeAccountFromStorage(String accountName) {
    try {
      // Remove transactions associated with the account
      final transactionBox = Hive.box<TransactionModel>('transactions');
      final transactions = transactionBox.values.where((transaction) =>
          transaction.fromAccount == accountName ||
          transaction.toAccount == accountName);
      for (final transaction in transactions) {
        transactionBox.delete(transaction.key);
      }

      // Remove the account from GetStorage
      accountsBox.remove(accountName);

      // Trigger UI update
      setState(() {});
      widget.onAccountAdded?.call();

      debugPrint('Account removed: $accountName');
    } catch (e) {
      debugPrint('Error removing account: $e');
    }
  }

  void _editAccount(String accountName, BuildContext context) {
    // Set the initial text in the controller
    _editingController.text = accountName;
    double newInitialAmount =
        widget.accountData['initialAmount'] as double? ?? 0.0;

    setState(() {
      // Initialize subAccounts properly
      if (widget.accountData.containsKey('subAccount') &&
          widget.accountData['subAccount'] != null) {
        subAccounts = List<String>.from(widget.accountData['subAccount']);
      } else {
        // If no subAccounts exist, initialize from subcategories or empty list
        // ignore: unnecessary_null_comparison
        subAccounts = widget.subcategories != null
            ? List<String>.from(widget.subcategories)
            : [];
      }
    });

    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Account'),
          content: StatefulBuilder(builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _editingController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  initialValue: newInitialAmount.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (newValue) {
                    newInitialAmount =
                        double.tryParse(newValue) ?? newInitialAmount;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Opening Balance',
                  ),
                ),
                const Text('Sub Account:'),
                ...subAccounts.map((subcat) => Row(
                      children: [
                        Expanded(child: Text(subcat)),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editSubAccounts(subcat, setState),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteSubAccounts(subcat, setState),
                        ),
                      ],
                    )),
                ElevatedButton(
                  child: const Text('Add Sub Account'),
                  onPressed: () => _addSubcategory(setState),
                ),
              ],
            );
          }),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newAccountName = _editingController.text;
                if (newAccountName.isNotEmpty) {
                  _updateAccountNameAndAmount(
                      accountName, newAccountName, newInitialAmount);
                  widget.onAccountAdded?.call();
                  dailyTabKey.currentState
                      ?.updateTransactionsWithUpdatedAccountName(
                          accountName, newAccountName);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error while editing account: $e');
    }
  }

  void _deleteSubAccounts(String subcat, StateSetter setState) {
    setState(() {
      subAccounts.remove(subcat);
    });
  }

  void _editSubAccounts(String oldSubcat, StateSetter setState) {
    TextEditingController controller = TextEditingController(text: oldSubcat);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Sub Account'),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                setState(() {
                  int index = subAccounts.indexOf(oldSubcat);
                  if (index != -1) {
                    subAccounts[index] = controller.text;
                  }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addSubcategory(StateSetter setState) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Sub Account'),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                setState(() {
                  subAccounts.add(controller.text);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateAccountNameAndAmount(
      String oldName, String newName, double newAmount) {
    try {
      final accountData = accountsBox.read(oldName);
      if (accountData != null) {
        final String imagePath = accountData['imagePath'];

        // First, update the account data in storage
        final Map<String, dynamic> updatedAccountData = {
          'imagePath': imagePath,
          'initialAmount': newAmount,
          'subAccount': subAccounts,
        };

        // If we're only adding/modifying sub-accounts and not changing the account name,
        // update the existing account
        if (oldName == newName) {
          accountsBox.write(oldName, updatedAccountData);
        } else {
          // If account name is changing, remove old and add new
          accountsBox.remove(oldName);
          accountsBox.write(newName, updatedAccountData);
        }

        // Update transactions
        final accountBox = Hive.box<TransactionModel>('transactions');
        final transactions = accountBox.values
            .where((transaction) =>
                transaction.fromAccount == oldName ||
                transaction.toAccount == oldName)
            .toList();

        // Batch update transactions
        for (var transaction in transactions) {
          final updatedTransaction = TransactionModel(
            id: transaction.id,
            amount: transaction.amount,
            categoryName: transaction.categoryName,
            date: transaction.date,
            description: transaction.description,
            fromAccount: transaction.fromAccount == oldName
                ? newName
                : transaction.fromAccount,
            fromAccountImagePath: transaction.fromAccount == oldName
                ? imagePath
                : transaction.fromAccountImagePath,
            toAccount: transaction.toAccount == oldName
                ? newName
                : transaction.toAccount,
            toAccountImagePath: transaction.toAccount == oldName
                ? imagePath
                : transaction.toAccountImagePath,
            transactionType: transaction.transactionType,
            iconData: transaction.iconData,
            subCategory: transaction.subCategory,
            generalCategory: transaction.generalSubCategory,
            generalSubCategory: transaction.generalSubCategory,
            // Preserve existing sub-account information
            fromSubAccount: transaction.fromSubAccount,
            toSubAccount: transaction.toSubAccount,
          );

          // Use the transaction's key to update it
          accountBox.put(transaction.key, updatedTransaction);
        }

        // Update attendance records if needed
        final attendanceBox = Hive.box<AttendanceModel>('attendanceBox');
        final attendanceRecords = attendanceBox.values
            .where((attendance) => attendance.account == oldName)
            .toList();

        for (var attendance in attendanceRecords) {
          final updatedAttendance = AttendanceModel(
            id: attendance.id,
            name: attendance.name,
            categoryName: attendance.categoryName,
            account: newName,
            date: attendance.date,
            subName: attendance.subName,
            isPresent: attendance.isPresent,
            accountPath: attendance.accountPath,
            categoryPath: attendance.categoryPath,
            balance: attendance.balance,
            description: attendance.description,
            extraCharges: attendance.extraCharges,
            openingBalance: attendance.openingBalance,
            payment: attendance.payment,
            siteName: attendance.siteName,
            wage: attendance.wage,
            generalCategoryName: attendance.generalCategoryName,
            generalSubCategory: attendance.generalSubCategory,
            subAccount: attendance.subAccount,
            subCategory: attendance.subCategory,
          );
          attendanceBox.put(attendance.key, updatedAttendance);
        }

        // Update widget state
        setState(() {
          if (oldName != newName) {
            widget.accountData['name'] = newName;
          }
          widget.accountData['initialAmount'] = newAmount;
          widget.accountData['subAccount'] = subAccounts;
        });

        // Force refresh transactions
        _updateTransactions();
        _updateAttendance();

        // Notify parent widget of changes
        if (widget.onAccountAdded != null) {
          widget.onAccountAdded!();
        }

        // Update daily tab if account name changed
        if (oldName != newName) {
          dailyTabKey.currentState
              ?.updateTransactionsWithUpdatedAccountName(oldName, newName);
        }
      } else {
        debugPrint('No data found for account: $oldName');
      }
    } catch (e) {
      debugPrint('Error updating account: $e');
    }
  }
}
