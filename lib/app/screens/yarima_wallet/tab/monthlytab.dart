import 'package:account_book/app/data/helpers/color_helper.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/components/monthly/date_row.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/components/monthly/financial_summary.dart';
import 'package:account_book/app/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'components/monthly/transaction_data.dart';

GlobalKey<MonthlyTabState> monthlyTabKey = GlobalKey<MonthlyTabState>();

class MonthlyTab extends StatefulWidget {
  DateTime selectMonth;
  DateTime selectedYear;
  final Function(DateTime) calculatePreviousMonthBalance;
  final Map<String, List<TransactionModel>> transactionsByMonth;
  final void Function(DateTime) changeToDailyTab;
  final Function(DateTime) calculateTotalPaymentAmountForMonth;
  final Function(DateTime) calculateTotalReceiptAmountForMonth;
  final Function(DateTime) calculateBalance;
  final Function(DateTime) calculateBalanceForMonth;
  final Function calculateTotalReceiptAmount;
  final Function calculateTotalPaymentAmount;
  final Function(DateTime) getPaymentsForDay;
  final Function(DateTime) getReceiptsForDay;
  final Function(DateTime) getTransfersForDay;
  final Function(DateTime) getAttendanceForDay;
  final Function(DateTime) onMonthSelected;
  final VoidCallback addTransactionScreen;
  final Function(double) updateOpeningBalance;
  final Box<TransactionModel> transactionBox;
  final Box<AttendanceModel> attendanceBox;
  MonthlyTab({
    required this.selectedYear,
    required this.selectMonth,
    required this.transactionsByMonth,
    required this.changeToDailyTab,
    super.key,
    required this.calculateTotalPaymentAmountForMonth,
    required this.calculateTotalReceiptAmountForMonth,
    required this.calculateBalance,
    required this.calculateTotalReceiptAmount,
    required this.calculateTotalPaymentAmount,
    required this.calculatePreviousMonthBalance,
    required this.getPaymentsForDay,
    required this.getReceiptsForDay,
    required this.calculateBalanceForMonth,
    required this.addTransactionScreen,
    required this.getTransfersForDay,
    required this.onMonthSelected,
    required this.updateOpeningBalance,
    required this.transactionBox,
    required this.attendanceBox,
    required this.getAttendanceForDay,
  });

  @override
  State<MonthlyTab> createState() => MonthlyTabState();
}

class MonthlyTabState extends State<MonthlyTab> {
  int selectedItemsCount = 0;
  List<String> selectedItems = [];
  bool isSelectionModeActive = false;
  double totalReceipts = 0.0;
  double totalBalance = 0.0;
  double totalPayments = 0.0;
  double closingBalance = 0.0;
  late Map<String, List<dynamic>> filteredItemsByMonth = {};
  Map<String, double> closingBalances = {};
  late Map<String, List<TransactionModel>> filteredTransactionsByMonth = {};
  late Map<String, List<AttendanceModel>> filteredAttendnaceByMonth = {};

  Map<String, double> dayBalancesByDay = {};

