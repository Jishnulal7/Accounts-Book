import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/category/components/category_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_ce/hive.dart';
import 'category_transaction.dart';

class CategoryTile extends StatefulWidget {
  const CategoryTile({
    super.key,
    required this.transactionCount,
    required this.categoryData,
    required this.transactionBox,
    required this.color,
    required this.selectedMonth,
    required this.title,
    this.onCategoryAdded,
    required this.subcategories,
    this.onCategoryUpdated,
    required this.onCategoryDeleted,
  });

  final String title;
  final int transactionCount;
  final Map<String, dynamic> categoryData;
  final VoidCallback? onCategoryAdded;
  final Function(String, Map<String, dynamic>)? onCategoryUpdated;
  final Box<TransactionModel> transactionBox;
  final Color color;
  final DateTime selectedMonth;
  final List<dynamic> subcategories;
  final Function(String) onCategoryDeleted;
  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  late String originalCategoryName;
  late TextEditingController _editingController;
  late List<String> subcategories;

  final CategoryHelper _categoryHelper = CategoryHelper();
  @override
  void initState() {
    super.initState();
    originalCategoryName = widget.categoryData['name'];
    _editingController = TextEditingController();
    // Initialize subcategories in initState
    if (widget.categoryData['subcategories'] != null) {
      subcategories = List<String>.from(widget.categoryData['subcategories']);
    } else {
      subcategories = List<String>.from(widget.subcategories);
    }
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              _editCategory();
            },
            backgroundColor: AppColor.kPrimary,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) {
              deleteCategory();
            },
            backgroundColor: AppColor.kRed,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        onTap: _showCategoryTransactionCard,
        title: _buildCategoryTitle(),
        leading: _buildLeadingIcon(),
      ),
    );
  }

  Widget _buildCategoryTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.categoryData['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          'No of Transactions: ${widget.transactionCount}',
          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildLeadingIcon() {
    return Image.asset(
      width: 30,
      widget.categoryData['imagePath'] ?? 'assets/categories/category.png',
    );
  }

  void _editCategory() {
    // Initialize the text controller with current category name
    _editingController.text = widget.categoryData['name'];

    // Initialize subcategories if present in categoryData
    setState(() {
      if (widget.categoryData['subcategories'] != null) {
        subcategories = List<String>.from(widget.categoryData['subcategories']);
      } else {
        subcategories = List<String>.from(widget.subcategories);
      }
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _editingController,
                      decoration:
                          const InputDecoration(labelText: 'Category Name'),
                    ),
                    const SizedBox(height: 20),
                    const Text('Subcategories:'),
                    ...subcategories.map((subcat) => Row(
                          children: [
                            Expanded(child: Text(subcat)),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _editSubcategory(subcat, setState),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteSubcategory(subcat, setState),
                            ),
                          ],
                        )),
                    ElevatedButton(
                      child: const Text('Add Subcategory'),
                      onPressed: () => _addSubcategory(setState),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    _saveEditedCategory();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editSubcategory(String oldSubcat, StateSetter setState) {
    TextEditingController controller = TextEditingController(text: oldSubcat);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Subcategory'),
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
                  int index = subcategories.indexOf(oldSubcat);
                  if (index != -1) {
                    subcategories[index] = controller.text;
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

  void _deleteSubcategory(String subcat, StateSetter setState) {
    setState(() {
      subcategories.remove(subcat);
    });
  }

  void _addSubcategory(StateSetter setState) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Subcategory'),
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
                  subcategories.add(controller.text);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _saveEditedCategory() {
    final newCategoryName = _editingController.text;
    final transactionType = widget.title == 'Payment Categories'
        ? TransactionType.payment
        : TransactionType.receipt;

    _categoryHelper.updateCategory(
      originalCategoryName,
      newCategoryName,
      widget.categoryData['imagePath'],
      transactionType,
      newSubcategories: subcategories,
    );

    setState(() {
      widget.categoryData['name'] = newCategoryName;
      widget.categoryData['subcategories'] = subcategories;
    });

    if (widget.onCategoryUpdated != null) {
      widget.onCategoryUpdated!(originalCategoryName, widget.categoryData);
    }
  }

  void deleteCategory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: const Text('Are you sure you want to delete this category?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                final transactionType = widget.title == 'Payment Categories'
                    ? TransactionType.payment
                    : TransactionType.receipt;
                _categoryHelper.deleteCategory(
                    widget.categoryData['name'], transactionType);

                if (widget.onCategoryUpdated != null) {
                  widget.onCategoryUpdated!(
                      widget.categoryData['name'], widget.categoryData);
                }

                widget.onCategoryDeleted(widget.categoryData['name']);
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category deleted')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showCategoryTransactionCard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategoryTransactionCardWidget(
        category: widget.categoryData,
        transactionBox: widget.transactionBox,
        categoryFromTransactions: widget.categoryData['name'],
        categoryType: widget.title,
        color: widget.color,
        selectedMonth: widget.selectedMonth,
      ),
    );
  }
}
