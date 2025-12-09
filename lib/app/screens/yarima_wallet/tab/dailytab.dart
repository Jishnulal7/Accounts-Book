import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/enums/toast.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/payment_model.dart';
import 'package:account_book/app/data/model/receipt_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_helper.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/edit_attendance.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/components/daily/attendance_section.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/components/daily/balance_card.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/components/daily/date_card.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/components/daily/transaction_section.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/components/daily/transaction_summary.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/components/daily/transfer_section.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/components/daily/transfer_summary.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/monthlytab.dart';
import 'package:account_book/app/screens/yarima_wallet/transaction/edit_transactions.dart';
import 'package:account_book/app/services/calculation_manager.dart';
import 'package:account_book/app/services/hive.dart';
import 'package:account_book/app/widgets/custom_confirmation.dart';
import 'package:account_book/app/widgets/custom_toast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import '../account/components/account_functions.dart';

GlobalKey<DailyTabState> dailyTabKey = GlobalKey<DailyTabState>();

class DailyTab extends StatefulWidget {
  List<TransactionModel> transactions;
  DateTime selectDailyDate;
  final Function(DateTime) selectDate;
  final Function(DateTime) calculateBalanceForDay;
  final Function calculateTotalReceiptAmount;
  final Function calculateTotalPaymentAmount;
  double balance;
  double previousDayBalance;
  double totalReceiptAmount;
  double totalPaymentAmount;
  final double openingBalance;
  final VoidCallback addTransactionScreen;
  Map<String, List<TransactionModel>> transactionsByDate;
  List<Receipt> receipts;
  List<Payment> payments;
  final Function(double) updateOpeningBalance;
  final Box<TransactionModel> transactionBox;
  final Box<AttendanceModel> attendanceBox;
  final ScrollController scrollController;
  DailyTab({
    super.key,
    required this.transactions,
    required this.selectDailyDate,
    required this.selectDate,
    required this.balance,
    required this.previousDayBalance,
    required this.totalReceiptAmount,
    required this.totalPaymentAmount,
    required this.addTransactionScreen,
    required this.openingBalance,
    required this.transactionsByDate,
    required this.receipts,
    required this.payments,
    required this.calculateTotalReceiptAmount,
    required this.calculateTotalPaymentAmount,
    required this.calculateBalanceForDay,
    required this.updateOpeningBalance,
    required this.transactionBox,
    required this.attendanceBox,
    required this.scrollController,
  });

  @override
  State<DailyTab> createState() => DailyTabState();
}

class DailyTabState extends State<DailyTab> {
  CalculationManager calculationManager = CalculationManager();
  late TransactionRepository _repository;
  final AccountHelper _accountHelper = AccountHelper();
  final GetStorage _accountsBox = GetStorage('accounts');

  @override
  void initState() {
    super.initState();
    _repository = TransactionRepository();
    _repository.init().then((_) => loadTransactions());
    _accountHelper.initializeDefaultAccounts();
  }

  Future<void> loadTransactions() async {
    final transactions =
        await _repository.getTransactionsForDay(widget.selectDailyDate);

    setState(() {
      widget.transactions = transactions;
      widget.transactionsByDate =
          _repository.groupTransactionsByDay(transactions);
    });
  }

