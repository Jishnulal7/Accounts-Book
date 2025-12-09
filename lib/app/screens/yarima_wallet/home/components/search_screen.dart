import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/color_helper.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_transaction_card.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/attendance_transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SearchResultsScreen extends StatefulWidget {
  final List<dynamic> initialItems;
  final String initialQuery;

  const SearchResultsScreen({
    super.key,
    required this.initialItems,
    required this.initialQuery,
  });

  @override
  SearchResultsScreenState createState() => SearchResultsScreenState();
}

class SearchResultsScreenState extends State<SearchResultsScreen> {
  late List<dynamic> _displayedItems;
  late TextEditingController _searchController;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _displayedItems = widget.initialItems;
    _filterItems();
    _searchController.addListener(_filterItems);
  }

  void _filterItems() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _displayedItems = widget.initialItems.where((item) {
        return _basicTextSearch(item, query) &&
            _dateRangeFilter(item) &&
            _categoryFilter(item);
      }).toList();
    });
  }

  bool _basicTextSearch(dynamic item, String query) {
    if (query.isEmpty) return true;
    if (item is TransactionModel) {
      final searchableFields = [
        DateFormat('yyyy-MM-dd').format(item.date),
        item.amount.toString(),
        item.fromAccount.toLowerCase(),
        item.categoryName?.toLowerCase() ?? item.generalCategory ?? '',
        item.subCategory?.toLowerCase() ?? item.generalSubCategory ?? '',
        item.description.toLowerCase(),
      ];
      return searchableFields.any((field) => field.contains(query));
    } else if (item is AttendanceModel) {
      final searchableFields = [
        DateFormat('yyyy-MM-dd').format(item.date),
        item.name.toLowerCase(),
        item.siteName.toLowerCase(),
        item.wage.toString(),
        item.description.toLowerCase(),
      ];
      return searchableFields.any((field) => field.contains(query));
    }
    return false;
  }

  bool _dateRangeFilter(dynamic item) {
    if (_startDate == null && _endDate == null) return true;
    final itemDate =
        item is TransactionModel ? item.date : (item as AttendanceModel).date;
    if (_startDate != null && itemDate.isBefore(_startDate!)) {
      return false;
    }
    if (_endDate != null && itemDate.isAfter(_endDate!)) return false;
    return true;
  }

  bool _categoryFilter(dynamic item) {
    if (_selectedCategory == null) return true;
    if (item is TransactionModel) {
      return item.categoryName?.toLowerCase() ==
          _selectedCategory?.toLowerCase();
    } else if (item is AttendanceModel) {
      return item.categoryName!.toLowerCase() ==
          _selectedCategory?.toLowerCase();
    }
    return false;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Transactions'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDatePicker('Start Date', _startDate,
                        (date) => setState(() => _startDate = date)),
                    _buildDatePicker('End Date', _endDate,
                        (date) => setState(() => _endDate = date)),
                    // _buildCategoryDropdown(setState),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Clear'),
                  onPressed: () => setState(() {
                    _startDate = null;
                    _endDate = null;
                    _selectedCategory = null;
                  }),
                ),
                ElevatedButton(
                  child: const Text('Apply'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _filterItems();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDatePicker(
      String title, DateTime? date, Function(DateTime?) onDateSelected) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
          date == null ? 'Not set' : DateFormat('yyyy-MM-dd').format(date)),
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
    );
  }

  // Widget _buildCategoryDropdown(StateSetter setState) {
  //   final categories = [
  //     null,
  //     ...widget.initialTransactions.map((e) => e.categoryName).toSet()
  //   ];
  //   return DropdownButtonFormField<String>(
  //     value: _selectedCategory,
  //     onChanged: (newValue) => setState(() => _selectedCategory = newValue),
  //     items: categories
  //         .map((category) => DropdownMenuItem(
  //               value: category,
  //               child: Text(category ?? 'All Categories'),
  //             ))
  //         .toList(),
  //     decoration: const InputDecoration(labelText: 'Category'),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search transactions and attendance...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _filterItems();
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _displayedItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No items found.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _searchController.clear();
                      _startDate = null;
                      _endDate = null;
                      _selectedCategory = null;
                      _filterItems();
                    },
                    child: const Text('Clear all filters'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _displayedItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _displayedItems[index];
                if (item is TransactionModel) {
                  return _buildTransactionListTile(item);
                } else if (item is AttendanceModel) {
                  return _buildAttendanceListTile(item);
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }

  Widget _buildTransactionListTile(TransactionModel transaction) {
    return ListTile(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AccountTransactionCard(
            transaction: transaction,
            color: ColorHelper().darkorWhite(context),
            isEditable: false,
          ),
        );
      },
      leading: _buildLeadingWidget(transaction),
      title: _buildTitle(transaction),
      subtitle: _buildSubtitle(transaction),
      trailing: _buildAmount(transaction),
    );
  }

  Widget _buildAttendanceListTile(AttendanceModel attendance) {
    return ListTile(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AttendanceTransactionCard(
              attendance: attendance,
              color: ColorHelper().darkorWhite(context),
              isEditable: false,
            );
          },
        );
      },
      leading: CircleAvatar(
        backgroundColor: attendance.isPresent ? Colors.green : Colors.red,
        child: Icon(attendance.isPresent ? Icons.check : Icons.close,
            color: Colors.white),
      ),
      title: Text(attendance.name,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('MMM dd, yyyy').format(attendance.date)),
          Text(
              '${attendance.siteName} • ${attendance.isPresent ? "Present" : "Absent"}'),
        ],
      ),
      trailing: Text(
        '${Provider.of<CurrencyNotifier>(context).currencySymbol}${attendance.payment}',
        style: TextStyle(
          color: AppColor.kRed,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSubtitle(TransactionModel transaction) {
    if (transaction.transactionType == TransactionType.transfer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('MMM dd, yyyy').format(transaction.date)),
          Text(transaction.description)
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('MMM dd, yyyy').format(transaction.date)} • ${transaction.generalCategory ?? transaction.categoryName}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(transaction.description)
        ],
      );
    }
  }

  Widget _buildLeadingWidget(TransactionModel transaction) {
    if (transaction.transactionType == TransactionType.transfer) {
      return CircleAvatar(
        backgroundColor: Colors.blue,
        child: Image.asset('assets/categories/swap-hori.png'),
      );
    } else {
      return CircleAvatar(
        // backgroundColor: ColorHelper().getColorForCategory(transaction.categoryName),
        child: transaction.iconData != null
            ? Image.asset(
                transaction.iconData.toString(),
                width: 30,
              )
            : const Icon(Icons.category, color: Colors.white),
      );
    }
  }

  Widget _buildTitle(TransactionModel transaction) {
    if (transaction.transactionType == TransactionType.transfer) {
      return Row(
        children: [
          Text(
            transaction.fromAccount,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Icon(Icons.arrow_circle_right_outlined),
          Text(
            transaction.toAccount,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      return Text(
        transaction.fromAccount,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }
  }

  Widget _buildAmount(TransactionModel transaction) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    if (transaction.transactionType == TransactionType.transfer) {
      return Text(
        '$currencySymbol${transaction.amount}',
        style: TextStyle(
          color: AppColor.kPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    } else if (transaction.transactionType == TransactionType.receipt) {
      return Text(
        '$currencySymbol${transaction.amount}',
        style: TextStyle(
          color: AppColor.kGreen,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    } else {
      return Text(
        '$currencySymbol${transaction.amount}',
        style: TextStyle(
          color: AppColor.kRed,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
