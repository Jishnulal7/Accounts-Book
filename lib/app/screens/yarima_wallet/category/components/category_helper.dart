import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_ce/hive.dart';


class CategoryHelper {
  List<Map<String, dynamic>> generalCategories;
  final GetStorage _storage = GetStorage();
  final String _receiptCategoriesKey = 'receipt_categories';
  final String _paymentCategoriesKey = 'payment_categories';

  CategoryHelper() : generalCategories = [] {
    _initializeCategories();
    _initializePaymentCategories();
    _initializeReceiptCategories();
  }

  void _initializeCategories() {
    _initializeGeneralCategories();
    _initializePaymentCategories();
    _initializeReceiptCategories();
  }

  void _initializePaymentCategories() {
    final storedCategories = _storage.read<List>(_paymentCategoriesKey);
    if (storedCategories == null) {
      final defaultCategories = _getDefaultCategories(_paymentCategoriesKey);
      _storage.write(_paymentCategoriesKey, defaultCategories);
    }
  }

  void _initializeReceiptCategories() {
    final storedCategories = _storage.read<List>(_receiptCategoriesKey);
    if (storedCategories == null) {
      final defaultCategories = _getDefaultCategories(_receiptCategoriesKey);
      _storage.write(_receiptCategoriesKey, defaultCategories);
    }
  }

  List<Map<String, dynamic>> get receiptCategories {
    return _getCategories(_receiptCategoriesKey);
  }

  List<Map<String, dynamic>> get paymentCategories {
    return _getCategories(_paymentCategoriesKey);
  }

