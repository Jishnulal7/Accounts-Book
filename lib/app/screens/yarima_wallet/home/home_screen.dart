import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/payment_model.dart';
import 'package:account_book/app/data/model/receipt_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/data/model/transfer_model.dart';
import 'package:account_book/app/screens/yarima_wallet/account/account_screen.dart';
import 'package:account_book/app/screens/yarima_wallet/category/category_screen.dart';
import 'package:account_book/app/screens/yarima_wallet/charts/charts.dart';
import 'package:account_book/app/screens/yarima_wallet/home/components/all_pdf_screen.dart';
import 'package:account_book/app/screens/yarima_wallet/home/components/search_screen.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/budget_screen.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/dailytab.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/monthlytab.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/yearlytab.dart';
import 'package:account_book/app/screens/yarima_wallet/transaction/add_transaction.dart';
import 'package:account_book/app/services/calculation_manager.dart';
import 'package:account_book/app/services/hive.dart';
import 'package:account_book/app/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';

class YarimaWalletHome extends StatefulWidget {
  const YarimaWalletHome({super.key});

  @override
  State<YarimaWalletHome> createState() => _YarimaWalletHomeState();
}

class _YarimaWalletHomeState extends State<YarimaWalletHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late TransactionRepository _transactionRepository;
  Box<TransactionModel> _transactionBox =
      Hive.box<TransactionModel>('transactions');
  Box<AttendanceModel> _attendanceBox =
      Hive.box<AttendanceModel>('attendanceBox');
  CalculationManager calculationManager = CalculationManager();

  late DateTime selectedDailyDate = DateTime.now();
  late DateTime selectedMonthlyDate = DateTime.now();
  late DateTime selectedYearlyDate = DateTime.now();

  double monthlyTotalPayments = 0.0;
  double monthlyTotalReceipts = 0.0;
  double totalReceiptAmount = 0.0;
  double totalPaymentAmount = 0.0;
  double balance = 0;
  double previousDayBalance = 0;
  double totalBalance = 0.0;
  double openingBalance = 0.0;

  List<TransactionModel> transactions = [];
  List<Receipt> receipts = [];
  List<Payment> payments = [];

  Map<String, List<TransactionModel>> transactionsByDate = {};
  Map<String, List<TransactionModel>> transactionsByMonth = {};

  DateTime? currentBackPressTime;
  bool canPopNow = false;
  int requiredSeconds = 1;
  String searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  bool _isBottomSheetOpen = false; // Flag to track if the bottom sheet is open

