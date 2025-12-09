import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/color_helper.dart';
import 'package:account_book/app/data/helpers/icon_helper.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/category/components/category_helper.dart';
import 'package:account_book/app/screens/yarima_wallet/category/components/category_transaction_card.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/all_subcategory_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/category_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/subcategory_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/dailytab.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/monthlytab.dart';
import 'package:account_book/app/screens/yarima_wallet/transaction/edit_transactions.dart';
import 'package:account_book/app/widgets/no_records.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CategoryTransactionCardWidget extends StatefulWidget {
  const CategoryTransactionCardWidget({
    super.key,
    required this.category,
    required this.transactionBox,
    required this.categoryFromTransactions,
    required this.categoryType,
    required this.color,
    required this.selectedMonth,
  });

  final Map<String, dynamic> category;
  final Box<TransactionModel> transactionBox;
  final String categoryFromTransactions;
  final String categoryType;
  final Color color;
  final DateTime selectedMonth;

  @override
  State<CategoryTransactionCardWidget> createState() =>
      _CategoryTransactionCardWidgetState();
}

class _CategoryTransactionCardWidgetState
    extends State<CategoryTransactionCardWidget> {
  late int selectedYear;
  late List<dynamic> subcategories;
  @override
  initState() {
    super.initState();
    selectedYear = widget.selectedMonth.year;
    subcategories = List.from(widget.category['subcategories'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BoxEvent>(
      stream: widget.transactionBox.watch(),
      builder: (context, snapshot) {
        final transactions = _getCategoryTransactions();
        final monthlyTotals = _calculateMonthlyTotalAmounts(transactions);
        final totalAmount = _calculateTotalAmount(transactions);

        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
            child: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildCategoryDetails(totalAmount, context),
                _buildTransactionList(transactions, monthlyTotals, context),
              ],
            ),
          ),
        );
      },
    );
  }

  List<TransactionModel> _getCategoryTransactions() {
    return CategoryHelper().getCategoryFromTransactions(
      widget.selectedMonth,
      widget.transactionBox,
      CategoryHelper().allTransactionTypes,
      widget.categoryFromTransactions,
    );
  }

  double _calculateTotalAmount(List<TransactionModel> transactions) {
    return transactions.fold(
        0.0, (sum, transaction) => sum + transaction.amount);
  }

  Map<String, double> _calculateMonthlyTotalAmounts(
      List<TransactionModel> transactions) {
    Map<String, double> monthlyTotals = {};

    for (var transaction in transactions) {
      if (transaction.categoryName == widget.categoryFromTransactions) {
        String monthKey = DateFormat('MMMM yyyy').format(transaction.date);
        monthlyTotals[monthKey] =
            (monthlyTotals[monthKey] ?? 0) + transaction.amount;
      }
    }

    return monthlyTotals;
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Category Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildCategoryDetails(double totalAmount, BuildContext context) {
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
          Row(
            children: [
              Image.asset(
                width: 30,
                widget.category['imagePath'] ??
                    'assets/categories/category.png',
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category['name'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.categoryType == 'Payment Categories'
                          ? 'Payment categories'
                          : 'Receipt Categories',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Total: $currencySymbol ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorHelper().darkorWhite(context),
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: totalAmount.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColor.kPurple,
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return CategoryPDFScreen(
                              categoryName: widget.category['name'],
                              transactions: _filterTransactionsByDateRange(
                                picked.start,
                                picked.end,
                                widget.transactionBox.values.toList(),
                              ),
                              startDate: picked.start,
                              endDate: picked.end,
                            );
                          },
                        ),
                      );
                    }
                  },
                  label: const Text('View PDF'),
                  icon: const Icon(Icons.picture_as_pdf),
                ),
              ),
            ],
          ),
          _buildSubcategoriesButton(context),
        ],
      ),
    );
  }

  Widget _buildSubcategoriesButton(BuildContext context) {
    return TextButton(
      onPressed: () => _showSubcategoriesBottomSheet(context),
      child: const Text('View Subcategories'),
    );
  }

  void _showSubcategoriesBottomSheet(BuildContext context) {
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
                title: Text('${widget.category['name']} Subcategories'),
                actions: [
                  IconButton(
                    onPressed: () {
                      _showAddSubcategoryDialog(context);
                    },
                    icon: const Icon(Icons.add),
                  ),
                  if ((widget.category['subcategories']?.length ?? 0) > 0)
                    IconButton(
                      onPressed: () {
                        generateAllSubCategoryPDF();
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
                child: (widget.category['subcategories']?.isEmpty ?? true)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No subcategories found',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showAddSubcategoryDialog(context);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Subcategory'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount:
                            widget.category['subcategories']?.length ?? 0,
                        itemBuilder: (context, index) {
                          final subcategory =
                              widget.category['subcategories'][index];
                          return ListTile(
                            title: Text(subcategory),
                            onTap: () => _showSubcategoryTransactions(
                                context, subcategory),
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

  void _showAddSubcategoryDialog(BuildContext context) {
    final TextEditingController subcategoryController = TextEditingController();
    final categoryHelper = CategoryHelper();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subcategory'),
        content: TextField(
          controller: subcategoryController,
          decoration: const InputDecoration(
            labelText: 'Subcategory Name',
            hintText: 'Enter subcategory name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newSubcategory = subcategoryController.text.trim();
              if (newSubcategory.isNotEmpty) {
                final transactionType =
                    widget.categoryType == 'Payment Categories'
                        ? TransactionType.payment
                        : TransactionType.receipt;

                // Add subcategory using CategoryHelper
                categoryHelper.addSubcategory(
                  widget.category['name'],
                  newSubcategory,
                  transactionType,
                );

                // Update local state
                setState(() {
                  subcategories.add(newSubcategory);
                });

                // Close only the add dialog
                Navigator.pop(context);

                // Force rebuild of the bottom sheet
                _refreshSubcategoriesBottomSheet(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _refreshSubcategoriesBottomSheet(BuildContext context) {
    // Close and reopen the bottom sheet with updated data
    Navigator.pop(context);
    _showSubcategoriesBottomSheet(context);
  }

  void _showSubcategoryTransactions(BuildContext context, String subcategory) {
    final subcategoryTransactions = widget.transactionBox.values
        .where((transaction) =>
            transaction.categoryName == widget.category['name'] &&
            transaction.subCategory == subcategory)
        .toList();

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
                title: Text('$subcategory Transactions'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      onPressed: () {
                        _generateSubCategoryPDF(context, subcategory);
                      }),
                ],
              ),
              Expanded(
                child: subcategoryTransactions.isEmpty
                    ? const Center(child: Text('No transactions found'))
                    : ListView.builder(
                        controller: controller,
                        itemCount: subcategoryTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = subcategoryTransactions[index];
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

  void generateAllSubCategoryPDF() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final subcategoryTransactions = <String, List<TransactionModel>>{};

      for (var subcategory in widget.category['subcategories']) {
        final transactions = _filterTransactionsByDateRange(
          picked.start,
          picked.end,
          widget.transactionBox.values
              .where((transaction) =>
                  transaction.categoryName == widget.category['name'] &&
                  transaction.subCategory == subcategory)
              .toList(),
        );
        subcategoryTransactions[subcategory] = transactions;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AllSubcategoriesPDFScreen(
            categoryName: widget.category['name'],
            subcategoryTransactions: subcategoryTransactions,
            startDate: picked.start,
            endDate: picked.end,
          ),
        ),
      );
    }
  }

  void _generateSubCategoryPDF(BuildContext context, String subcategory) async {
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
                transaction.categoryName == widget.category['name'] &&
                transaction.subCategory == subcategory)
            .toList(),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubcategoryPDFScreen(
            categoryName: widget.category['name'],
            subcategoryName: subcategory,
            transactions: subcategoryTransactions,
            startDate: picked.start,
            endDate: picked.end,
          ),
        ),
      );
    }
  }

  List<TransactionModel> _filterTransactionsByDateRange(DateTime startDate,
      DateTime endDate, List<TransactionModel> transactions) {
    // Adjust the end date to include the entire last day
    final adjustedEndDate = endDate.add(const Duration(days: 1));

    return transactions
        .where((transaction) =>
            transaction.date.isAtSameMomentAs(startDate) ||
            transaction.date.isAtSameMomentAs(endDate) ||
            (transaction.date.isAfter(startDate) &&
                transaction.date.isBefore(adjustedEndDate)))
        .toList();
  }

  Widget _buildTransactionList(
    List<TransactionModel> transactions,
    Map<String, double> monthlyTotals,
    BuildContext context,
  ) {
    final uniqueMonths = transactions
        .map((transaction) => DateFormat('MMMM yyyy').format(transaction.date))
        .toSet()
        .toList();

    final dateTimeMonths = uniqueMonths
        .map((month) => DateFormat('MMMM yyyy').parse(month))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    final sortedMonths = dateTimeMonths
        .map((dateTime) => DateFormat('MMMM yyyy').format(dateTime))
        .toList();

    return sortedMonths.isEmpty
        ? const NoRecordsWidget()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sortedMonths.map((month) {
              final transactionsForMonth = transactions
                  .where((transaction) =>
                      DateFormat('MMMM yyyy').format(transaction.date) == month)
                  .toList();

              return transactionsForMonth.isEmpty
                  ? const SizedBox.shrink()
                  : _buildMonthlyTransactionCard(
                      transactionsForMonth, month, monthlyTotals, context);
            }).toList(),
          );
  }

  Widget _buildMonthlyTransactionCard(
    List<TransactionModel> transactionsForMonth,
    String month,
    Map<String, double> monthlyTotals,
    BuildContext context,
  ) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: widget.color),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    month,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$currencySymbol${monthlyTotals[month]?.toStringAsFixed(1) ?? '0.00'}',
                    style: TextStyle(color: AppColor.kPurple),
                  ),
                ],
              ),
            ),
            Divider(color: widget.color),
            Column(
              children: transactionsForMonth.map((transaction) {
                return _buildTransactionTile(transaction, context);
              }).toList(),
            ),
          ],
        ),
      ),
    );
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
              CustomIcons().getImagePathForAccounts(transaction.fromAccount),
              width: 30,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(transaction.fromAccount,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        trailing: Text(
          '$currencySymbol${transaction.amount.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 18,
            color: widget.categoryType == 'Payment Categories'
                ? AppColor.kRed
                : AppColor.kGreen,
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
          return CategoryTransactionCard(
            transaction: transaction,
            color: widget.color,
            onEdit: () => _editTransaction(transaction, context),
            onDelete: () => _deleteTransaction(transaction, context),
            title: widget.categoryType,
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
