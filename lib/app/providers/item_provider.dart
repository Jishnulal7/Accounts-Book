import 'package:account_book/app/data/model/purchase_model.dart';
import 'package:account_book/app/data/model/sale_model.dart';
import 'package:account_book/app/data/model/stock_adjustment_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:account_book/app/data/model/item_model.dart';
import 'package:uuid/uuid.dart';

class ItemProvider with ChangeNotifier {
  List<ItemModel> _items = [];
  ItemModel _item = ItemModel();
  bool _isLoading = true;
  bool _lowStockQuantityAlert = false;
  bool _isCustomerSelected = true;
  bool _isService = false;
  DateTime _selectMonth = DateTime.now();
  String _selectedUnit = 'None';
  String _selectedTaxRate = 'None';
  final Map<String, int> _openingStocks = {};
  Map<String, int> get openingStocks => _openingStocks;
  List<ItemModel> get items => _items;
  ItemModel get item => _item;
  bool get isLoading => _isLoading;
  bool get lowStockQuantityAlert => _lowStockQuantityAlert;
  bool get isCustomerSelected => _isCustomerSelected;
  bool get isService => _isService;
  DateTime get selectMonth => _selectMonth;
  String get selectedUnit => _selectedUnit;
  String get selectedTaxRate => _selectedTaxRate;
  List<Map<String, dynamic>> allTransactions = [];
  bool showGoods = true;
  bool showServices = true;
  bool showOutOfStock = true;
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setLowStockQuantityAlert(bool value) {
    _lowStockQuantityAlert = value;
    notifyListeners();
  }

  void setIsCustomerSelected(bool value) {
    _isCustomerSelected = value;
    _isService = !value;
    notifyListeners();
  }

  void setSelectMonth(DateTime value) {
    _selectMonth = value;
    notifyListeners();
  }

  void setSelectedUnit(String value) {
    _selectedUnit = value;
    notifyListeners();
  }

  void setSelectedTaxRate(String value) {
    _selectedTaxRate = value;
    notifyListeners();
  }

  Future<void> initializeOpeningStocks() async {
    // Open a separate box to store opening stock values
    final openingStockBox = await Hive.openBox('openingStockBox');

    // Get all items
    final itemBox = await Hive.openBox<ItemModel>('itemBox');
    final allItems = itemBox.values.toList();

    // For each item, set opening stock if not already set
    for (var item in allItems) {
      if (item.id != null) {
        // Check if opening stock is already stored
        if (!openingStockBox.containsKey(item.id)) {
          // Store initial stock as opening stock
          await openingStockBox.put(item.id, item.stockQuantity ?? 0);
        }

        // Load into memory
        _openingStocks[item.id!] = openingStockBox.get(item.id);
      }
    }
  }

// 1. Modify the fetchItems method to initialize opening stocks for all items
  Future<void> fetchItems() async {
    try {
      setLoading(true);
      final itemBox = await Hive.openBox<ItemModel>('itemBox');

      // Get all items first
      List<ItemModel> allItems = itemBox.values.toList();

      await initializeOpeningStocks();

      // Apply filters
      _items = allItems.where((item) {
        bool showItem = true;

        // Filter by item type
        if (!showGoods && item.itemType == 'Goods') showItem = false;
        if (!showServices && item.itemType == 'Service') showItem = false;

        // Filter out of stock items
        if (!showOutOfStock &&
            (item.stockQuantity ?? 0) <= 0 &&
            item.itemType == 'Goods') {
          showItem = false;
        }

        return showItem;
      }).toList();

      setLoading(false);
      notifyListeners();
    } catch (e) {
      setLoading(false);
      debugPrint('Error fetching items: $e');
      rethrow;
    }
  }

  Future<void> fetchItemDetails(String itemId) async {
    setLoading(true);
    final itemBox = await Hive.openBox<ItemModel>('itemBox');
    final openingStockBox = await Hive.openBox('openingStockBox');

    final itemFromBox = itemBox.get(itemId);
    if (itemFromBox != null) {
      _item = itemFromBox;

      // Load opening stock from the dedicated box
      if (openingStockBox.containsKey(itemId)) {
        _openingStocks[itemId] = openingStockBox.get(itemId);
      } else {
        // If not found, initialize it and store
        _openingStocks[itemId] = itemFromBox.stockQuantity ?? 0;
        await openingStockBox.put(itemId, itemFromBox.stockQuantity ?? 0);
      }

      // Rest of your existing code...
      _lowStockQuantityAlert = _item.lowStockQuantityAlert ?? false;
      _isCustomerSelected = _item.itemType == 'Goods';
      _isService = !_isCustomerSelected;
      _selectMonth = _item.date ?? DateTime.now();
      _selectedUnit = _item.unit ?? 'None';
      _selectedTaxRate = _item.gst ?? 'None';
    }
    setLoading(false);
  }