// Add this to track the transaction type that was already processed
  TransactionType? _processedTransactionType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final transactionType =
        ModalRoute.of(context)?.settings.arguments as TransactionType?;

    // Only open bottom sheet if there's a transaction type, it's not already being processed,
    // and it's different from the last processed type
    if (transactionType != null &&
        !_isBottomSheetOpen &&
        transactionType != _processedTransactionType) {
      // Set the flag to true to indicate that the bottom sheet is being opened
      _isBottomSheetOpen = true;

      // Store the current transaction type being processed
      _processedTransactionType = transactionType;

      // Schedule the call to _addTransaction after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addTransaction(transactionType: transactionType).then((_) {
          // Reset the flag after the bottom sheet is closed
          _isBottomSheetOpen = false;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadTransactionsFromHive();
    transactionsByDate[DateFormat('yyyy-MM-dd').format(selectedDailyDate)] = [];
    previousDayBalance = openingBalance;
    _initializeController();
    _selectDate(selectedDailyDate);
    _initializeListeners();
    _initializeTransactionRepository();
    getAttendanceForDay(selectedMonthlyDate);
  }

  void _initializeController() {
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(_handleTabSelection);
  }

  Future<void> _initializeTransactionRepository() async {
    _transactionRepository = TransactionRepository();
    await _transactionRepository.init();
  }

  void _initializeListeners() {
    _scrollController.addListener(_scrollListener);
  }

  void notifyTabUpdate() {
    totalReceiptAmount = calculateTotalReceiptAmount();
    totalPaymentAmount = calculateTotalPaymentAmount();
    balance = calculateBalanceForDay(selectedDailyDate);
    monthlyTabKey.currentState?.updateTransactions(transactionsByDate);
    monthlyTotalPayments =
        calculateTotalPaymentAmountForMonth(selectedDailyDate);
    monthlyTotalReceipts =
        calculateTotalReceiptAmountForMonth(selectedDailyDate);
    transactionsByMonth =
        calculationManager.groupTransactionsByMonth(transactionsByDate);
    setState(() {});
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      // _refreshCurrentDate();
    }
  }

  void _changeToDailyTab(DateTime selectedDate) {
    setState(() {
      // selectedDailyDate = selectedDate;
      _tabController.animateTo(0); // Assuming 0 is the index for daily tab
    });

    // Update calculations for the new date
    _selectDate(selectedDate);
  }

  void _updateSelectedMonth(DateTime date) {
    if (!mounted) return;

    // Schedule the state update for the next frame
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (mounted) {
          _tabController.animateTo(1);

          setState(() {
            selectedMonthlyDate = date;
            selectedYearlyDate = date;
            // Update any other necessary state for tab navigation
          });
        }
      },
    );
  }

  void onMonthSelected(DateTime newDate) {
    setState(() {
      selectedYearlyDate = newDate; // Update only the monthly date
      // Don't update selectedDailyDate here
      // notifyTabUpdate();
    });
  }

  void onYearSelected(DateTime newDate) {
    setState(() {
      selectedDailyDate = newDate;
      notifyTabUpdate();
    });
  }

  void updateOpeningBalance(double newOpeningBalance) {
    setState(() {
      openingBalance = newOpeningBalance;
      previousDayBalance = newOpeningBalance;
    });
  }

  Future<void> loadTransactionsFromHive() async {
    try {
      _transactionBox = await Hive.openBox<TransactionModel>('transactions');
      _attendanceBox = Hive.box<AttendanceModel>('attendanceBox');
      transactions.clear();
      transactionsByDate.clear();

      for (final transaction in _transactionBox.values.toList()) {
        transactions.add(transaction);

        final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
        transactionsByDate[dateKey] ??= [];
        transactionsByDate[dateKey]!.add(transaction);
      }

      notifyTabUpdate();

      setState(() {});
    } catch (e) {
      debugPrint('Error loading transactions from Hive: $e');
    }
  }

  Future<void> addUpdatedTransaction(
      TransactionModel updatedTransaction) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(updatedTransaction.date);
      await _transactionRepository.addTransaction(updatedTransaction);

      transactionsByDate[dateKey] ??= [];
      transactionsByDate[dateKey]!.add(updatedTransaction);

      if (updatedTransaction is Receipt) {
        receipts.add(updatedTransaction);
      } else if (updatedTransaction is Payment) {
        payments.add(updatedTransaction);
      }

      notifyTabUpdate();
      setState(() {});
    } catch (e) {
      debugPrint('Error adding transaction to Hive: $e');
    }
  }

  void updateTransaction(TransactionModel updatedTransaction, int index) {
    if (updatedTransaction is Receipt) {
      receipts[index] = updatedTransaction;
    } else if (updatedTransaction is Payment) {
      payments[index] = updatedTransaction;
    }

    double totalReceiptAmount = calculateTotalReceiptAmount();
    double totalPaymentAmount = calculateTotalPaymentAmount();
    double balance = calculateBalanceForDay(selectedDailyDate);

    setState(() {
      totalReceiptAmount = totalReceiptAmount;
      totalPaymentAmount = totalPaymentAmount;
      balance = balance;
    });
  }

  double calculateTotalPaymentAmount() {
    return calculationManager.calculateTotalPaymentAmount(
        selectedDailyDate, _transactionBox);
  }

  double calculateTotalReceiptAmount() {
    return calculationManager.calculateTotalReceiptAmount(
        selectedDailyDate, _transactionBox);
  }

  double calculateTotalPaymentAmountForMonth(DateTime selectedMonth) {
    return calculationManager.calculateTotalPaymentAmountForMonth(
        selectedMonth, _transactionBox, _attendanceBox);
  }

  double calculateTotalReceiptAmountForMonth(DateTime selectedMonth) {
    return calculationManager.calculateTotalReceiptAmountForMonth(
        selectedMonth, _transactionBox);
  }

  double calculateBalanceForDay(DateTime selectedDate) {
    return calculationManager.calculateBalanceForDay(
        selectedDate, openingBalance, _transactionBox, _attendanceBox);
  }

  double calculateBalanceForMonth(DateTime month) {
    return calculationManager.calculateBalanceForMonth(
        month, openingBalance, _transactionBox, _attendanceBox);
  }

  double calculatePreviousMonthBalance(DateTime month) {
    return calculationManager.calculatePreviousMonthBalance(
        month, openingBalance, _transactionBox, _attendanceBox);
  }

  Map<String, Map<String, double>> calculateYearlyData(
    Map<String, List<TransactionModel>> transactionsByMonth,
    double openingBalance,
  ) {
    return calculationManager.calculateYearlyData(
      transactionsByMonth,
      openingBalance,
      _transactionBox,
      _attendanceBox,
    );
  }

  List<Payment> getPaymentsForMonth(DateTime selectedMonth) {
    return calculationManager.getPaymentsForMonth(
      selectedMonth,
      _transactionBox,
    );
  }

  List<Payment> getPaymentsForDay(DateTime selectedMonth) {
    return calculationManager.getPaymentsFromHive(
      _transactionBox,
      selectedMonth,
    );
  }

  List<Transfer> getTransfersForDay(DateTime selectedMonth) {
    return calculationManager.getTransfersFromHive(
      _transactionBox,
      selectedMonth,
    );
  }

  getAttendanceForDay(DateTime selectedMonth) {
    return calculationManager.getAttendanceTransactionsFromHive(
      _attendanceBox,
      selectedMonth,
    );
  }

  List<Receipt> getReceiptsForDay(DateTime selectedMonth) {
    return calculationManager.getReceiptsFromHive(
      _transactionBox,
      selectedMonth,
    );
  }

  List<Payment> getPaymentsForYear(DateTime selectedMonth) {
    return calculationManager.getPaymentsForYear(
      selectedMonth,
      _transactionBox,
    );
  }

  List<Receipt> getReceiptsForMonth(DateTime selectedMonth) {
    return calculationManager.getReceiptsForMonth(
      selectedMonth,
      _transactionBox,
    );
  }

  List<Receipt> getReceiptsForYear(DateTime selectedMonth) {
    return calculationManager.getReceiptsForYear(
      selectedMonth,
      _transactionBox,
    );
  }

  List<Transfer> getTransfersForMonth(DateTime selectedMonth) {
    return calculationManager.getTransfersForYear(
      _transactionBox,
      selectedMonth,
    );
  }

  void _selectDate(DateTime newDate) {
    setState(() {
      selectedDailyDate = newDate;
      totalReceiptAmount = calculateTotalReceiptAmount();
      totalPaymentAmount = calculateTotalPaymentAmount();
      balance = calculateBalanceForDay(selectedDailyDate);
      previousDayBalance =
          calculateBalanceForDay(newDate.subtract(const Duration(days: 1)));
      monthlyTotalPayments =
          calculateTotalPaymentAmountForMonth(selectedMonthlyDate);
      monthlyTotalReceipts =
          calculateTotalReceiptAmountForMonth(selectedMonthlyDate);
      transactionsByMonth =
          calculationManager.groupTransactionsByMonth(transactionsByDate);
    });
  }

  Future<void> _addTransaction({TransactionType? transactionType}) async {
    final newTransaction =
        await _showAddTransactionModal(transactionType: transactionType);
    if (newTransaction != null) {
      await _processNewTransaction(newTransaction);
    }
  }

  Future<TransactionModel?> _showAddTransactionModal(
      {TransactionType? transactionType}) async {
    if (Theme.of(context).platform == TargetPlatform.windows) {
      // For Windows: use AlertDialog
      return showDialog<TransactionModel>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Add Transaction'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: AddTransactionScreen(
              selectedDate: selectedDailyDate,
              onAddTransaction: addUpdatedTransaction,
              transactionBox: _transactionBox,
              onAddAttendance: () {
                setState(() {});
              },
              initialTransactionType: transactionType,
            ),
          ),
        ),
      );
    } else {
      // For other platforms: use ModalBottomSheet as before
      return showModalBottomSheet<TransactionModel>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AddTransactionScreen(
                selectedDate: selectedDailyDate,
                onAddTransaction: addUpdatedTransaction,
                transactionBox: _transactionBox,
                onAddAttendance: () {
                  setState(() {});
                },
                initialTransactionType: transactionType,
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _processNewTransaction(TransactionModel newTransaction) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(newTransaction.date);
    notifyTabUpdate();
    _selectDate(newTransaction.date);
    debugPrint('Date key: $dateKey');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> searchAndNavigate(String query) async {
    List<dynamic> searchedItems = [];
    if (query.trim().isEmpty) {
      // For an empty query, we'll show all transactions and attendance records
      searchedItems = [
        ..._transactionBox.values,
        ..._attendanceBox.values,
      ];
    } else {
      searchedItems = await searchItems(query);
    }
    // Navigate to the search results screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          initialItems: searchedItems,
          initialQuery: query,
        ),
      ),
    );
  }

  Future<List<dynamic>> searchItems(String query) async {
    final List<TransactionModel> allTransactions =
        _transactionBox.values.toList();
    final List<AttendanceModel> allAttendance = _attendanceBox.values.toList();

    // If the query is empty, return all items
    if (query.isEmpty) {
      return [...allTransactions, ...allAttendance];
    }

    final lowercaseQuery = query.toLowerCase().trim();

    List<dynamic> searchResults = [];

    // Search transactions
    searchResults.addAll(allTransactions.where((transaction) {
      return _matchTransaction(transaction, lowercaseQuery);
    }));

    // Search attendance records
    searchResults.addAll(allAttendance.where((attendance) {
      return _matchAttendance(attendance, lowercaseQuery);
    }));

    return searchResults;
  }

  bool _matchTransaction(TransactionModel transaction, String lowercaseQuery) {
    final transactionDate = DateFormat('yyyy-MM-dd').format(transaction.date);
    final transactionAmount = transaction.amount.toString();
    final transactionDescription = transaction.description.toLowerCase();
    final transactionAccount = transaction.fromAccount.toLowerCase();
    final transactionCategory = transaction.categoryName?.toLowerCase() ?? '';

    return transactionDate.contains(lowercaseQuery) ||
        transactionAmount.contains(lowercaseQuery) ||
        transactionDescription.contains(lowercaseQuery) ||
        transactionAccount.contains(lowercaseQuery) ||
        transactionCategory.contains(lowercaseQuery);
  }

  bool _matchAttendance(AttendanceModel attendance, String lowercaseQuery) {
    final attendanceDate = DateFormat('yyyy-MM-dd').format(attendance.date);
    final attendanceName = attendance.name.toLowerCase();
    final attendanceSite = attendance.siteName.toLowerCase();
    final attendanceWage = attendance.wage.toString();
    final attendanceDescription = attendance.description.toLowerCase();

    return attendanceDate.contains(lowercaseQuery) ||
        attendanceName.contains(lowercaseQuery) ||
        attendanceSite.contains(lowercaseQuery) ||
        attendanceWage.contains(lowercaseQuery) ||
        attendanceDescription.contains(lowercaseQuery);
  }

  Widget _buildFloatingActionButton() {
    return SpeedDial(
      onPress: _addTransaction,
      child: const Icon(Icons.add),
    );
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      setState(() {});
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      setState(() {});
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      actions: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return AllPdfScreen(
                      selectDailyDate: selectedDailyDate,
                      transactionsByMonth: transactionsByMonth,
                      yearlyData: calculateYearlyData(
                        transactionsByMonth,
                        openingBalance,
                      ),
                      transactionBox: _transactionBox,
                      openingBalance: openingBalance,
                      attendanceBox: _attendanceBox,
                    );
                  },
                ),
              );
            },
            child: Image.asset(
              'assets/categories/pdf.png',
              width: 30,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => searchAndNavigate(searchQuery),
            child: Image.asset(
              'assets/categories/search (2).png',
              width: 30,
            ),
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Daily'),
          Tab(text: 'Monthly'),
          Tab(text: 'Yearly'),
        ],
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: SizedBox(
        height: 80.0,
        child: BottomNavBar(
          items: [
            BottomNavItem(
              icon: 'assets/categories/wallet.png',
              label: 'Accounts',
              screen: AccountScreen(selectedDailyDate: selectedDailyDate),
            ),
            BottomNavItem(
              icon: 'assets/categories/category.png',
              label: 'Category',
              screen: CategoryScreen(selectDate: selectedDailyDate),
            ),
            BottomNavItem(
              icon: 'assets/categories/money.png',
              label: 'Budget',
              screen: const BudgetDashboardScreen(),
            ),
            BottomNavItem(
              icon: 'assets/categories/analytics_548174.png',
              label: 'Analysis',
              screen: ChartsScreen(selectedMonth: selectedDailyDate),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomAppBar(),
        appBar: _buildAppBar(),
        body: TabBarView(
          controller: _tabController,
          children: [
            DailyTab(
              key: dailyTabKey,
              transactions: transactions,
              selectDailyDate: selectedDailyDate,
              selectDate: _selectDate,
              balance: balance,
              previousDayBalance: previousDayBalance,
              totalReceiptAmount: totalReceiptAmount,
              totalPaymentAmount: totalPaymentAmount,
              openingBalance: openingBalance,
              transactionsByDate: transactionsByDate,
              payments: payments,
              receipts: receipts,
              calculateTotalReceiptAmount: calculateTotalReceiptAmount,
              calculateTotalPaymentAmount: calculateTotalPaymentAmount,
              calculateBalanceForDay: calculateBalanceForDay,
              updateOpeningBalance: updateOpeningBalance,
              transactionBox: _transactionBox,
              attendanceBox: _attendanceBox,
              addTransactionScreen: _addTransaction,
              scrollController: _scrollController,
            ),
            MonthlyTab(
              selectMonth: selectedMonthlyDate,
              changeToDailyTab: _changeToDailyTab,
              key: monthlyTabKey,
              transactionsByMonth: transactionsByMonth,
              calculateTotalPaymentAmountForMonth:
                  calculateTotalPaymentAmountForMonth,
              calculateTotalReceiptAmountForMonth:
                  calculateTotalReceiptAmountForMonth,
              calculateBalance: calculateBalanceForDay,
              calculateTotalReceiptAmount: calculateTotalReceiptAmount,
              calculateTotalPaymentAmount: calculateTotalPaymentAmount,
              calculatePreviousMonthBalance: calculatePreviousMonthBalance,
              getReceiptsForDay: getReceiptsForDay,
              getPaymentsForDay: getPaymentsForDay,
              calculateBalanceForMonth: calculateBalanceForMonth,
              addTransactionScreen: _addTransaction,
              getTransfersForDay: getTransfersForDay,
              selectedYear: selectedYearlyDate,
              onMonthSelected: onMonthSelected,
              updateOpeningBalance: updateOpeningBalance,
              transactionBox: _transactionBox,
              attendanceBox: _attendanceBox,
              getAttendanceForDay: getAttendanceForDay,
            ),
            YearlyTab(
              scrollController: _scrollController,
              yearlyData: calculateYearlyData(
                transactionsByMonth,
                openingBalance,
              ),
              getPaymentsForMonth: getPaymentsForYear,
              getReceiptsForMonth: getReceiptsForYear,
              addTransactionScreen: _addTransaction,
              selectedMonth: selectedMonthlyDate,
              changeToMonthlyTab: _updateSelectedMonth,
              selectedYear: selectedYearlyDate,
              getTransfersForMonth: getTransfersForMonth,
              updateOpeningBalance: updateOpeningBalance,
              transactionBox: _transactionBox,
              attendanceBox: _attendanceBox,
              calculatePreviousMonthBalance: calculatePreviousMonthBalance,
            ),
          ],
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _tabController.animation!,
          builder: (context, child) {
            return _buildFloatingActionButton();
          },
        ),
      ),
    );
  }
}