  Map<String, List<TransactionModel>> groupTransactionsByDate(
      List<TransactionModel> transactions) {
    return transactions.fold({},
        (Map<String, List<TransactionModel>> data, transaction) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      data.putIfAbsent(dateKey, () => []).add(transaction);
      return data;
    });
  }

  void removeTransactionsWithRemovedAccount(String removedAccountName) {
    try {
      setState(() {
        widget.transactions.removeWhere((transaction) =>
            transaction.fromAccount == removedAccountName ||
            transaction.toAccount == removedAccountName);
        widget.transactionsByDate =
            groupTransactionsByDate(widget.transactions);
      });
    } catch (e) {
      debugPrint('Error removing transactions with removed account: $e');
    }
  }

  void updateTransactionsWithUpdatedAccountName(
      String oldName, String newName) {
    try {
      setState(() {
        for (final transaction in widget.transactions) {
          if (transaction.fromAccount == oldName) {
            transaction.fromAccount = newName;
          }
          if (transaction.toAccount == oldName) {
            transaction.toAccount = newName;
          }
        }
        widget.transactionsByDate =
            groupTransactionsByDate(widget.transactions);
      });
    } catch (e) {
      debugPrint('Error updating transactions with updated account name: $e');
    }
  }

  void deleteItemsFromBothTabs(List<String> selectedItems) {
    try {
      setState(() {
        for (final dateKey in selectedItems) {
          final transactions = widget.transactionBox.values.where(
              (transaction) =>
                  DateFormat('yyyy-MM-dd').format(transaction.date) == dateKey);
          for (final transaction in transactions) {
            widget.transactionBox.delete(transaction.key);
          }
        }
        _updateTransactionTotals();
      });
    } catch (e) {
      debugPrint('Error deleting items from both tabs: $e');
    }
  }

  void removeTransactionsWithRemovedCategory(String removedCategoryName) {
    try {
      setState(() {
        widget.transactions.removeWhere(
            (transaction) => transaction.categoryName == removedCategoryName);
        widget.transactionsByDate =
            groupTransactionsByDate(widget.transactions);
      });
    } catch (e) {
      debugPrint('Error removing transactions with removed category: $e');
    }
  }

  restoreData() async {
    await Hive.openBox<TransactionModel>('transactions');
    setState(() {
      loadTransactions();
      debugPrint(widget.transactionBox.values.toString());
    });
  }

  void rebuildWidgetTree() async {
    try {
      var box = await Hive.openBox<TransactionModel>('transactions');
      await box.clear();
      setState(() {
        loadTransactions();
        widget.balance = 0.0;
        widget.previousDayBalance = 0.0;
        widget.totalPaymentAmount = 0.0;
        widget.totalReceiptAmount = 0.0;
        widget.transactions = [];
        widget.transactionsByDate = {};
        widget.receipts = [];
        widget.payments = [];
      });
    } catch (e) {
      debugPrint('Error clearing transaction box: $e');
    }
  }

  void deleteTransactions(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return ConfirmationDialog(
          title: 'Delete Transaction',
          content: 'Are you sure you want to delete this transaction?',
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => deleteTransactionsFromHive(transaction),
          confirmButtonText: 'Delete',
          cancelButtonText: 'Cancel',
        );
      },
    );
  }

  void updateTransactionsWithUpdatedCategoryName(
      String oldName, String newName) {
    try {
      setState(() {
        for (final transaction in widget.transactions) {
          if (transaction.categoryName == oldName) {
            transaction.categoryName = newName;
          }
        }
      });
    } catch (e) {
      debugPrint('Error updating transactions with updated category name: $e');
    }
  }

  void deleteTransactionsFromHive(TransactionModel transaction) {
    try {
      _repository.deleteTransaction(transaction);

      if (transaction.transactionType != TransactionType.transfer) {
        widget.selectDate(widget.selectDailyDate);
      }
      setState(() {
        // Remove the transaction from the local lists
        widget.transactions.removeWhere((t) => t.id == transaction.id);
        widget.transactionsByDate.forEach((date, transactions) {
          transactions.removeWhere((t) => t.id == transaction.id);
        });
        // Remove empty dates
        widget.transactionsByDate
            .removeWhere((date, transactions) => transactions.isEmpty);
      });

      // Notify MonthlyTab to update its data
      monthlyTabKey.currentState?.updateTransactions(widget.transactionsByDate);

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
    }
  }

  void copyTransaction(
      TransactionModel transaction, DateTime targetMonth) async {
    try {
      final DateTime? newDate = await showDatePicker(
        context: context,
        initialDate: widget.selectDailyDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (newDate != null) {
        final copiedTransaction = TransactionModel(
          toSubAccount: transaction.toSubAccount,
          fromSubAccount: transaction.fromSubAccount,
          amount: transaction.amount,
          description: transaction.description,
          categoryName: transaction.categoryName,
          date: newDate,
          id: transaction.id,
          transactionType: transaction.transactionType,
          iconData: transaction.iconData,
          fromAccount: transaction.fromAccount,
          toAccount: transaction.toAccount,
          fromAccountImagePath: transaction.fromAccountImagePath,
          toAccountImagePath: transaction.toAccountImagePath,
          subCategory: transaction.subCategory,
          generalCategory: transaction.generalCategory,
          generalSubCategory: transaction.generalSubCategory,
        );

        final dateKey = DateFormat('yyyy-MM-dd').format(newDate);
        widget.transactionsByDate
            .putIfAbsent(dateKey, () => [])
            .add(copiedTransaction);

        await widget.transactionBox.add(copiedTransaction);

        setState(() {
          widget.transactions.add(copiedTransaction);
          widget.transactionsByDate =
              groupTransactionsByDate(widget.transactions);
        });
        // Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error copying transaction: $e');
    }
  }

  void editTransactions(TransactionModel transaction) {
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: EditScreen(
            transaction: transaction,
            selectedDailyDate: widget.selectDailyDate,
            transactionBox: widget.transactionBox,
          ),
        ),
      ).then((updatedTransaction) {
        if (updatedTransaction != null) {
          setState(() {
            widget.transactionBox
                .put(updatedTransaction.key, updatedTransaction);
            if (updatedTransaction.transactionType !=
                TransactionType.transfer) {
              // Change this line
              widget.selectDate(widget.selectDailyDate);
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Error editing transaction: $e');
    }
  }

  void _updateTransactionTotals() {
    widget.totalPaymentAmount = widget.calculateTotalPaymentAmount();
    widget.totalReceiptAmount = widget.calculateTotalReceiptAmount();
    widget.balance = widget.calculateBalanceForDay(widget.selectDailyDate);
  }

  void _editAttendance(AttendanceModel attendance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: EditAttendanceScreen(
          attendance: attendance,
          onSave: (updatedAttendance) async {
            await widget.attendanceBox
                .put(updatedAttendance.key, updatedAttendance);
            setState(() {});
            // Navigator.of(context).pop();
            ToastService.show(
              context,
              message: 'Attendance updated successfully',
              type: ToastType.success,
            );
          },
          selectedDailyDate: widget.selectDailyDate,
          transactionBox: widget.transactionBox,
        ),
      ),
    );
  }

  void _deleteAttendance(AttendanceModel attendance) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Attendance',
        content: 'Are you sure you want to delete this attendance record?',
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () async {
          await widget.attendanceBox.delete(attendance.key);
          setState(() {});
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

  Map<String, double> _calculateAccountBalances() {
    try {
      Map<String, double> balances = {};

      // Get all accounts from GetStorage
      final accounts = _accountsBox
          .getKeys()
          .where((key) =>
              _accountsBox.read(key) != null && _accountsBox.read(key) is Map)
          .toList();

      for (var accountName in accounts) {
        final accountData = _accountsBox.read(accountName);
        if (accountData == null) continue;

        // Filter transactions for the specific account
        Set<TransactionModel> accountTransactions = widget.transactionBox.values
            .where((transaction) =>
                DateFormat('yyyy-MM-dd').format(transaction.date).compareTo(
                        DateFormat('yyyy-MM-dd')
                            .format(widget.selectDailyDate)) <=
                    0 &&
                (transaction.fromAccount == accountName ||
                    transaction.toAccount == accountName))
            .toSet();

        // Filter attendance transactions for the specific account
        Set<AttendanceModel> accountAttendanceTransactions = widget
            .attendanceBox.values
            .where((attendance) =>
                DateFormat('yyyy-MM-dd').format(attendance.date).compareTo(
                        DateFormat('yyyy-MM-dd')
                            .format(widget.selectDailyDate)) <=
                    0 &&
                attendance.account == accountName)
            .toSet();

        // Calculate balance using AccountHelper
        balances[accountName] = AccountFuntions().calculateAccountBalance(
          accountTransactions,
          accountAttendanceTransactions,
          accountName,
          accountName,
          accountData as Map<String, dynamic>,
        );
      }

      return balances;
    } catch (e) {
      debugPrint('Error calculating account balances: $e');
      return {};
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
          if (transaction.fromAccount == fromAccount) {
            balance -= transaction.amount;
          }
        } else if (transaction.transactionType == TransactionType.receipt) {
          if (transaction.toAccount == toAccount) {
            balance += transaction.amount;
          }
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
      rethrow;
    }
  }

  Widget _buildWideLayout(
    BuildContext context,
    List<TransactionModel> selectedDateTransactions,
    List<AttendanceModel> selectedDateAttendance,
    double receipts,
    double payments,
    double balance,
    Map<String, double> accountBalances,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildSummaryColumn(balance, accountBalances),
              ),
              Expanded(
                flex: 2,  
                child: _buildTransactionsColumn(
                  selectedDateTransactions,
                  selectedDateAttendance,
                  receipts,
                  payments,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    List<TransactionModel> selectedDateTransactions,
    List<AttendanceModel> selectedDateAttendance,
    double receipts,
    double payments,
    double balance,
    Map<String, double> accountBalances,
  ) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Column(
        children: [
          _buildSummaryColumn(balance, accountBalances),
          _buildTransactionsColumn(
            selectedDateTransactions,
            selectedDateAttendance,
            receipts,
            payments,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn(
      double balance, Map<String, double> accountBalances) {
    return Column(
      children: [
        DateNavigationCard(
          selectDailyDate: widget.selectDailyDate,
          balance: balance,
          selectDate: widget.selectDate,
        ),
        const SizedBox(height: 7),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: AccountBalanceWidget(
            accountBalances: accountBalances,
            onAccountChanged: (newAccount) {
              debugPrint('Selected account changed to: $newAccount');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsColumn(
    List<TransactionModel> selectedDateTransactions,
    List<AttendanceModel> selectedDateAttendance,
    double receipts,
    double payments,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TransactionSummary(
              title: 'Payments', amount: payments, color: AppColor.kRed),
          TransactionSection(
            transactions: selectedDateTransactions
                .where((t) => t.transactionType == TransactionType.payment)
                .toList(),
            editTransactions: editTransactions,
            deleteTransactions: deleteTransactions,
            copyTransaction: copyTransaction,
            selectedDate: widget.selectDailyDate,
          ),
          TransactionSummary(
              title: 'Receipts', amount: receipts, color: AppColor.kGreen),
          TransactionSection(
            transactions: selectedDateTransactions
                .where((t) => t.transactionType == TransactionType.receipt)
                .toList(),
            editTransactions: editTransactions,
            deleteTransactions: deleteTransactions,
            copyTransaction: copyTransaction,
            selectedDate: widget.selectDailyDate,
          ),
          const TransferSummary(title: 'Transfers'),
          TransferSection(
            transactions: selectedDateTransactions,
            title: 'Transfers',
            editTransactions: editTransactions,
            deleteTransactions: deleteTransactions,
            copyTransaction: copyTransaction,
            selectDailyDate: widget.selectDailyDate,
          ),
          const TransferSummary(title: 'Attendance'),
          AttendanceSectionInDailyTab(
            date: widget.selectDailyDate,
            editAttendance: _editAttendance,
            deleteAttendance: _deleteAttendance,
            attendanceRecords: selectedDateAttendance,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateKey =
        DateFormat('yyyy-MM-dd').format(widget.selectDailyDate);
    final selectedDateTransactions = widget.transactionBox.values
        .where((transaction) =>
            DateFormat('yyyy-MM-dd').format(transaction.date) ==
            selectedDateKey)
        .toList();
    final selectedDateAttendance = widget.attendanceBox.values
        .where((attendance) =>
            DateFormat('yyyy-MM-dd').format(attendance.date) == selectedDateKey)
        .toList();

    final receipts = widget.calculateTotalReceiptAmount();
    final payments = widget.calculateTotalPaymentAmount();
    final balance = widget.calculateBalanceForDay(widget.selectDailyDate);
    final accountBalances = _calculateAccountBalances();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return _buildWideLayout(
            context,
            selectedDateTransactions,
            selectedDateAttendance,
            receipts,
            payments,
            balance,
            accountBalances,
          );
        } else {
          return _buildNarrowLayout(
            context,
            selectedDateTransactions,
            selectedDateAttendance,
            receipts,
            payments,
            balance,
            accountBalances,
          );
        }
      },
    );
  }
}