  Future<bool> hasTransactions(String itemId) async {
    try {
      // Get the item first to find its name
      final itemBox = await Hive.openBox<ItemModel>('itemBox');
      final item = itemBox.get(itemId);
      if (item == null) return false;

      final itemName = item.itemName;
      if (itemName == null) return false;

      // Check purchases
      final purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
      for (var purchase in purchaseBox.values) {
        for (var purchaseItem in purchase.item) {
          if (purchaseItem.itemName == itemName) {
            return true; // Found in purchases
          }
        }
      }

      // Check sales
      final saleBox = await Hive.openBox<SaleModel>('saleBox');
      for (var sale in saleBox.values) {
        for (var saleItem in sale.item) {
          if (saleItem.itemName == itemName) {
            return true; // Found in sales
          }
        }
      }

      return false; // No transactions found
    } catch (e) {
      debugPrint('Error checking for transactions: $e');
      return false; // Default to false on error
    }
  }

// Modified deleteItem method in ItemProvider class
  Future<bool> deleteItem(String itemId) async {
    try {
      setLoading(true);

      // First check if the item has associated transactions
      bool hasAssociatedTransactions = await hasTransactions(itemId);
      if (hasAssociatedTransactions) {
        setLoading(false);
        return false; // Cannot delete - has transactions
      }

      // Delete from Hive
      final itemBox = await Hive.openBox<ItemModel>('itemBox');
      await itemBox.delete(itemId);

      // Also delete from opening stock box
      final openingStockBox = await Hive.openBox('openingStockBox');
      await openingStockBox.delete(itemId);

      // Update local state
      _items.removeWhere((item) => item.id == itemId);
      _openingStocks.remove(itemId);

      // If the deleted item was the current item, reset it
      if (_item.id == itemId) {
        _item = ItemModel();
      }

      setLoading(false);
      notifyListeners();
      return true; // Successfully deleted
    } catch (e) {
      setLoading(false);
      debugPrint('Error deleting item: $e');
      rethrow;
    }
  }

  Future<void> adjustStock(
      ItemModel updatedItem, StockAdjustmentModel adjustment) async {
    setLoading(true);

    // Save the stock adjustment
    final adjustmentBox =
        await Hive.openBox<StockAdjustmentModel>('stockAdjustmentBox');
    await adjustmentBox.put(adjustment.id, adjustment);

    // Update item stock
    final itemBox = await Hive.openBox<ItemModel>('itemBox');
    await itemBox.put(updatedItem.id, updatedItem);

    // Update local state
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
    } else {
      _items.add(updatedItem);
    }

    if (_item.id == updatedItem.id) {
      _item = updatedItem;
    }