  List<Map<String, dynamic>> _getCategories(String key) {
    final storedCategories = _storage.read<List>(key);
    if (storedCategories != null) {
      return storedCategories
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return _getDefaultCategories(key);
  }

  List<Map<String, dynamic>> _getDefaultCategories(String key) {
    if (key == _paymentCategoriesKey) {
      return [
        {
          'name': 'Food',
          'imagePath': 'assets/categories/fast-food.png',
          'subcategories': [
            'Groceries',
            'Dining out',
            'Fast food',
            'Beverages'
          ],
        },
        {
          'name': 'Shopping',
          'imagePath': 'assets/categories/shopping.png',
          'subcategories': [
            'Clothing',
            'Electronics',
            'Gifts',
            'Online shopping'
          ],
        },
        {
          'name': 'Transport',
          'imagePath': 'assets/categories/taxi(2).png',
          'subcategories': [
            'Public transport',
            'Taxi',
            'Fuel',
            'Car maintenance'
          ],
        },
        {
          'name': 'Bills',
          'imagePath': 'assets/categories/bill.png',
          'subcategories': ['Utilities', 'Phone', 'Internet', 'Subscriptions'],
        },
        {
          'name': 'Gadgets',
          'imagePath': 'assets/categories/smartphone.png',
          'subcategories': ['Phones', 'Computers', 'Accessories', 'Smart home'],
        },
        {
          'name': 'Education',
          'imagePath': 'assets/categories/graduation.png',
          'subcategories': ['Tuition', 'Books', 'Courses', 'Supplies'],
        },
        {
          'name': 'EMI',
          'imagePath': 'assets/categories/loan.png',
          'subcategories': [
            'Home loan',
            'Car loan',
            'Personal loan',
            'Credit card'
          ],
        },
        {
          'name': 'Health',
          'imagePath': 'assets/categories/healthcare-and-medical.png',
          'subcategories': [
            'Doctor visits',
            'Medicine',
            'Insurance',
            'Fitness'
          ],
        },
        {
          'name': 'Household',
          'imagePath': 'assets/categories/house.png',
          'subcategories': ['Furniture', 'Appliances', 'Repairs', 'Decor'],
        },
        {
          'name': 'Rent',
          'imagePath': 'assets/categories/rent.png',
        },
        {
          'name': 'Invest',
          'imagePath': 'assets/categories/investment.png',
          'subcategories': ['Stocks', 'Mutual funds', 'Crypto', 'Real estate'],
        },
        {
          'name': 'Kids',
          'imagePath': 'assets/categories/feeding-bottle.png',
          'subcategories': ['Childcare', 'Toys', 'Clothing', 'Education'],
        },
        {
          'name': 'Leisure',
          'imagePath': 'assets/categories/sports.png',
          'subcategories': ['Entertainment', 'Hobbies', 'Sports', 'Travel'],
        },
        {
          'name': 'Office',
          'imagePath': 'assets/categories/briefcase.png',
          'subcategories': ['Supplies', 'Equipment', 'Software', 'Coworking'],
        },
        {
          'name': 'Travel',
          'imagePath': 'assets/categories/plane.png',
          'subcategories': [
            'Flights',
            'Hotels',
            'Transportation',
            'Activities'
          ],
        },
        {
          'name': 'Subscription',
          'imagePath': 'assets/categories/subscription.png',
          'subcategories': [
            'Streaming',
            'Software',
            'Magazines',
            'Memberships'
          ],
        },
        {
          'name': 'Entertainment',
          'imagePath': 'assets/categories/tickets.png',
          'subcategories': ['Movies', 'Concerts', 'Theater', 'Events'],
        },
        {
          'name': 'Utilities',
          'imagePath': 'assets/categories/lightning-bolt.png',
          'subcategories': ['Electricity', 'Water', 'Gas', 'Internet'],
        },
      ];
    } else if (key == _receiptCategoriesKey) {
      return [
        {
          'name': 'Bills',
          'imagePath': 'assets/categories/bill.png',
        },
        {
          'name': 'Rent',
          'imagePath': 'assets/categories/rent.png',
        },
        {
          'name': 'Invest',
          'imagePath': 'assets/categories/investment.png',
        },
        {
          'name': 'Office',
          'imagePath': 'assets/categories/briefcase.png',
        },
        {
          'name': 'Salary',
          'imagePath': 'assets/categories/money-bag.png',
        },
        {
          'name': 'Rewards',
          'imagePath': 'assets/categories/gift.png',
        },
        {
          'name': 'Bonus',
          'imagePath': 'assets/categories/gift-card.png',
        },
      ];
    } else if (key == _receiptCategoriesKey) {
      return [
        {
          'name': 'Bills',
          'imagePath': 'assets/categories/bill.png',
        },
        {
          'name': 'Rent',
          'imagePath': 'assets/categories/rent.png',
        },
        {
          'name': 'Invest',
          'imagePath': 'assets/categories/investment.png',
        },
        {
          'name': 'Office',
          'imagePath': 'assets/categories/briefcase.png',
        },
        {
          'name': 'Salary',
          'imagePath': 'assets/categories/money-bag.png',
        },
        {
          'name': 'Rewards',
          'imagePath': 'assets/categories/gift.png',
        },
        {
          'name': 'Bonus',
          'imagePath': 'assets/categories/gift-card.png',
        },
      ];
    }
    return [];
  }

  void addCategory(String name, String imagePath, TransactionType type,
      {List<dynamic>? subcategories}) {
    final newCategory = {
      'name': name,
      'imagePath': imagePath,
      'subcategories': subcategories ?? [],
    };
    if (type == TransactionType.payment) {
      final categories = paymentCategories;
      categories.add(newCategory);
      _storage.write(_paymentCategoriesKey, categories);
    } else if (type == TransactionType.receipt) {
      final categories = receiptCategories;
      categories.add(newCategory);
      _storage.write(_receiptCategoriesKey, categories);
    }
  }

  void updateCategory(
      String oldName, String newName, String newImagePath, TransactionType type,
      {List<dynamic>? newSubcategories}) {
    if (type == TransactionType.payment) {
      final categories = paymentCategories;
      final index =
          categories.indexWhere((category) => category['name'] == oldName);
      if (index != -1) {
        categories[index] = {
          'name': newName,
          'imagePath': newImagePath,
          'subcategories':
              newSubcategories ?? categories[index]['subcategories'] ?? [],
        };
        _storage.write(_paymentCategoriesKey, categories);
      }
    } else if (type == TransactionType.receipt) {
      final categories = receiptCategories;
      final index =
          categories.indexWhere((category) => category['name'] == oldName);
      if (index != -1) {
        categories[index] = {
          'name': newName,
          'imagePath': newImagePath,
          'subcategories':
              newSubcategories ?? categories[index]['subcategories'] ?? [],
        };
        _storage.write(_receiptCategoriesKey, categories);
      }
    }
  }

  void deleteCategory(String name, TransactionType type) {
    if (type == TransactionType.payment) {
      final categories = paymentCategories;
      categories.removeWhere((category) => category['name'] == name);
      _storage.write(_paymentCategoriesKey, categories);
    } else if (type == TransactionType.receipt) {
      final categories = receiptCategories;
      categories.removeWhere((category) => category['name'] == name);
      _storage.write(_receiptCategoriesKey, categories);
    }
  }

  // New methods for managing subcategories
  void addSubcategory(
      String categoryName, String subcategoryName, TransactionType type) {
    final categories = (type == TransactionType.payment)
        ? paymentCategories
        : receiptCategories;
    final categoryIndex =
        categories.indexWhere((category) => category['name'] == categoryName);

    if (categoryIndex != -1) {
      if (!categories[categoryIndex].containsKey('subcategories')) {
        categories[categoryIndex]['subcategories'] = [];
      }
      categories[categoryIndex]['subcategories'].add(subcategoryName);

      final storageKey = (type == TransactionType.payment)
          ? _paymentCategoriesKey
          : _receiptCategoriesKey;
      _storage.write(storageKey, categories);
    }
  }

  void updateSubcategory(String categoryName, String oldSubcategoryName,
      String newSubcategoryName, TransactionType type) {
    final categories = (type == TransactionType.payment)
        ? paymentCategories
        : receiptCategories;
    final categoryIndex =
        categories.indexWhere((category) => category['name'] == categoryName);

    if (categoryIndex != -1 &&
        categories[categoryIndex].containsKey('subcategories')) {
      final subcategories = categories[categoryIndex]['subcategories'] as List;
      final subcategoryIndex = subcategories.indexOf(oldSubcategoryName);

      if (subcategoryIndex != -1) {
        subcategories[subcategoryIndex] = newSubcategoryName;

        final storageKey = (type == TransactionType.payment)
            ? _paymentCategoriesKey
            : _receiptCategoriesKey;
        _storage.write(storageKey, categories);
      }
    }
  }

  void deleteSubcategory(
      String categoryName, String subcategoryName, TransactionType type) {
    final categories = (type == TransactionType.payment)
        ? paymentCategories
        : receiptCategories;
    final categoryIndex =
        categories.indexWhere((category) => category['name'] == categoryName);

    if (categoryIndex != -1 &&
        categories[categoryIndex].containsKey('subcategories')) {
      final subcategories = categories[categoryIndex]['subcategories'] as List;
      subcategories.remove(subcategoryName);

      final storageKey = (type == TransactionType.payment)
          ? _paymentCategoriesKey
          : _receiptCategoriesKey;
      _storage.write(storageKey, categories);
    }
  }

  void _initializeGeneralCategories() {
    final storedCategories = _storage.read<List>('generalCategories');
    if (storedCategories != null && storedCategories.isNotEmpty) {
      generalCategories = storedCategories
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else {
      generalCategories = [
        {
          'name': 'General',
          'imagePath': 'assets/categories/category.png',
          'subcategories': [],
          'initialBalance': 0.0,
        }
      ];
      _saveGeneralCategories();
    }
  }

  void loadGeneralCategories() {
    final storedCategories = _storage.read<List>('generalCategories');
    if (storedCategories != null && storedCategories.isNotEmpty) {
      generalCategories = storedCategories
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
  }

  void _saveGeneralCategories() {
    _storage.write('generalCategories', generalCategories);
  }

  void addGeneralCategory(
      String name, List<String> subcategories, double initialBalance) {
    generalCategories.add({
      'name': name,
      'imagePath': 'assets/categories/category.png',
      'subcategories': subcategories,
      'initialBalance': initialBalance,
    });
    _saveGeneralCategories();
  }

  void updateGeneralCategory(int index, String newName,
      {List<String>? newSubcategories, double? newInitialBalance}) {
    if (index >= 0 && index < generalCategories.length) {
      generalCategories[index]['name'] = newName;
      if (newSubcategories != null) {
        generalCategories[index]['subcategories'] = newSubcategories;
      }
      if (newInitialBalance != null) {
        generalCategories[index]['initialBalance'] = newInitialBalance;
      }
      _saveGeneralCategories();
    }
  }

  void deleteGeneralCategory(int index) {
    if (index >= 0 && index < generalCategories.length) {
      generalCategories.removeAt(index);
      _saveGeneralCategories();
    }
  }

  void addSubcategoryToGeneral(int index, String subcategory) {
    if (index >= 0 && index < generalCategories.length) {
      if (!generalCategories[index].containsKey('subcategories')) {
        generalCategories[index]['subcategories'] = [];
      }
      generalCategories[index]['subcategories'].add(subcategory);
      _saveGeneralCategories();
    }
  }

  void updateSubcategoryInGeneral(
      int categoryIndex, int subcategoryIndex, String newSubcategory) {
    if (categoryIndex >= 0 && categoryIndex < generalCategories.length) {
      if (generalCategories[categoryIndex].containsKey('subcategories') &&
          subcategoryIndex >= 0 &&
          subcategoryIndex <
              generalCategories[categoryIndex]['subcategories'].length) {
        generalCategories[categoryIndex]['subcategories'][subcategoryIndex] =
            newSubcategory;
        _saveGeneralCategories();
      }
    }
  }

  void deleteSubcategoryFromGeneral(int categoryIndex, int subcategoryIndex) {
    if (categoryIndex >= 0 && categoryIndex < generalCategories.length) {
      if (generalCategories[categoryIndex].containsKey('subcategories') &&
          subcategoryIndex >= 0 &&
          subcategoryIndex <
              generalCategories[categoryIndex]['subcategories'].length) {
        generalCategories[categoryIndex]['subcategories']
            .removeAt(subcategoryIndex);
        _saveGeneralCategories();
      }
    }
  }

  List<TransactionModel> getCategoryFromTransactions(
    DateTime selectedMonth,
    Box<TransactionModel> transactionBox,
    List<TransactionType> types,
    String category,
  ) {
    try {
      return transactionBox.values
          .where((transaction) =>
              types.contains(transaction.transactionType) &&
              transaction.categoryName == category)
          .toList();
    } catch (e) {
      debugPrint('Error getting category from transactions: $e');
      return [];
    }
  }

  int getNumberOfTransactionsPerCategory(
    String categoryName,
    TransactionType transactionType,
    Box<TransactionModel> transactionBox,
  ) {
    try {
      return transactionBox.values
          .where((transaction) =>
              transaction.categoryName == categoryName &&
              transaction.transactionType == transactionType)
          .length;
    } catch (e) {
      debugPrint('Error getting number of transactions: $e');
      return 0;
    }
  }

  final allTransactionTypes = [
    TransactionType.payment,
    TransactionType.receipt,
  ];
}