  @override
  void initState() {
    super.initState();
    // Schedule the data loading for the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadTransactionsAndAttendanceFromHive();
    });
    filterTransactionsForSelectedMonth(widget.selectMonth);
    closingBalance = widget.calculatePreviousMonthBalance(widget.selectMonth);
  }

  @override
  void didUpdateWidget(MonthlyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectMonth != widget.selectMonth) {
      // Schedule the data loading for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadTransactionsAndAttendanceFromHive();
      });
      filterTransactionsForSelectedMonth(widget.selectMonth);
      closingBalance = widget.calculatePreviousMonthBalance(widget.selectMonth);
    }
  }

  void updateSelectedMonth(DateTime newSelectedMonth) {
    setState(() {
      widget.selectMonth = newSelectedMonth;

      // Ensure filtered transactions are updated for the new month
      filterTransactionsForSelectedMonth(newSelectedMonth);
      filteredItemsByMonth = groupItemsByDay(
          filteredTransactionsByMonth.values.expand((x) => x).toList());

      closingBalance = widget.calculatePreviousMonthBalance(newSelectedMonth);
      isSelectionModeActive = false;
      selectedItems.clear();
      selectedItemsCount = 0;
    });

    // Notify the parent about month change
    widget.onMonthSelected(newSelectedMonth);
  }

  void loadTransactionsAndAttendanceFromHive() {
    if (!mounted) return;

    try {
      final selectedMonthKey = DateFormat('yyyy-MM').format(widget.selectMonth);

      // Load transactions for the month
      final allTransactionsForMonth = widget.transactionBox.values
          .where((transaction) =>
              DateFormat('yyyy-MM').format(transaction.date) ==
              selectedMonthKey)
          .toList();

      // Load attendance for the month
      final allAttendanceForMonth = widget.attendanceBox.values
          .where((attendance) =>
              DateFormat('yyyy-MM').format(attendance.date) == selectedMonthKey)
          .toList();

      if (mounted) {
        setState(() {
          // Update filtered transactions
          filteredTransactionsByMonth =
              groupTransactionsByDay(allTransactionsForMonth);

          // Update filtered items to include both transactions and attendance
          final allItems = [
            ...allTransactionsForMonth,
            ...allAttendanceForMonth
          ];
          filteredItemsByMonth = groupItemsByDay(allItems);

          // Ensure the items are properly sorted by date
          updateClosingBalance(widget.selectMonth);
        });
      }

      // Notify parent about month selection
      if (mounted) {
        widget.onMonthSelected(widget.selectMonth);
      }
    } catch (e) {
      debugPrint('Error loading transactions and attendance from Hive: $e');
    }
  }

  Map<String, List<dynamic>> groupItemsByDay(List<dynamic> items) {
    try {
      final Map<String, List<dynamic>> itemsByDay = {};
      for (final item in items) {
        final dayKey = DateFormat('yyyy-MM-dd').format(item.date);
        itemsByDay.putIfAbsent(dayKey, () => []);
        if (!itemsByDay[dayKey]!.contains(item)) {
          itemsByDay[dayKey]!.add(item);
        }
      }
      return Map.fromEntries(itemsByDay.entries.toList()
        ..sort(
            (a, b) => DateTime.parse(b.key).compareTo(DateTime.parse(a.key))));
    } catch (e) {
      debugPrint('Error grouping items by day: $e');
      return {};
    }
  }

  void updateSelectionAfterRestore() {
    setState(() {
      // Revalidate selected items
      selectedItems = selectedItems
          .where((dayKey) => filteredTransactionsByMonth.containsKey(dayKey))
          .toList();

      // Update selection mode and count
      isSelectionModeActive = selectedItems.isNotEmpty;
      selectedItemsCount = selectedItems.length;
    });
  }

  restoreData() async {
    await Hive.openBox<TransactionModel>('transactions');
    await Hive.openBox<AttendanceModel>('attendanceBox');
    setState(() {
      loadTransactionsAndAttendanceFromHive();
      updateSelectionAfterRestore();
      debugPrint(widget.transactionBox.values.toString());
      debugPrint(widget.attendanceBox.values.toString());
    });
  }

  void updateClosingBalance(DateTime newSelectedDate) {
    try {
      final selectedMonthKey = DateFormat('yyyy-MM').format(newSelectedDate);
      if (closingBalances.containsKey(selectedMonthKey)) {
        closingBalance = closingBalances[selectedMonthKey]!;
      } else {
        closingBalance = widget.calculatePreviousMonthBalance(newSelectedDate);
        closingBalances[selectedMonthKey] = closingBalance;
      }
    } catch (e) {
      debugPrint('Error updating closing balance: $e');
    }
  }

  void updateTransactions(
      Map<String, List<TransactionModel>> newTransactionsByDate) {
    try {
      setState(() {
        filteredTransactionsByMonth = newTransactionsByDate;
      });
    } catch (e) {
      debugPrint('Error updating transactions: $e');
    }
  }

  void filterTransactionsForSelectedMonth(DateTime selectedDate) {
    try {
      final selectedMonthKey = DateFormat('yyyy-MM').format(selectedDate);

      // Get transactions for the month
      final transactionsForMonth =
          widget.transactionsByMonth[selectedMonthKey] ?? [];
      final filteredTransactions = transactionsForMonth
          .where((transaction) =>
              transaction.date.month == selectedDate.month &&
              transaction.date.year == selectedDate.year)
          .toList();

      // Get attendance for the month
      final attendanceForMonth = widget.attendanceBox.values
          .where((attendance) =>
              attendance.date.month == selectedDate.month &&
              attendance.date.year == selectedDate.year)
          .toList();

      setState(() {
        // Update filtered transactions
        filteredTransactionsByMonth =
            groupTransactionsByDay(filteredTransactions);

        // Update filtered items to include both transactions and attendance
        final allItems = [...filteredTransactions, ...attendanceForMonth];
        filteredItemsByMonth = groupItemsByDay(allItems);
      });
    } catch (e) {
      debugPrint('Error filtering transactions for selected month: $e');
    }
  }

  Map<String, List<TransactionModel>> groupTransactionsByDay(
      List<TransactionModel> transactions) {
    try {
      final Map<String, List<TransactionModel>> transactionsByDay = {};
      for (final transaction in transactions) {
        final dayKey = DateFormat('yyyy-MM-dd').format(transaction.date);
        transactionsByDay.putIfAbsent(dayKey, () => []);
        if (!transactionsByDay[dayKey]!.contains(transaction)) {
          transactionsByDay[dayKey]!.add(transaction);
        }
      }
      return transactionsByDay;
    } catch (e) {
      debugPrint('Error grouping transactions by day: $e');
      return {};
    }
  }

  Future _selectMonthYear(BuildContext context) async {
    try {
      showMonthPicker(
        context: context,
        initialDate: widget.selectMonth,
        firstDate: DateTime(2000, 1),
        lastDate: DateTime(2101, 12),
      ).then((date) {
        if (date != null) {
          setState(() {
            widget.selectMonth = date;
            filterTransactionsForSelectedMonth(date);
            closingBalance = widget.calculatePreviousMonthBalance(date);
            isSelectionModeActive = false;
            selectedItems.clear();
            selectedItemsCount = 0;
          });
        }
      });
    } catch (e) {
      debugPrint('Error selecting month/year: $e');
    }
  }

  List<TransactionModel> filterTransactionsForMonth(
      List<TransactionModel> allTransactions, DateTime selectedDate) {
    try {
      return allTransactions.where((transaction) {
        return transaction.date.month == selectedDate.month &&
            transaction.date.year == selectedDate.year;
      }).toList();
    } catch (e) {
      debugPrint('Error filtering transactions for month: $e');
      return [];
    }
  }

  double calculateBalanceForDay(DateTime date) {
    try {
      return widget.calculateBalance(date);
    } catch (e) {
      debugPrint('Error calculating balance for day: $e');
      return 0.0;
    }
  }

  double calculateBalanceForMonth(DateTime month) {
    try {
      return widget.calculateBalanceForMonth(month);
    } catch (e) {
      debugPrint('Error calculating balance for month: $e');
      return 0.0;
    }
  }

  void deleteSelectedItems(List<String> selectedItems) {
    try {
      setState(() {
        for (final dayKey in selectedItems) {
          // Delete transactions
          final transactions = widget.transactionBox.values.where(
              (transaction) =>
                  DateFormat('yyyy-MM-dd').format(transaction.date) == dayKey);
          for (final transaction in transactions) {
            widget.transactionBox.delete(transaction.key);
          }

          // Delete attendance records
          final attendanceRecords = widget.attendanceBox.values.where(
              (attendance) =>
                  DateFormat('yyyy-MM-dd').format(attendance.date) == dayKey);
          for (final attendance in attendanceRecords) {
            widget.attendanceBox.delete(attendance.key);
          }

          // Remove from filtered collections
          filteredTransactionsByMonth.remove(dayKey);
          filteredItemsByMonth.remove(dayKey);
        }

        selectedItems.clear();
        isSelectionModeActive = false;
        selectedItemsCount = 0;

        // Reload data to ensure UI is updated
        loadTransactionsAndAttendanceFromHive();
      });
    } catch (e) {
      debugPrint('Error deleting selected items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedDates = _getSortedDates();
    final bool hasTransactions = sortedDates.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return _buildWideLayout(context, sortedDates, hasTransactions);
        } else {
          return _buildNarrowLayout(context, sortedDates, hasTransactions);
        }
      },
    );
  }

  Widget _buildWideLayout(
      BuildContext context, List<String> sortedDates, bool hasTransactions) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: _buildSummaryColumn(context),
        ),
        Expanded(
          flex: 2,
          child: _buildTransactionsColumn(sortedDates, hasTransactions),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
      BuildContext context, List<String> sortedDates, bool hasTransactions) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSummaryColumn(context),
          _buildTransactionsColumn(sortedDates, hasTransactions),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn(BuildContext context) {
    return Column(
      children: [
        if (isSelectionModeActive) _buildCustomAppBar(),
        DateSelectionRow(
          selectMonth: widget.selectMonth,
          onPreviousMonth: _navigateToPreviousMonth,
          onNextMonth: _navigateToNextMonth,
          onSelectMonthYear: () => _selectMonthYear(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          child: CompactFinancialSummaryWidget(
            totalReceipts: widget
                .calculateTotalReceiptAmountForMonth(widget.selectMonth)
                .toStringAsFixed(1),
            totalPayments: widget
                .calculateTotalPaymentAmountForMonth(widget.selectMonth)
                .toStringAsFixed(1),
            carryForward: widget
                .calculatePreviousMonthBalance(widget.selectMonth)
                .toStringAsFixed(1),
            balance:
                calculateBalanceForMonth(widget.selectMonth).toStringAsFixed(1),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsColumn(List<String> sortedDates, bool hasItems) {
    if (!hasItems) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: TransactionData(
        sortedDates: sortedDates,
        filteredItemsByMonth: filteredItemsByMonth,
        getReceiptsForDay: widget.getReceiptsForDay,
        getPaymentsForDay: widget.getPaymentsForDay,
        getTransfersForDay: widget.getTransfersForDay,
        calculateBalanceForDay: calculateBalanceForDay,
        changeToDailyTab: widget.changeToDailyTab,
        isSelectionModeActive: isSelectionModeActive,
        onSelectItem: _onSelectItem,
        onLongPressItem: _onLongPressItem,
        getAttendanceForDay: widget.getAttendanceForDay,
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return CustomAppBar(
      sortedDates: _getSortedDates(),
      onBackPressed: _clearSelection,
      onSelectAll: _selectAllItems,
      onDelete: _deleteSelectedItems,
      selectedItemsCount: selectedItemsCount,
    );
  }

  List<String> _getSortedDates() {
    try {
      // Get all dates from filteredItemsByMonth
      final dates = filteredItemsByMonth.keys.where((dayKey) {
        final date = DateTime.parse(dayKey);
        return date.month == widget.selectMonth.month &&
            date.year == widget.selectMonth.year;
      }).toList();

      // Sort dates in descending order
      dates.sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));
      return dates;
    } catch (e) {
      debugPrint('Error getting sorted dates: $e');
      return [];
    }
  }

  void _onSelectItem(String dayKey) {
    setState(() {
      if (selectedItems.contains(dayKey)) {
        selectedItems.remove(dayKey);
        if (selectedItems.isEmpty) {
          isSelectionModeActive = false;
          selectedItemsCount = 0;
        } else {
          selectedItemsCount = selectedItems.length;
        }
      } else {
        selectedItems.add(dayKey);
        selectedItemsCount = selectedItems.length;
      }
    });
  }

  void _onLongPressItem(String dayKey) {
    if (!selectedItems.contains(dayKey)) {
      setState(() {
        selectedItems.add(dayKey);
        isSelectionModeActive = true;
        selectedItemsCount = selectedItems.length;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      isSelectionModeActive = false;
      selectedItems.clear();
      selectedItemsCount = 0;
    });
  }

  void _selectAllItems() {
    setState(() {
      selectedItems = _getSortedDates();
      selectedItemsCount = selectedItems.length;
    });
  }

  void _deleteSelectedItems() {
    deleteSelectedItems(selectedItems);
    setState(() {});
  }

  void _navigateToPreviousMonth() {
    final newDate = widget.selectMonth.subtract(
      Duration(
        days: ColorHelper().getDaysInMonth(
          widget.selectMonth.month,
        ),
      ),
    );
    filterTransactionsForSelectedMonth(newDate);
    updateClosingBalance(newDate);

    setState(() {
      widget.selectMonth = newDate;
      isSelectionModeActive = false;
      selectedItems.clear();
      selectedItemsCount = 0;
    });
  }

  void _navigateToNextMonth() {
    final newDate = widget.selectMonth.add(
      Duration(
        days: ColorHelper().getDaysInMonth(
          widget.selectMonth.month,
        ),
      ),
    );
    filterTransactionsForSelectedMonth(newDate);
    updateClosingBalance(newDate);

    setState(() {
      widget.selectMonth = newDate;
      isSelectionModeActive = false;
      selectedItems.clear();
      selectedItemsCount = 0;
    });
  }
}
