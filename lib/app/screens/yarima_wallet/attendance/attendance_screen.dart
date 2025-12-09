import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/add_attendance_category.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/add_attendance_subcategory.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/components/attendance_model.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/components/category_service.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/all_attendance_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/attendance_pdf.dart';
import 'package:account_book/app/widgets/custom_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, this.onNameAdded});
  final VoidCallback? onNameAdded;

  @override
  AttendanceScreenState createState() => AttendanceScreenState();
}

class AttendanceScreenState extends State<AttendanceScreen> {
  final CategoryService _categoryService = CategoryService();
  late List<AttendanceCategory> categories;

  @override
  void initState() {
    super.initState();
    categories = _categoryService.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Categories'),
        actions: [
          IconButton(
            onPressed: _addMainCategory,
            icon: const Icon(Icons.add),
            tooltip: 'Add Main Category',
          ),
        ],
      ),
      body: categories.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryTile(index);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMainCategory,
        tooltip: 'Add Main Category',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No categories yet',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _addMainCategory,
            child: const Text('Add Your First Category'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(int index) {
    return GestureDetector(
      child: Slidable(
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
              onPressed: (_) => _deleteWindow(index),
              backgroundColor: AppColor.kRed,
              foregroundColor: Colors.white,
              icon: Icons.delete,
            ),
            SlidableAction(
              onPressed: (_) => _allAttendancePDF(),
              backgroundColor: AppColor.kPurple,
              foregroundColor: Colors.white,
              icon: Icons.picture_as_pdf,
            ),
          ],
        ),
        child: ExpansionTile(
          leading: Image.asset(
            'assets/categories/profile.png',
            width: 35,
          ),
          title: Text(
            categories[index].name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            if (categories[index].subcategories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text('No subcategories'),
              )
            else
              ...categories[index].subcategories.map(
                    (subcategory) => _buildSubcategoryTile(index, subcategory),
                  ),
            ListTile(
              title: const Text('Add Subcategory',
                  style: TextStyle(color: Colors.blue)),
              leading: const Icon(Icons.add, color: Colors.blue),
              onTap: () => _addSubcategory(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryTile(int index, Subcategory subcategory) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return ListTile(
      title: Text(subcategory.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wage: $currencySymbol${subcategory.wage.toStringAsFixed(1)}'),
          Text(
              'Opening Balance: $currencySymbol${subcategory.openingBalance.toStringAsFixed(1)}'),
          Text('Position: ${subcategory.position}'),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (String value) {
          if (value == 'edit') {
            _editSubcategory(index, subcategory);
          } else if (value == 'delete') {
            _deleteSubcategory(index, subcategory);
          } else if (value == 'PDF') {
            _subCategoryPdf(categories[index], subcategory);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit, color: AppColor.kGreen),
              title: const Text('Edit'),
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: AppColor.kRed),
              title: const Text('Delete'),
            ),
          ),
          PopupMenuItem<String>(
            value: 'PDF',
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf, color: AppColor.kPrimary),
              title: const Text('PDF'),
            ),
          ),
        ],
      ),
    );
  }

  void _subCategoryPdf(
      AttendanceCategory category, Subcategory subcategory) async {
    // Fetch attendance records for this subcategory
    List<AttendanceModel> attendanceRecords =
        await fetchAttendanceRecords(category.name, subcategory.name);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttendancePDF(
            categoryName: category.name,
            subcategoryName: subcategory.name,
            attendanceRecords: attendanceRecords,
            startDate: picked.start,
            endDate: picked.end,
          ),
        ),
      );
    }
  }

  Future<List<AttendanceModel>> fetchAttendanceRecords(
      String categoryName, String subcategoryName) async {
    if (!Hive.isBoxOpen('attendanceBox')) {
      await Hive.openBox<AttendanceModel>('attendanceBox');
    }
    final box = Hive.box<AttendanceModel>('attendanceBox');

    // Fetch all records
    List<AttendanceModel> allRecords =
        box.values.toList().cast<AttendanceModel>();

    // Filter records based on category and subcategory
    List<AttendanceModel> filteredRecords = allRecords.where((record) {
      return record.name == categoryName || record.subName == subcategoryName;
    }).toList();
    filteredRecords.sort((a, b) => a.date.compareTo(b.date));

    // Calculate running balance
    double runningBalance = 0;
    for (var record in filteredRecords) {
      runningBalance += record.wage + record.extraCharges - record.payment;
      record.balance = runningBalance;
    }

    return filteredRecords;
  }

  void _editSubcategory(int categoryIndex, Subcategory subcategory) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: AddSubcategoryBottomSheet(
            initialName: subcategory.name,
            initialBalance: subcategory.openingBalance,
            wage: subcategory.wage,
            position: subcategory.position,
          ),
        );
      },
    );

    if (result != null && result['name'].isNotEmpty) {
      setState(() {
        categories[categoryIndex].subcategories =
            categories[categoryIndex].subcategories.map((sub) {
          if (sub == subcategory) {
            return Subcategory(result['name'], result['initialBalance'],
                result['wage'], result['position']);
          }
          return sub;
        }).toList();
      });
      await _categoryService.saveCategories(categories);
    }
  }

  void _deleteSubcategory(int categoryIndex, Subcategory subcategory) async {
    setState(() {
      categories[categoryIndex].subcategories.remove(subcategory);
    });
    await _categoryService.saveCategories(categories);
  }

  void _allAttendancePDF() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AllCategoryAttendancePDF(
            categories: categories,
            startDate: picked.start,
            endDate: picked.end,
          ),
        ),
      );
    }
  }

  void _editCategory(int categoryIndex) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: AddCategoryBottomSheet(
            onNameAdded: widget.onNameAdded,
            initialName: categories[categoryIndex].name,
            initialSubcategories: categories[categoryIndex]
                .subcategories
                .map((sub) => {
                      'name': sub.name,
                      'initialBalance': sub.openingBalance,
                      'wage': sub.wage,
                      'position': sub.position,
                    })
                .toList(),
          ),
        );
      },
    );

    if (result != null && result['name'].isNotEmpty) {
      setState(() {
        categories[categoryIndex].name = result['name'];
        categories[categoryIndex].subcategories.clear();
        for (var sub in result['subcategories']) {
          categories[categoryIndex].subcategories.add(
                Subcategory(sub['name'], sub['initialBalance'], sub['wage'],
                    sub['position']),
              );
        }
      });
      await _categoryService.saveCategories(categories);
    }
  }

  _deleteWindow(int categoryIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return ConfirmationDialog(
          title: 'Delete Category',
          content: 'Are you sure you want to delete this Category?',
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => _deleteCategory(categoryIndex),
          confirmButtonText: 'Delete',
          cancelButtonText: 'Cancel',
        );
      },
    );
  }

  void _deleteCategory(int categoryIndex) async {
    setState(() {
      categories.removeAt(categoryIndex);
    });
    await _categoryService.saveCategories(categories);
    Navigator.pop(context);
  }

  void _addMainCategory() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: const AddCategoryBottomSheet());
      },
    );

    if (result != null && result['name'].isNotEmpty) {
      setState(() {
        List<Subcategory> subcategories = [];
        for (var sub in (result['subcategories'] as List<dynamic>? ?? [])) {
          subcategories.add(
            Subcategory(
                sub['name'] as String? ?? '',
                (sub['initialBalance'] as num?)?.toDouble() ?? 0.0,
                (sub['wage'] as num?)?.toDouble() ?? 0.0,
                sub['position'] as String? ?? ''),
          );
        }

        categories
            .add(AttendanceCategory(result['name'] as String, subcategories));
      });
      await _categoryService.saveCategories(categories);
    }
  }

  void _addSubcategory(int categoryIndex) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
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
    );

    if (result != null) {
      _handleSubcategoryAdded(categoryIndex, result);
    }
  }

  void _handleSubcategoryAdded(
      int categoryIndex, Map<String, dynamic> subcategoryData) async {
    if (subcategoryData['name'].isNotEmpty) {
      setState(() {
        categories[categoryIndex].subcategories.add(
              Subcategory(
                subcategoryData['name'],
                subcategoryData['initialBalance'],
                subcategoryData['wage'],
                subcategoryData['position'],
              ),
            );
      });
      await _categoryService.saveCategories(categories);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subcategory added successfully')),
        );
      }
    }
  }
}
