import 'package:account_book/app/data/helpers/icon_helper.dart';
import 'package:account_book/app/data/model/budget_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/category/components/category_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:provider/provider.dart';


class BudgetDashboardScreen extends StatefulWidget {
  const BudgetDashboardScreen({super.key});

  @override
  BudgetDashboardScreenState createState() => BudgetDashboardScreenState();
}

class BudgetDashboardScreenState extends State<BudgetDashboardScreen> {
  late Box<BudgetModel> _budgetBox;
  late Box<TransactionModel> _transactionBox;
  late CategoryHelper _categoryHelper;
  bool _isInitialized = false;
  late GetStorage paymentBox;
  List<Map<String, dynamic>> _allCategories = [];
  CustomIcons customIcons = CustomIcons();
  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      await Hive.initFlutter();
      await GetStorage.init('payment_categories');

      // Open budget and transaction boxes
      _budgetBox = await Hive.openBox<BudgetModel>('budgets');
      _transactionBox = await Hive.openBox<TransactionModel>('transactions');

      // Initialize CategoryHelper
      _categoryHelper = CategoryHelper();

      // Initialize GetStorage for payment categories
      paymentBox = GetStorage('payment_categories');

      // Load categories
      _loadAllCategories();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing Hive or GetStorage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize storage')),
      );
    }
  }

  void _loadAllCategories() {
    // Combine general and payment categories
    _allCategories = [
      ..._categoryHelper.generalCategories,
      ..._categoryHelper.paymentCategories,
    ];
  }

  void _editBudget(BudgetModel budget, int index, String currency) {
    TextEditingController amountController =
        TextEditingController(text: budget.plannedAmount.toString());
    BudgetPeriod selectedPeriod = budget.period;
    String selectedCategory = budget.category;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Budget'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: _categoryHelper.paymentCategories
                          .map<DropdownMenuItem<String>>((category) {
                        return DropdownMenuItem<String>(
                          value: category['name'] as String,
                          child: Text(category['name'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                    DropdownButtonFormField<BudgetPeriod>(
                      value: selectedPeriod,
                      items: BudgetPeriod.values.map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text(
                              period.toString().split('.').last.capitalize()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPeriod = value!;
                        });
                      },
                    ),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Planned Amount',
                        prefixText: currency,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (amountController.text.isNotEmpty) {
                      // Update budget dates based on period
                      DateTime now = DateTime.now();
                      DateTime startDate = now;
                      DateTime endDate;

                      switch (selectedPeriod) {
                        case BudgetPeriod.weekly:
                          endDate = now.add(Duration(days: 7));
                          break;
                        case BudgetPeriod.monthly:
                          endDate = DateTime(now.year, now.month + 1, now.day);
                          break;
                        case BudgetPeriod.yearly:
                          endDate = DateTime(now.year + 1, now.month, now.day);
                          break;
                      }

                      // Create updated budget
                      final updatedBudget = BudgetModel(
                        category: selectedCategory,
                        plannedAmount: double.parse(amountController.text),
                        startDate: startDate,
                        endDate: endDate,
                        period: selectedPeriod,
                      );

                      // Update the budget in the box
                      _budgetBox.putAt(index, updatedBudget);

                      Navigator.of(context).pop();
                      setState(() {});
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteBudget(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Budget'),
          content: Text('Are you sure you want to delete this budget?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Delete the budget
                _budgetBox.deleteAt(index);
                Navigator.of(context).pop();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateBudgetDialog(String currencySymbol) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String? selectedCategory;
    String? selectedSubcategory;
    TextEditingController amountController = TextEditingController();
    BudgetPeriod selectedPeriod = BudgetPeriod.monthly;
    List<String> subcategories = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Update subcategories when category changes
            void updateSubcategories(String category) {
              final categoryData = _allCategories.firstWhere(
                (cat) => cat['name'] == category,
                orElse: () => {'subcategories': []},
              );
              subcategories =
                  List<String>.from(categoryData['subcategories'] ?? []);
              if (subcategories.isEmpty) {
                selectedSubcategory = null;
              } else if (!subcategories.contains(selectedSubcategory)) {
                selectedSubcategory = subcategories.first;
              }
            }

            return AlertDialog(
              title: Text('Create New Budget'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 10,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        hint: Text('Select Category'),
                        value: selectedCategory,
                        validator: (value) =>
                            value == null ? 'Select a category' : null,
                        items: _allCategories
                            .map<DropdownMenuItem<String>>((category) {
                          return DropdownMenuItem<String>(
                            value: category['name'] as String,
                            child: Row(
                              children: [
                                Image.asset(
                                  category['imagePath'] as String,
                                  width: 24,
                                  height: 24,
                                ),
                                SizedBox(width: 8),
                                Text(category['name'] as String),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                            updateSubcategories(value!);
                          });
                        },
                      ),
                      if (selectedCategory != null &&
                          subcategories.isNotEmpty) ...[
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Subcategory',
                            border: OutlineInputBorder(),
                          ),
                          hint: Text('Select Subcategory'),
                          value: selectedSubcategory,
                          items: subcategories.map((subcategory) {
                            return DropdownMenuItem<String>(
                              value: subcategory,
                              child: Text(subcategory),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSubcategory = value;
                            });
                          },
                        ),
                      ],
                      DropdownButtonFormField<BudgetPeriod>(
                        decoration: InputDecoration(
                          labelText: 'Period',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedPeriod,
                        items: BudgetPeriod.values.map((period) {
                          return DropdownMenuItem(
                            value: period,
                            child: Text(
                                period.toString().split('.').last.capitalize()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPeriod = value!;
                          });
                        },
                      ),
                      TextFormField(
                        controller: amountController,
                        decoration: InputDecoration(
                          labelText: 'Planned Amount',
                          prefixText: currencySymbol,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      DateTime now = DateTime.now();
                      DateTime startDate = now;
                      DateTime endDate;

                      switch (selectedPeriod) {
                        case BudgetPeriod.weekly:
                          endDate = now.add(Duration(days: 7));
                          break;
                        case BudgetPeriod.monthly:
                          endDate = DateTime(now.year, now.month + 1, now.day);
                          break;
                        case BudgetPeriod.yearly:
                          endDate = DateTime(now.year + 1, now.month, now.day);
                          break;
                      }

                      final newBudget = BudgetModel(
                        category: selectedCategory!,
                        plannedAmount: double.parse(amountController.text),
                        startDate: startDate,
                        endDate: endDate,
                        period: selectedPeriod,
                        subCategory: selectedSubcategory,
                      );

                      _budgetBox.add(newBudget);
                      Navigator.of(context).pop();
                      setState(() {});
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Budget Tracker'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Tracker'),
        centerTitle: true,
      ),
      body: _budgetBox.isEmpty
          ? Center(child: Text('No budgets created yet'))
          : _buildBudgetList(currencySymbol),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateBudgetDialog(currencySymbol),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildBudgetList(String currencySymbol) {
    return ListView.builder(
      itemCount: _budgetBox.length,
      itemBuilder: (context, index) {
        final budget = _budgetBox.getAt(index)!;
        return Slidable(
          key: ValueKey(budget.hashCode),
          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (context) =>
                    _editBudget(budget, index, currencySymbol),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit',
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (context) => _deleteBudget(index),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: _buildBudgetItem(budget, currencySymbol),
        );
      },
    );
  }

  Widget _buildBudgetItem(BudgetModel budget, String currencySymbol) {
    // Get transactions for this category in the current month
    List<TransactionModel> categoryTransactions =
        _categoryHelper.getCategoryFromTransactions(
      DateTime.now(),
      _transactionBox,
      [TransactionType.payment],
      budget.category,
    );

    // Filter by subcategory if it exists
    if (budget.subCategory != null) {
      categoryTransactions = categoryTransactions
          .where((t) => t.subCategory == budget.subCategory)
          .toList();
    }
    // Calculate total amount spent in this category
    double totalSpent = categoryTransactions.isNotEmpty
        ? categoryTransactions.map((t) => t.amount).reduce((a, b) => a + b)
        : 0.0;

    double percentSpent = (totalSpent / budget.plannedAmount) * 100;

    // Find the matching category icon

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      customIcons.getImagePathForCategory(budget.category),
                      width: 30,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.category,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (budget.subCategory != null)
                          Text(
                            budget.subCategory!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    )
                  ],
                ),
                Text(
                  '${percentSpent.toStringAsFixed(1)}% Spent',
                  style: TextStyle(
                    color: percentSpent > 100 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            LinearProgressIndicator(
              value: percentSpent / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentSpent > 100 ? Colors.red : Colors.blue,
              ),
              minHeight: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Planned: $currencySymbol ${budget.plannedAmount.toStringAsFixed(2)}'),
                Text('Spent: $currencySymbol ${totalSpent.toStringAsFixed(2)}'),
              ],
            ),
            Text(
              'Period: ${budget.period.toString().split('.').last.capitalize()}',
              style: TextStyle(color: Colors.grey),
            ),
            if (categoryTransactions.isNotEmpty) ...[
              Text(
                'Recent Transactions: ${categoryTransactions.length}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...categoryTransactions.take(3).map((transaction) => ListTile(
                    title: Text(transaction.description),
                    trailing: Text(
                        '$currencySymbol ${transaction.amount.toStringAsFixed(2)}'),
                    dense: true,
                  ))
            ]
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
