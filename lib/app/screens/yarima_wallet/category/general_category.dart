import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/category/components/category_helper.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/all_general_category_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/general_category_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/dailytab.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/monthlytab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';

class GeneralCategorySection extends StatefulWidget {
  final Box<TransactionModel> transactionBox;
  final DateTime selectedMonth;
  final VoidCallback onCategoryAdded;

  const GeneralCategorySection({
    super.key,
    required this.transactionBox,
    required this.selectedMonth,
    required this.onCategoryAdded,
  });

  @override
  GeneralCategorySectionState createState() => GeneralCategorySectionState();
}

class GeneralCategorySectionState extends State<GeneralCategorySection> {
  @override
  void initState() {
    categoryHelper.loadGeneralCategories();
    super.initState();
  }

  final CategoryHelper categoryHelper = CategoryHelper();
  void _addCategory() {
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newCategoryName = '';
        List<String> newSubcategories = [];
        double initialBalance = 0.0;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Category'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 16,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        onChanged: (value) {
                          newCategoryName = value;
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Category name cannot be empty';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                            hintText: "Enter category name"),
                      ),
                      TextField(
                        onChanged: (value) {
                          initialBalance = double.tryParse(value) ?? 0.0;
                        },
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "Enter initial balance",
                          errorStyle: TextStyle(color: Colors.red),
                        ),
                      ),
                      const Text('Subcategories:'),
                      ...newSubcategories.asMap().entries.map(
                            (entry) => Row(
                              children: [
                                Expanded(
                                  child: Text(entry.value),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      newSubcategories.removeAt(entry.key);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                      ElevatedButton(
                        child: const Text('Add Subcategory'),
                        onPressed: () {
                          _addSubcategoryDialog(context, (subcategory) {
                            setState(() {
                              newSubcategories.add(subcategory);
                            });
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        categoryHelper.addGeneralCategory(
                            newCategoryName, newSubcategories, initialBalance);
                      });
                      widget.onCategoryAdded();
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Force a rebuild of the widget after the dialog is closed
      setState(() {});
    });
  }

  void _addSubcategoryDialog(BuildContext context, Function(String) onAdd) {
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newSubcategoryName = '';
        return AlertDialog(
          title: const Text('Add New Subcategory'),
          content: Form(
            key: formKey,
            child: TextFormField(
              onChanged: (value) {
                newSubcategoryName = value;
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Subcategory name cannot be empty';
                }
                return null;
              },
              decoration: const InputDecoration(
                hintText: "Enter subcategory name",
                errorStyle: TextStyle(color: Colors.red),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  onAdd(newSubcategoryName);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _editCategory(int index) {
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String updatedCategoryName =
            categoryHelper.generalCategories[index]['name'];
        List<String> updatedSubcategories = List<String>.from(
            categoryHelper.generalCategories[index]['subcategories']);
        double updatedInitialBalance =
            categoryHelper.generalCategories[index]['initialBalance'];
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Category'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 16,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: updatedCategoryName,
                        onChanged: (value) {
                          updatedCategoryName = value;
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Category name cannot be empty';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: "Enter category name",
                          errorStyle: TextStyle(color: Colors.red),
                        ),
                      ),
                      TextField(
                        onChanged: (value) {
                          updatedInitialBalance =
                              double.tryParse(value) ?? updatedInitialBalance;
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            hintText:
                                "Initial balance: $updatedInitialBalance"),
                      ),
                      const Text('Subcategories:'),
                      ...updatedSubcategories.asMap().entries.map(
                            (entry) => Row(
                              children: [
                                Expanded(
                                  child: Text(entry.value),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _editSubcategoryDialog(
                                        context, entry.key, entry.value,
                                        (newValue) {
                                      setState(() {
                                        updatedSubcategories[entry.key] =
                                            newValue;
                                      });
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      updatedSubcategories.removeAt(entry.key);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                      ElevatedButton(
                        child: const Text('Add Subcategory'),
                        onPressed: () {
                          _addSubcategoryDialog(context, (subcategory) {
                            setState(() {
                              updatedSubcategories.add(subcategory);
                            });
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Update'),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final oldCategoryName =
                          categoryHelper.generalCategories[index]['name'];
                      setState(() {
                        categoryHelper.updateGeneralCategory(
                          index,
                          updatedCategoryName,
                          newSubcategories: updatedSubcategories,
                          newInitialBalance: updatedInitialBalance,
                        );
                      });
                      await _updateTransactionGeneralCategory(
                          oldCategoryName, updatedCategoryName);
                      dailyTabKey.currentState?.loadTransactions();
                      monthlyTabKey.currentState
                          ?.loadTransactionsAndAttendanceFromHive();
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Force a rebuild of the widget after the dialog is closed
      setState(() {});
    });
  }

  void _editSubcategoryDialog(BuildContext context, int index,
      String currentValue, Function(String) onUpdate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String updatedSubcategoryName = currentValue;
        return AlertDialog(
          title: const Text('Edit Subcategory'),
          content: TextField(
            onChanged: (value) {
              updatedSubcategoryName = value;
            },
            decoration: InputDecoration(hintText: currentValue),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                final categoryName =
                    categoryHelper.generalCategories[index]['name'];
                if (updatedSubcategoryName.isNotEmpty) {
                  onUpdate(updatedSubcategoryName);

                  // Update all transactions with the old subcategory name
                  await _updateTransactionGeneralSubCategory(
                      categoryName, currentValue, updatedSubcategoryName);
                  dailyTabKey.currentState?.loadTransactions();
                  monthlyTabKey.currentState
                      ?.loadTransactionsAndAttendanceFromHive();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text(
              'Are you sure you want to delete "${categoryHelper.generalCategories[index]['name']}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                setState(() {
                  categoryHelper.deleteGeneralCategory(index);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addSubcategory(int categoryIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newSubcategoryName = '';
        return AlertDialog(
          title: const Text('Add New Subcategory'),
          content: TextField(
            onChanged: (value) {
              newSubcategoryName = value;
            },
            decoration:
                const InputDecoration(hintText: "Enter subcategory name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (newSubcategoryName.isNotEmpty) {
                  setState(() {
                    categoryHelper.addSubcategoryToGeneral(
                        categoryIndex, newSubcategoryName);
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _editSubcategory(int categoryIndex, int subcategoryIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final categoryName =
            categoryHelper.generalCategories[categoryIndex]['name'];
        final currentSubcategoryName =
            categoryHelper.generalCategories[categoryIndex]['subcategories']
                [subcategoryIndex];
        String updatedSubcategoryName = currentSubcategoryName;

        return AlertDialog(
          title: const Text('Edit Subcategory'),
          content: TextField(
            onChanged: (value) {
              updatedSubcategoryName = value;
            },
            decoration: InputDecoration(hintText: currentSubcategoryName),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                if (updatedSubcategoryName.isNotEmpty) {
                  // First update all transactions with the old subcategory name
                  await _updateTransactionGeneralSubCategory(
                    categoryName,
                    currentSubcategoryName,
                    updatedSubcategoryName,
                  );

                  // Then update the category helper
                  setState(() {
                    categoryHelper.updateSubcategoryInGeneral(
                      categoryIndex,
                      subcategoryIndex,
                      updatedSubcategoryName,
                    );
                  });
                  dailyTabKey.currentState?.loadTransactions();
                  monthlyTabKey.currentState
                      ?.loadTransactionsAndAttendanceFromHive();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteSubcategory(int categoryIndex, int subcategoryIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Subcategory'),
          content: Text(
              'Are you sure you want to delete "${categoryHelper.generalCategories[categoryIndex]['subcategories'][subcategoryIndex]}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                setState(() {
                  categoryHelper.deleteSubcategoryFromGeneral(
                      categoryIndex, subcategoryIndex);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _generalCategoryPdf(String categoryName) async {
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
            return GeneralCategoryPdf(
              categoryName: categoryName,
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

  void _allGeneralCategoryPdf() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      for (var category in categoryHelper.generalCategories) {
        final subcategoryTransactions = <String, List<TransactionModel>>{};

        for (var subcategory in category['subcategories']) {
          final transactions = _filterTransactionsByDateRange(
            picked.start,
            picked.end,
            widget.transactionBox.values
                .where((transaction) =>
                    transaction.categoryName == category['name'])
                .toList(),
          );
          subcategoryTransactions[subcategory] = transactions;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllGeneralSubCatgoryPDf(
              categoryName: category['name'],
              subcategoryTransactions: subcategoryTransactions,
              startDate: picked.start,
              endDate: picked.end,
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateTransactionGeneralCategory(
      String oldCategoryName, String newCategoryName) async {
    final box = widget.transactionBox;

    for (int i = 0; i < box.length; i++) {
      final transaction = box.getAt(i);
      if (transaction?.generalCategory == oldCategoryName) {
        transaction?.generalCategory = newCategoryName;
        await transaction?.save(); // Save the transaction after modifying it
      }
    }
  }

  // Method to update generalSubCategory in transactionBox when a subcategory name is edited
  Future<void> _updateTransactionGeneralSubCategory(String categoryName,
      String oldSubCategoryName, String newSubCategoryName) async {
    final box = widget.transactionBox;

    for (int i = 0; i < box.length; i++) {
      final transaction = box.getAt(i);
      if (transaction?.generalCategory == categoryName &&
          transaction?.generalSubCategory == oldSubCategoryName) {
        transaction?.generalSubCategory = newSubCategoryName;
        await transaction?.save(); // Save the transaction after modifying it
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Scaffold(
      appBar: AppBar(
        title: const Text('General Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addCategory,
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        child: const Icon(Icons.add),
        onPress: () {
          _addCategory();
        },
      ),
      body: ListView.builder(
        itemCount: categoryHelper.generalCategories.length,
        itemBuilder: (context, index) {
          final category = categoryHelper.generalCategories[index];
          return Slidable(
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => _editCategory(index),
                  backgroundColor: AppColor.kPrimary,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                ),
                SlidableAction(
                  onPressed: (_) => _deleteCategory(index),
                  backgroundColor: AppColor.kRed,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                ),
                SlidableAction(
                  onPressed: (_) => _allGeneralCategoryPdf(),
                  backgroundColor: AppColor.kPurple,
                  foregroundColor: Colors.white,
                  icon: Icons.picture_as_pdf,
                ),
              ],
            ),
            child: ExpansionTile(
              leading: Image.asset(
                category['imagePath'],
                width: 30,
              ),
              title: Text(category['name']),
              subtitle: Text(
                  'Initial Balance: $currencySymbol${category['initialBalance'].toStringAsFixed(1)}'),
              children: [
                ...List.generate(
                  category['subcategories']?.length ?? 0,
                  (subIndex) => ListTile(
                    title: Text(category['subcategories'][subIndex]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: AppColor.kPrimary,
                          ),
                          onPressed: () => _editSubcategory(index, subIndex),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: AppColor.kRed,
                          ),
                          onPressed: () => _deleteSubcategory(index, subIndex),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.picture_as_pdf,
                            color: AppColor.kPurple,
                          ),
                          onPressed: () => _generalCategoryPdf(
                              category['subcategories'][subIndex]),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add Subcategory'),
                  onTap: () => _addSubcategory(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
