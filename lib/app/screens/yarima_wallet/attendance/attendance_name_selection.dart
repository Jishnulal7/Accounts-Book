import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/add_attendance_subcategory.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/attendance_screen.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/components/attendance_model.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/components/category_service.dart';
import 'package:account_book/app/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class AttendanceNameSelector extends StatefulWidget {
  final List<AttendanceCategory> categories;
  final Function(String, double, double, String) onSubcategorySelected;
  final VoidCallback? onNameAdded;
  final Function(int, Map<String, dynamic>)? onSubcategoryAdded;
  final Function(List<AttendanceCategory>)? onCategoriesUpdated;

  const AttendanceNameSelector({
    super.key,
    required this.categories,
    required this.onSubcategorySelected,
    this.onNameAdded,
    this.onSubcategoryAdded,
    this.onCategoriesUpdated,
  });

  @override
  State<AttendanceNameSelector> createState() => _AttendanceNameSelectorState();
}

class _AttendanceNameSelectorState extends State<AttendanceNameSelector> {
  final CategoryService _categoryService = CategoryService();
  late List<AttendanceCategory> _categories;

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
  }

  @override
  void didUpdateWidget(AttendanceNameSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categories != oldWidget.categories) {
      setState(() {
        _categories = List.from(widget.categories);
      });
    }
  }

  void _showAddSubcategoryBottomSheet(int categoryIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: const AddSubcategoryBottomSheet(),
        );
      },
    ).then((value) async {
      if (value != null) {
        await _handleSubcategoryAdded(
            categoryIndex, value as Map<String, dynamic>);
      }
    });
  }

  Future<void> _handleSubcategoryAdded(
    int categoryIndex,
    Map<String, dynamic> subcategoryData,
  ) async {
    if (subcategoryData['name'].isNotEmpty) {
      setState(() {
        _categories[categoryIndex].subcategories.add(
              Subcategory(
                subcategoryData['name'],
                subcategoryData['initialBalance'],
                subcategoryData['wage'],
                subcategoryData['position'],
              ),
            );
      });

      try {
        await _categoryService.saveCategories(_categories);
        if (widget.onCategoriesUpdated != null) {
          widget.onCategoriesUpdated!(_categories);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving subcategory: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Future<void> _editSubcategory(
  //     int categoryIndex, Subcategory subcategory) async {
  //   final result = await showModalBottomSheet<Map<String, dynamic>>(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (BuildContext context) {
  //       return Container(
  //         padding: EdgeInsets.only(
  //           bottom: MediaQuery.of(context).viewInsets.bottom,
  //           left: 16,
  //           right: 16,
  //           top: 16,
  //         ),
  //         child: AddSubcategoryBottomSheet(
  //           initialName: subcategory.name,
  //           initialBalance: subcategory.openingBalance,
  //           wage: subcategory.wage,
  //           position: subcategory.position,
  //         ),
  //       );
  //     },
  //   );

  //   if (result != null && result['name'].isNotEmpty) {
  //     setState(() {
  //       // Clone the categories list with a new list instance
  //       _categories = List.from(_categories);
  //       AttendanceCategory updatedCategory = _categories[categoryIndex];

  //       // Clone the subcategories list within the specific category
  //       List<Subcategory> updatedSubcategories =
  //           List.from(updatedCategory.subcategories);

  //       // Find and update the specific subcategory
  //       int subIndex = updatedSubcategories.indexOf(subcategory);
  //       if (subIndex != -1) {
  //         updatedSubcategories[subIndex] = Subcategory(
  //           result['name'],
  //           result['initialBalance'],
  //           result['wage'],
  //           result['position'],
  //         );
  //       }

  //       // Assign the modified subcategories list back to the category
  //       _categories[categoryIndex] = AttendanceCategory(
  //         updatedCategory.name,
  //         updatedSubcategories,
  //       );
  //     });

  //     // Save the updated categories and notify
  //     try {
  //       await _categoryService.saveCategories(_categories);
  //       widget.onCategoriesUpdated?.call(_categories);

  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Subcategory updated successfully'),
  //             duration: Duration(seconds: 2),
  //           ),
  //         );
  //       }
  //     } catch (e) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text('Error updating subcategory: ${e.toString()}'),
  //             backgroundColor: Colors.red,
  //             duration: const Duration(seconds: 2),
  //           ),
  //         );
  //       }
  //     }
  //   }
  // }

  // Future<void> _deleteSubcategory(
  //     int categoryIndex, Subcategory subcategory) async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) {
  //       return ConfirmationDialog(
  //         title: 'Delete Subcategory',
  //         content: 'Are you sure you want to delete this subcategory?',
  //         onCancel: () => Navigator.of(context).pop(false),
  //         onConfirm: () => Navigator.of(context).pop(true),
  //         confirmButtonText: 'Delete',
  //         cancelButtonText: 'Cancel',
  //       );
  //     },
  //   );

  //   if (confirmed == true) {
  //     setState(() {
  //       _categories[categoryIndex].subcategories.remove(subcategory);
  //     });

  //     try {
  //       await _categoryService.saveCategories(_categories);
  //       if (widget.onCategoriesUpdated != null) {
  //         widget.onCategoriesUpdated!(_categories);
  //       }

  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Subcategory deleted successfully'),
  //           ),
  //         );
  //       }
  //     } catch (e) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text('Error deleting subcategory: ${e.toString()}'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //       }
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select Attendance Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return ExpansionTile(
                  dense: true,
                  title: Text(_categories[index].name),
                  children: [
                    ..._categories[index].subcategories.map(
                          (subcategory) => ListTile(
                            title: Text(subcategory.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Wage: $currencySymbol${subcategory.wage.toStringAsFixed(1)}'),
                                Text(
                                    'Opening Balance: $currencySymbol${subcategory.openingBalance.toStringAsFixed(1)}'),
                                Text('Position: ${subcategory.position}'),
                              ],
                            ),
                            onTap: () {
                              widget.onSubcategorySelected(
                                '${_categories[index].name} - ${subcategory.name}',
                                subcategory.openingBalance,
                                subcategory.wage,
                                subcategory.name,
                              );
                              Navigator.pop(context);
                            },
                            // trailing: PopupMenuButton<String>(
                            //   onSelected: (String value) async {
                            //     switch (value) {
                            //       case 'select':
                            //         widget.onSubcategorySelected(
                            //           '${_categories[index].name} - ${subcategory.name}',
                            //           subcategory.openingBalance,
                            //           subcategory.wage,
                            //           subcategory.name,
                            //         );
                            //         Navigator.pop(context);
                            //         break;
                            //       case 'edit':
                            //         await _editSubcategory(index, subcategory);
                            //         break;
                            //       case 'delete':
                            //         await _deleteSubcategory(
                            //             index, subcategory);
                            //         break;
                            //     }
                            //   },
                            //   itemBuilder: (BuildContext context) =>
                            //       <PopupMenuEntry<String>>[
                            //     PopupMenuItem<String>(
                            //       value: 'select',
                            //       child: ListTile(
                            //         leading: Icon(Icons.check_circle,
                            //             color: AppColor.kPrimary),
                            //         title: const Text('Select'),
                            //       ),
                            //     ),
                            //     PopupMenuItem<String>(
                            //       value: 'edit',
                            //       child: ListTile(
                            //         leading: Icon(Icons.edit,
                            //             color: AppColor.kGreen),
                            //         title: const Text('Edit'),
                            //       ),
                            //     ),
                            //     PopupMenuItem<String>(
                            //       value: 'delete',
                            //       child: ListTile(
                            //         leading: Icon(Icons.delete,
                            //             color: AppColor.kRed),
                            //         title: const Text('Delete'),
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          ),
                        ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddSubcategoryBottomSheet(index),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Sub Category'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          CustomOutlineButton(
            height: 40,
            width: 130,
            borderRadius: 20,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceScreen(
                    onNameAdded: widget.onNameAdded,
                  ),
                ),
              );
            },
            text: 'Add Category',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
