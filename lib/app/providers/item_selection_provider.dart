import 'package:account_book/app/providers/item_provider.dart';
import 'package:flutter/material.dart';
import 'package:account_book/app/data/model/item_model.dart';
import 'package:account_book/app/data/model/item_selection_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

class ItemSelectionProvider extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController percentageController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController taxController = TextEditingController();

  double subtotal = 0.0;
  double total = 0.0;
  double discount = 0.0;
  double taxAmount = 0.0;
  double currentTaxPercentage = 0.0;

  bool isWithoutTax = true;
  bool isTextFieldFocused = false;
  bool isListViewVisible = true;
  bool isItemSelected = false;
  bool isCreatingNewItem = false;
  bool _isHiveInitialized = false;

  late Box<ItemModel> hiveBox;
  String selectedItemName = '';
  ItemModel? selectedItem;
  String selectedTaxRate = 'None';
  String selectedUnit = 'None';
  String hsnCode = '';
  String _currentId = '1';
  late Box<String> idBox;

  String partyName;
  List<ItemSelectionModel> selectedItems;

  ItemSelectionProvider({
    required this.partyName,
    required this.selectedItems,
  }) {
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    hiveBox = await Hive.openBox<ItemModel>('itemBox');
    idBox = await Hive.openBox<String>('idBox');
    _currentId = idBox.get('lastUsedId', defaultValue: '0')!;
    _isHiveInitialized = true;
    _setupControllers();
    notifyListeners();
  }

  void _setupControllers() {
    nameController.addListener(_textFieldFocusChange);
    quantityController.addListener(updateSubtotal);
    rateController.addListener(_rateControllerListener);
    percentageController.addListener(_percentageControllerListener);
    discountController.addListener(_discountControllerListener);

    percentageController.text = '0';
    quantityController.text = '1';
    discountController.text = '0';
  }

  void initializeWithItem(ItemSelectionModel item) {
    debugPrint('Initializing item: ${item.itemName}');
    // Temporarily remove listeners to prevent interference
    discountController.removeListener(_discountControllerListener);
    percentageController.removeListener(_percentageControllerListener);

    // Set basic item details
    nameController.text = item.itemName;
    quantityController.text = item.quantity.toStringAsFixed(2);
    selectedUnit = item.unit;
    rateController.text = item.rate.toStringAsFixed(2);

    // Set discount values with proper formatting
    discountController.text = item.discount.toStringAsFixed(2);
    percentageController.text = item.discountPercentage.toStringAsFixed(2);

    // Re-add listeners after setting values
    discountController.addListener(_discountControllerListener);
    percentageController.addListener(_percentageControllerListener);

    // Set the tax rate based on the item's tax type
    selectedTaxRate = item.taxType;
    isWithoutTax = selectedTaxRate == 'None' || selectedTaxRate == 'Exempted';

    // Update UI state
    isItemSelected = true;
    isTextFieldFocused = true;
    isListViewVisible = false;

    // Force calculations with initial values
    updateSubtotal();
    notifyListeners();
  }

  void _textFieldFocusChange() {
    isTextFieldFocused = nameController.text.isNotEmpty;
    isCreatingNewItem =
        !isItemSelected && !_itemExistsSync(nameController.text);
    notifyListeners();
  }

  void _rateControllerListener() {
    updateSubtotal();
    if (rateController.text.isNotEmpty && isCreatingNewItem) {
      isItemSelected = true;
      notifyListeners();
    }
  }

  void _percentageControllerListener() {
    updateDiscountFromPercentage();
    updateSubtotal();
  }

  void _discountControllerListener() {
    updatePercentageFromDiscount();
    updateSubtotal();
  }

  void updateDiscountFromPercentage() {
    try {
      double percentage = double.tryParse(percentageController.text) ?? 0.0;
      double subTotal = _calculateSubTotalAmount();
      double discountAmount = (subTotal * percentage) / 100;
      discountController.removeListener(_discountControllerListener);
      discountController.text = discountAmount.toStringAsFixed(2);
      // discountController.addListener(_discountControllerListener);
    } catch (error) {
      debugPrint('Error calculating discount from percentage: $error');
    }
  }

  void updatePercentageFromDiscount() {
    try {
      double discountAmount = double.tryParse(discountController.text) ?? 0.0;
      double subTotal = _calculateSubTotalAmount();
      double percentage =
          (subTotal != 0) ? (discountAmount / subTotal) * 100 : 0;
      percentageController.removeListener(_percentageControllerListener);
      percentageController.text = percentage.toStringAsFixed(2);
      // percentageController.addListener(_percentageControllerListener);
    } catch (error) {
      debugPrint('Error calculating percentage from discount: $error');
    }
  }

  void updateSubtotal() {
    try {
      double rate = double.tryParse(rateController.text) ?? 0.0;
      double discountAmount = double.tryParse(discountController.text) ?? 0.0;
      if (discountAmount > rate) {
        discountAmount = rate;
        discountController.text = rate.toStringAsFixed(2);
      }

      subtotal = _calculateSubTotalAmount();
      taxAmount = _calculateTaxAmount();
      total = _calculateTotalAmount();
      discount = _calculatePercentage();

      _updateTaxController(taxAmount);
      notifyListeners();
    } catch (error) {
      debugPrint('Error during calculation: $error');
    }
  }

  void _updateTaxController(double taxAmount) {
    taxController.text = taxAmount.toStringAsFixed(2);
  }

  double _calculateSubTotalAmount() {
    double quantity = double.tryParse(quantityController.text) ?? 0.0;
    double rate = double.tryParse(rateController.text) ?? 0.0;
    return quantity * rate;
  }

  double _calculateTotalAmount() {
    return subtotal + taxAmount - discount;
  }

  double _calculatePercentage() {
    try {
      double percentage = double.tryParse(percentageController.text) ?? 0.0;
      if (percentage > 100) {
        percentage = 100;
        percentageController.text = '100';
      }
      return (subtotal * percentage) / 100;
    } catch (error) {
      debugPrint('Error calculating discount percentage: $error');
      return 0.0;
    }
  }

  double _calculateTaxAmount() {
    if (isWithoutTax) return 0.0;

    try {
      String taxRateStr = selectedTaxRate.replaceAll(RegExp(r'[^\d.]'), '');
      double taxRate = double.tryParse(taxRateStr) ?? 0.0;
      return (subtotal * taxRate) / 100;
    } catch (error) {
      debugPrint('Error calculating tax amount: $error');
      return 0.0;
    }
  }

  void resetForm() {
    nameController.clear();
    quantityController.clear();
    rateController.clear();
    percentageController.clear();
    taxController.clear();
    subtotal = 0.0;
    total = 0.0;
    discount = 0.0;
    taxAmount = 0.0;
    isItemSelected = false;
    isCreatingNewItem = false;
    selectedItem = null;
    isTextFieldFocused = false;
    isListViewVisible = true;
    selectedUnit = 'None';
    notifyListeners();
  }

  Future<List<ItemModel>> filterItems(String query) async {
    if (!_isHiveInitialized) {
      await _initializeHive();
    }
    return hiveBox.values
        .where((item) =>
            item.itemName!.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void selectItem(ItemModel item) {
    selectedItem = item;
    nameController.text = item.itemName!;
    quantityController.text = '1';
    rateController.text = item.amount!.toStringAsFixed(2);
    selectedUnit = item.unit ?? 'None';
    hsnCode = item.hsn ?? '';
    // Set the tax rate based on the item's GST value
    selectedTaxRate = item.gst ?? 'None';
    isWithoutTax = selectedTaxRate == 'None' || selectedTaxRate == 'Exempted';

    isItemSelected = true;
    isListViewVisible = false;
    updateSubtotal();
    notifyListeners();
  }

  Future<bool> itemExists(String itemName) async {
    if (!_isHiveInitialized) {
      await _initializeHive();
    }
    return hiveBox.values.any((item) => item.itemName == itemName);
  }

  bool _itemExistsSync(String itemName) {
    if (!_isHiveInitialized) {
      return false; // or handle this case appropriately
    }
    return hiveBox.values.any((item) => item.itemName == itemName);
  }

  Future<void> createNewItem(
      BuildContext context, ItemProvider itemProvider) async {
    if (!_isHiveInitialized) {
      await _initializeHive();
    }

    if (!await itemExists(nameController.text) &&
        nameController.text.isNotEmpty) {
      DateTime date = DateTime.now();
      double amount;

      try {
        amount = double.parse(rateController.text);
      } catch (e) {
        amount = 0.0; // Default value if parsing fails
      }
      if (selectedItem != null) {
        hsnCode = selectedItem!.hsn ?? '';
      }
      final newItem = ItemModel(
        id: const Uuid().v4(),
        itemName: nameController.text,
        unit: selectedUnit,
        amount: amount,
        gst: selectedTaxRate,
        stockQuantity: 0,
        itemType: 'Goods',
        date: date,
        lowStockQuantityAlert: false,
        hsn: hsnCode,
        itemDescription: '',
        itemCategory: '',
        lowStockQuantity: 0,
        subCategory: '',
      );
      final hiveBox = await Hive.openBox<ItemModel>('itemBox');
      await hiveBox.put(newItem.id, newItem);
      selectedItem = newItem;

      // Ensure the ItemProvider is updated properly
      await itemProvider.fetchItems();

      notifyListeners();
    } else if (selectedItem == null && nameController.text.isNotEmpty) {
      // Find the existing item by name and select it
      final existingItems = await filterItems(nameController.text);
      if (existingItems.isNotEmpty) {
        selectedItem = existingItems.first;
        isItemSelected = true;
        notifyListeners();
      }
    }
  }

  Future<String> fetchHSNCode(String itemName) async {
    // Ensure Hive is initialized
    if (!_isHiveInitialized) {
      await _initializeHive();
    }

    // Find the item in the Hive box by name
    final existingItems =
        hiveBox.values.where((item) => item.itemName == itemName);

    if (existingItems.isNotEmpty) {
      // Return the HSN code of the first matching item
      return existingItems.first.hsn ?? '';
    }

    return '';
  }

  ItemSelectionModel createItemSelectionModel() {
    return ItemSelectionModel(
      id: _currentId,
      unit: selectedUnit,
      itemName: nameController.text,
      quantity: double.tryParse(quantityController.text) ?? 0.0,
      rate: double.tryParse(rateController.text) ?? 0.0,
      subTotal: subtotal,
      discount: discount,
      discountPercentage: double.tryParse(percentageController.text) ?? 0.0,
      taxAmount: isWithoutTax ? 0.0 : taxAmount,
      totalAmount: total,
      partyName: partyName,
      taxType: selectedTaxRate,
      hsnCode: hsnCode,
    );
  }

  void addItemToSelection() {
    if (selectedItem == null) return;

    final double quantity = double.tryParse(quantityController.text) ?? 0.0;
    final double rate = double.tryParse(rateController.text) ?? 0.0;
    final double discountAmount = double.tryParse(
            discountController.text.isEmpty ? '0' : discountController.text) ??
        0.0;

    // Extract tax rate from the selected tax type
    double taxRate = 0.0;
    if (!isWithoutTax &&
        selectedTaxRate != 'None' &&
        selectedTaxRate != 'Exempted') {
      final percentageMatch =
          RegExp(r'(\d+(?:\.\d+)?)').firstMatch(selectedTaxRate);
      if (percentageMatch != null) {
        taxRate = double.parse(percentageMatch.group(1)!);
      }
    }

    final double subTotal = quantity * rate;
    final double discountPercentage =
        double.tryParse(percentageController.text) ?? 0.0;
    final double taxAmount = (taxRate / 100) * (subTotal - discountAmount);
    final double totalAmount = subTotal - discountAmount + taxAmount;

    // Check if item already exists in the selection
    final existingItemIndex = selectedItems.indexWhere(
      (item) => item.id == selectedItem!.id,
    );

    if (existingItemIndex != -1) {
      // If item exists, update it with all values
      final updatedQuantity =
          selectedItems[existingItemIndex].quantity + quantity;
      final updatedSubTotal = updatedQuantity * rate;

      // Calculate discount amount based on percentage for the new subtotal
      final updatedDiscountAmount =
          (discountPercentage / 100) * updatedSubTotal;

      // Recalculate tax based on new subtotal and discount
      final updatedTaxAmount =
          (taxRate / 100) * (updatedSubTotal - updatedDiscountAmount);

      // Calculate new total amount
      final updatedTotalAmount =
          updatedSubTotal - updatedDiscountAmount + updatedTaxAmount;

      selectedItems[existingItemIndex] =
          selectedItems[existingItemIndex].copyWith(
        quantity: updatedQuantity,
        subTotal: updatedSubTotal,
        discount: updatedDiscountAmount,
        discountPercentage: discountPercentage,
        taxAmount: updatedTaxAmount,
        type: selectedTaxRate,
        totalAmount: updatedTotalAmount,
      );
    } else {
      // If new item, add it with all values
      selectedItems.add(ItemSelectionModel(
        id: selectedItem!.id ?? const Uuid().v4(),
        partyName: partyName,
        itemName: selectedItem!.itemName ?? '',
        quantity: quantity,
        unit: selectedUnit,
        rate: rate,
        subTotal: subTotal,
        discount: discountAmount,
        discountPercentage: discountPercentage,
        taxAmount: taxAmount,
        taxType: selectedTaxRate,
        totalAmount: totalAmount,
        hsnCode: selectedItem!.hsn,
      ));
    }

    notifyListeners();
  }

  void setTaxRate(String newValue) {
    selectedTaxRate = newValue;
    isWithoutTax = newValue == 'None' || newValue == 'Exempted';

    if (!isWithoutTax) {
      final percentageMatch =
          RegExp(r'(\d+(?:\.\d+)?)').firstMatch(selectedTaxRate);
      if (percentageMatch != null) {
        currentTaxPercentage = double.parse(percentageMatch.group(1)!);
      }
    } else {
      currentTaxPercentage = 0.0;
    }

    updateSubtotal();
    notifyListeners();
  }

  void setUnit(String newValue) {
    selectedUnit = newValue;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    rateController.dispose();
    percentageController.dispose();
    discountController.dispose();
    taxController.dispose();
    super.dispose();
  }

  updateSelectedItem(int index) {
    if (index < 0 || index >= selectedItems.length) {
      debugPrint('Invalid index provided: $index');
      return;
    }

    final double quantity = double.tryParse(quantityController.text) ?? 0.0;
    final double rate = double.tryParse(rateController.text) ?? 0.0;
    final double discountAmount = double.tryParse(
            discountController.text.isEmpty ? '0' : discountController.text) ??
        0.0;

    // Extract tax rate from the selected tax type
    double taxRate = 0.0;
    if (!isWithoutTax &&
        selectedTaxRate != 'None' &&
        selectedTaxRate != 'Exempted') {
      final percentageMatch =
          RegExp(r'(\d+(?:\.\d+)?)').firstMatch(selectedTaxRate);
      if (percentageMatch != null) {
        taxRate = double.parse(percentageMatch.group(1)!);
      }
    }

    final double subTotal = quantity * rate;
    final double discountPercentage =
        double.tryParse(percentageController.text) ?? 0.0;
    final double taxAmount = (taxRate / 100) * (subTotal - discountAmount);
    final double totalAmount = subTotal - discountAmount + taxAmount;

    // Update the item at the specified index
    selectedItems[index] = ItemSelectionModel(
      id: selectedItems[index].id,
      partyName: partyName,
      itemName: nameController.text,
      quantity: quantity,
      unit: selectedUnit,
      rate: rate,
      subTotal: subTotal,
      discount: discountAmount,
      discountPercentage: discountPercentage,
      taxAmount: taxAmount,
      taxType: selectedTaxRate,
      totalAmount: totalAmount,
      hsnCode: selectedItem?.hsn ?? hsnCode,
    );

    notifyListeners();
  }
}