    setLoading(false);
    notifyListeners();
  }

  Future<void> reduceStock(String itemId, int quantity, String reason) async {
    setLoading(true);
    final itemBox = await Hive.openBox<ItemModel>('itemBox');
    final item = itemBox.get(itemId);

    if (item != null) {
      // Remove the stock quantity check
      final adjustment = StockAdjustmentModel(
        id: 'RED-${DateTime.now().millisecondsSinceEpoch}',
        itemId: itemId,
        date: DateTime.now(),
        quantity: quantity.toDouble(),
        rate: item.amount ?? 0,
        amount: (item.amount ?? 0) * quantity,
        reason: reason,
        type: AdjustmentType.reduction,
      );

      final updatedItem = item.copyWith(
        stockQuantity: (item.stockQuantity ?? 0) - quantity,
        date: item.date, // Preserve original date
      );

      // Save adjustment
      final adjustmentBox =
          await Hive.openBox<StockAdjustmentModel>('stockAdjustmentBox');
      await adjustmentBox.put(adjustment.id, adjustment);

      // Update item
      await itemBox.put(itemId, updatedItem);

      // Update local state
      final index = _items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
      }

      if (_item.id == itemId) {
        _item = updatedItem;
      }

      setLoading(false);
      notifyListeners();
    } else {
      setLoading(false);
      throw Exception('Item not found');
    }
  }

  Future<void> updateItem(Map<String, dynamic> updatedValues) async {
    final String oldName = _item.itemName ?? '';
    _item = ItemModel(
      id: _item.id,
      itemName: updatedValues['itemName'] ?? _item.itemName,
      stockQuantity: int.tryParse(updatedValues['stockQuantity'] ?? '') ??
          _item.stockQuantity,
      amount: double.tryParse(updatedValues['amount'] ?? '') ?? _item.amount,
      hsn: updatedValues['hsn'] ?? _item.hsn,
      date: _selectMonth,
      itemCategory: updatedValues['itemCategory'] ?? _item.itemCategory,
      itemDescription:
          updatedValues['itemDescription'] ?? _item.itemDescription,
      lowStockQuantity: int.tryParse(updatedValues['lowStockQuantity'] ?? '') ??
          _item.lowStockQuantity,
      gst: _selectedTaxRate,
      unit: _selectedUnit,
      lowStockQuantityAlert: _lowStockQuantityAlert,
      itemType: _isCustomerSelected ? 'Goods' : 'Service',
      subCategory:
          updatedValues['subCategory']?.toString() ?? _item.subCategory ?? '',
    );

    final itemBox = await Hive.openBox<ItemModel>('itemBox');
    await itemBox.put(_item.id, _item);

    if (_item.itemName != null && _item.itemName != oldName) {
      await _updateTransactionItemNames(oldName, _item.itemName!);
    }
    // Update opening stock if specified in the updated values
    if (updatedValues.containsKey('openingStock')) {
      final openingStockBox = await Hive.openBox('openingStockBox');
      final newOpeningStock =
          int.tryParse(updatedValues['openingStock'] ?? '') ?? 0;
      await openingStockBox.put(_item.id, newOpeningStock);
      _openingStocks[_item.id!] = newOpeningStock;
    }

    final index = _items.indexWhere((item) => item.id == _item.id);
    if (index != -1) {
      _items[index] = _item;
    }
    _updateSalesAndPurchases(
      _item.id!,
      _item.itemName!,
      _item.unit!,
    );

    notifyListeners();
  }

  void _updateSalesAndPurchases(
      String itemId, String newName, String newUnit) async {
    try {
      // Update sales
      final saleBox = Hive.box<SaleModel>('saleBox');
      for (var sale in saleBox.values) {
        final updatedItems = sale.item.map((item) {
          if (item.id == itemId) {
            return item.copyWith(
              itemName: newName,
              unit: newUnit,
            );
          }
          return item;
        }).toList();

        if (updatedItems != sale.item) {
          await saleBox.put(sale.key, sale.copyWith(item: updatedItems));
        }
      }

      // Update purchases
      final purchaseBox = Hive.box<PurchaseModel>('purchaseBox');
      for (var purchase in purchaseBox.values) {
        final updatedItems = purchase.item.map((item) {
          if (item.id == itemId) {
            return item.copyWith(
              itemName: newName,
              unit: newUnit,
            );
          }
          return item;
        }).toList();

        if (updatedItems != purchase.item) {
          await purchaseBox.put(
              purchase.key, purchase.copyWith(item: updatedItems));
        }
      }
    } catch (e) {
      debugPrint('Error updating sales/purchases: $e');
    }
  }

  Future<void> _updateTransactionItemNames(
      String oldName, String newName) async {
    final purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
    final saleBox = await Hive.openBox<SaleModel>('saleBox');

    // Update purchases
    for (final purchase in purchaseBox.values) {
      bool modified = false;
      for (final item in purchase.item) {
        if (item.itemName == oldName) {
          item.itemName = newName;
          modified = true;
        }
      }
      if (modified) await purchaseBox.put(purchase.id, purchase);
    }

    // Update sales
    for (final sale in saleBox.values) {
      bool modified = false;
      for (final item in sale.item) {
        if (item.itemName == oldName) {
          item.itemName = newName;
          modified = true;
        }
      }
      if (modified) await saleBox.put(sale.id, sale);
    }
  }

  Future<void> createNewItem(Map<String, dynamic> newItemValues) async {
    final newItem = ItemModel(
      id: const Uuid().v4(),
      itemName: newItemValues['itemName'],
      stockQuantity: int.tryParse(newItemValues['stockQuantity'] ?? ''),
      amount: double.tryParse(newItemValues['amount'] ?? ''),
      hsn: newItemValues['hsn'],
      date: newItemValues['date'],
      itemCategory: newItemValues['itemCategory'],
      itemDescription: newItemValues['itemDescription'],
      lowStockQuantity: int.tryParse(newItemValues['lowStockQuantity'] ?? ''),
      gst: newItemValues['gst'],
      unit: newItemValues['unit'],
      lowStockQuantityAlert: newItemValues['lowStockQuantityAlert'],
      itemType: newItemValues['itemType'],
      subCategory: newItemValues['subCategory']?.toString() ?? '',
    );

    final itemBox = await Hive.openBox<ItemModel>('itemBox');
    await itemBox.put(newItem.id, newItem);
    _item = newItem;
    final openingStockBox = await Hive.openBox('openingStockBox');
    await openingStockBox.put(newItem.id, newItem.stockQuantity ?? 0);
    _openingStocks[newItem.id!] = newItem.stockQuantity ?? 0;
    await fetchItems();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getItemTransactions(String itemId) async {
    try {
      allTransactions.clear();
      final itemBox = await Hive.openBox<ItemModel>('itemBox');
      final currentItem = itemBox.get(itemId);
      if (currentItem == null) return [];

      final purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
      final salesBox = await Hive.openBox<SaleModel>('saleBox');
      final adjustmentBox =
          await Hive.openBox<StockAdjustmentModel>('stockAdjustmentBox');

      // Add purchases - using itemName from the current item
      for (var purchase in purchaseBox.values) {
        for (var item in purchase.item) {
          if (item.itemName == currentItem.itemName) {
            allTransactions.add({
              'date': purchase.date,
              'type': purchase.type.name,
              'transactionType': PurchaseType.purchase,
              'partyName': purchase.partyName,
              'quantity': item.quantity,
              'rate': item.rate,
              'amount': item.totalAmount,
              'invoiceNumber': purchase.invoiceNumber,
            });
          }
        }
      }

      // Add sales - using itemName from the current item
      for (var sale in salesBox.values) {
        for (var item in sale.item) {
          if (item.itemName == currentItem.itemName) {
            allTransactions.add({
              'date': sale.date,
              'type': sale.type.name,
              'transactionType': SalesType.sale,
              'partyName': sale.partyName,
              'quantity': item.quantity,
              'rate': item.rate,
              'amount': item.totalAmount,
              'invoiceNumber': sale.invoiceNumber,
            });
          }
        }
      }

      // Add adjustments
      for (var adjustment in adjustmentBox.values) {
        if (adjustment.itemId == itemId) {
          allTransactions.add({
            'date': adjustment.date,
            'type': 'Stock Adjustment',
            'transactionType': adjustment.type == AdjustmentType.addition
                ? PurchaseType.purchase
                : PurchaseType.purchaseReturn,
            'partyName': 'Manual Adjustment',
            'quantity': adjustment.quantity,
            'rate': adjustment.rate,
            'amount': adjustment.amount,
            'invoiceNumber': adjustment.id,
          });
        }
      }

      allTransactions.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      return allTransactions;
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      return [];
    }
  }

  Future<void> updateStockForTransaction(
      String itemId, double quantity, bool isPurchase) async {
    try {
      debugPrint(
          'Updating stock for item: $itemId, quantity: $quantity, isPurchase: $isPurchase');

      // Open the item box
      final itemBox = await Hive.openBox<ItemModel>('itemBox');

      // Find the item by its ID
      final item = itemBox.get(itemId);

      if (item != null) {
        int newStockQuantity;
        if (isPurchase) {
          // For purchase, add to stock
          newStockQuantity = (item.stockQuantity ?? 0) + quantity.toInt();
        } else {
          // For sale, subtract from stock - REMOVE THE NEGATIVE STOCK CHECK
          newStockQuantity = (item.stockQuantity ?? 0) - quantity.toInt();
        }

        // Update the item's stock quantity
        item.stockQuantity = newStockQuantity;
        await itemBox.put(itemId, item);

        // Update local state if needed
        final index = _items.indexWhere((i) => i.id == itemId);
        if (index != -1) {
          _items[index] = item;
        }

        // Update current item if needed
        if (_item.id == itemId) {
          _item = item;
        }

        notifyListeners();
      } else {
        debugPrint('Item not found with ID: $itemId');
      }
    } catch (e) {
      debugPrint('Error updating stock for transaction: $e');
    }
  }

  // Method to check if there's enough stock for a sale
  bool hasEnoughStock(String itemId, double requestedQuantity) {
    try {
      final currentItem = _items.firstWhere((item) => item.id == itemId);
      return (currentItem.stockQuantity ?? 0) >= requestedQuantity;
    } catch (e) {
      debugPrint('Error checking stock: $e');
      return false;
    }
  }

  // Method to get current stock level
  double getCurrentStock(String itemId) {
    try {
      final currentItem = _items.firstWhere((item) => item.id == itemId);
      return (currentItem.stockQuantity ?? 0).toDouble();
    } catch (e) {
      debugPrint('Error getting current stock: $e');
      return 0;
    }
  }

  String getFormattedDate() {
    return DateFormat('dd MMM y').format(_selectMonth);
  }

  void toggleGoodsFilter(bool value) {
    showGoods = value;
    fetchItems();
    notifyListeners();
  }

  void toggleServicesFilter(bool value) {
    showServices = value;
    fetchItems();
    notifyListeners();
  }

  void toggleOutOfStockFilter(bool value) {
    showOutOfStock = value;
    fetchItems();
    notifyListeners();
  } // Add these methods to your ItemProvider class

  Future<bool> itemExists(String itemId) async {
    final box = await Hive.openBox<ItemModel>('itemBox');
    return box.containsKey(itemId);
  }

  Future<int> getItemStock(String itemId) async {
    final box = await Hive.openBox<ItemModel>('itemBox');
    final item = box.get(itemId);
    return item?.stockQuantity ?? 0;
  }
}
