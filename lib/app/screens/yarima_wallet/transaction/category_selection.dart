import 'package:account_book/app/data/helpers/icon_helper.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/category/category_screen.dart';
import 'package:account_book/app/screens/yarima_wallet/category/components/category_helper.dart';
import 'package:account_book/app/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategorySelection extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final TransactionType transactionType;
  final Function(String, String?, String,
      {String? generalCategory, String? generalSubCategory}) onCategorySelected;
  final Function(String, String) onCategoryCreated;
  final VoidCallback? onCategoryAdded;
  final Box<TransactionModel> transactionBox;
  final String? previouslySelectedCategory;
  final DateTime selectedDailyDate;

  const CategorySelection({
    super.key,
    required this.categories,
    required this.transactionType,
    required this.onCategorySelected,
    this.onCategoryAdded,
    this.previouslySelectedCategory,
    required this.selectedDailyDate,
    required this.onCategoryCreated,
    required this.transactionBox,
  });

  @override
  CategorySelectionState createState() => CategorySelectionState();
}

class CategorySelectionState extends State<CategorySelection> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allCategories = [];
  List<Map<String, dynamic>> filteredCategories = [];
  List<Map<String, dynamic>> customCategories = [];
  List<Map<String, dynamic>> allGeneralCategories = [];
  List<Map<String, dynamic>> filteredGeneralCategories = [];

  String? expandedCategory;
  String? lastSelectedCategory;
  ScrollController scrollController = ScrollController();
  final CategoryHelper categoryHelper = CategoryHelper();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadLastSelectedCategory();
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredCategories = List.from(allCategories);
        filteredGeneralCategories = List.from(allGeneralCategories);
      } else {
        // Filter regular categories
        filteredCategories = allCategories.where((category) {
          final categoryNameMatches =
              category['name'].toString().toLowerCase().contains(query);
          final subcategoriesMatch = (category['subcategories']
                      as List<dynamic>?)
                  ?.any((subCategory) =>
                      subCategory.toString().toLowerCase().contains(query)) ??
              false;
          return categoryNameMatches || subcategoriesMatch;
        }).toList();

        // Filter general categories
        filteredGeneralCategories = allGeneralCategories.where((category) {
          final categoryNameMatches =
              category['name'].toString().toLowerCase().contains(query);
          final subcategoriesMatch = (category['subcategories']
                      as List<dynamic>?)
                  ?.any((subCategory) =>
                      subCategory.toString().toLowerCase().contains(query)) ??
              false;
          return categoryNameMatches || subcategoriesMatch;
        }).toList();
      }
      _sortCategories(filteredCategories);
      _sortCategories(filteredGeneralCategories);
    });
  }

  void _loadCategories() {
    final receiptBox = GetStorage('receipt_categories');
    final paymentBox = GetStorage('payment_categories');
    final receiptKeys = receiptBox.getKeys()?.cast<String>() ?? [];
    final paymentKeys = paymentBox.getKeys()?.cast<String>() ?? [];

    // Load categories based on transaction type
    if (widget.transactionType == TransactionType.receipt) {
      allCategories = [
        ...customCategories,
        ..._convertKeysToCategoryList(receiptKeys, receiptBox),
        ...categoryHelper.receiptCategories
            .map((c) => _mergeWithStoredData(c, receiptBox)),
      ];
    } else {
      allCategories = [
        ...customCategories,
        ..._convertKeysToCategoryList(paymentKeys, paymentBox),
        ...categoryHelper.paymentCategories
            .map((c) => _mergeWithStoredData(c, paymentBox)),
      ];
    }

    // Remove duplicates
    allCategories =
        allCategories.fold<List<Map<String, dynamic>>>([], (prev, element) {
      if (!prev.any((e) => e['name'] == element['name'])) {
        prev.add(element);
      }
      return prev;
    });

    allGeneralCategories = List.from(categoryHelper.generalCategories);

    setState(() {
      filteredCategories = List.from(allCategories);
      filteredGeneralCategories = List.from(allGeneralCategories);
      _sortCategories(filteredCategories);
      _sortCategories(filteredGeneralCategories);
    });
  }

  Map<String, dynamic> _mergeWithStoredData(
      Map<String, dynamic> defaultCategory, GetStorage box) {
    final storedData =
        box.read(defaultCategory['name']) as Map<dynamic, dynamic>?;
    if (storedData != null) {
      return {
        ...defaultCategory,
        ...storedData,
        'isDefault': true,
      };
    }
    return {...defaultCategory, 'isDefault': true};
  }

  List<Map<String, dynamic>> _convertKeysToCategoryList(
      Iterable<String> keys, GetStorage box) {
    return keys.map((key) {
      final categoryData = box.read(key) as Map<dynamic, dynamic>?;
      String imagePath = categoryData?['imagePath'] ??
          CustomIcons().getImagePathForCategory(key);

      final subcategories =
          (categoryData?['subcategories'] as List<dynamic>?) ?? [];

      return {
        'name': key,
        'imagePath': imagePath,
        'subcategories': subcategories,
      };
    }).toList();
  }

  void _sortCategories(List<Map<String, dynamic>> categories) {
    categories.sort((a, b) {
      if (a['name'] == lastSelectedCategory) return -1;
      if (b['name'] == lastSelectedCategory) return 1;
      return a['name'].toString().compareTo(b['name'].toString());
    });
  }

  Future<void> _loadLastSelectedCategory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastSelectedCategory = prefs.getString('lastSelectedCategory');
      _sortCategories(filteredCategories);
      _sortCategories(filteredGeneralCategories);
    });
  }

  Future<void> _saveLastSelectedCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSelectedCategory', category);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Category',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search categories',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filteredCategories.length +
                  filteredGeneralCategories.length +
                  1,
              itemBuilder: (context, index) {
                if (index < filteredCategories.length) {
                  return _buildCategoryTile(filteredCategories[index]);
                } else if (index == filteredCategories.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'General Categories',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                } else {
                  final generalCategoryIndex =
                      index - filteredCategories.length - 1;
                  if (generalCategoryIndex < filteredGeneralCategories.length) {
                    return _buildCategoryTile(
                        filteredGeneralCategories[generalCategoryIndex]);
                  }
                  return null;
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: CustomOutlineButton(
              onTap: () => _navigateToCategorySection(context),
              text: 'Add Categories',
              iconData: Icons.add,
              height: 46,
              width: 150,
              borderRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(Map<String, dynamic> category) {
    final subcategories = category['subcategories'] as List<dynamic>?;

    return ListTile(
      leading: Image.asset(
        category['imagePath'],
        height: 30,
        width: 30,
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
          return const Icon(Icons.error);
        },
      ),
      title: Text(category['name'].toString()),
      trailing: subcategories != null && subcategories.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.expand_more),
              onPressed: () => _showSubcategoriesBottomSheet(context, category),
            )
          : null,
      onTap: () => _selectCategory(
          category['name'].toString(), null, category['imagePath']),
    );
  }

  void _showSubcategoriesBottomSheet(
      BuildContext context, Map<String, dynamic> category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.75,
        expand: false,
        builder: (_, scrollController) {
          return Column(
            children: [
              Container(
                height: 5,
                width: 40,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Text(
                category['name'].toString(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: category['subcategories'].length,
                  itemBuilder: (context, index) {
                    final subcategory = category['subcategories'][index];
                    return ListTile(
                      title: Text(subcategory.toString()),
                      onTap: () {
                        _selectCategory(
                          category['name'].toString(),
                          subcategory.toString(),
                          category['imagePath'],
                        );
                        Navigator.pop(context);
                      },
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

  void _selectCategory(
      String categoryName, String? subcategoryName, String imagePath) {
    String? generalCategory;
    String? generalSubCategory;
    final isGeneralCategory = filteredGeneralCategories
        .any((category) => category['name'] == categoryName);

    if (isGeneralCategory) {
      generalCategory = categoryName;
      generalSubCategory = subcategoryName;
      categoryName = '';
    }

    widget.onCategorySelected(
      categoryName,
      subcategoryName,
      imagePath,
      generalCategory: generalCategory,
      generalSubCategory: generalSubCategory,
    );

    _saveLastSelectedCategory(
        isGeneralCategory ? generalCategory! : categoryName);
    Navigator.pop(context);
  }

  void _navigateToCategorySection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryScreen(
          selectDate: widget.selectedDailyDate,
          onCategoryAdded: _onCategoryAdded,
        ),
      ),
    );
  }

  void _onCategoryAdded() {
    _loadCategories();
    widget.onCategoryAdded?.call();
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
