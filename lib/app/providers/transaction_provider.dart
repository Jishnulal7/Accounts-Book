import 'dart:convert';
import 'dart:math';
import 'package:account_book/app/data/constants/invoice_prefix_manager.dart';
import 'package:account_book/app/data/helpers/enums/toast.dart';
import 'package:account_book/app/data/model/payment_record.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:account_book/app/data/helpers/enums/invoice_prefix.dart';
import 'package:account_book/app/data/helpers/enums/transaction_type.dart';
import 'package:account_book/app/providers/item_provider.dart';
import 'package:account_book/app/providers/party_provider.dart';
import 'package:account_book/app/widgets/custom_toast.dart';
import 'package:account_book/app/data/model/item_selection_model.dart';
import 'package:account_book/app/data/model/party_model.dart';
import 'package:account_book/app/data/model/purchase_model.dart';
import 'package:account_book/app/data/model/sale_model.dart';

class TransactionProvider with ChangeNotifier {
  // Form keys to validate forms
  final GlobalKey<FormState> purchaseKey = GlobalKey<FormState>();
  final GlobalKey<FormState> saleKey = GlobalKey<FormState>();

  // Controllers for various input fields
  final TextEditingController partyNamecontroller = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController itemController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController receivedAmountController =
      TextEditingController();
  final TextEditingController shippingChargeController =
      TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController packagingChargeController =
      TextEditingController();
  final TextEditingController additionalChargeController =
      TextEditingController();
  final TextEditingController transportationNameController =
      TextEditingController();
  final TextEditingController deliveryDateController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController deliveryLocationController =
      TextEditingController();

  // Maps to store the last used invoice numbers for sales and purchases
  final Map<SalesType, int> _lastSaleNumbers = {};
  final Map<PurchaseType, int> _lastPurchaseNumbers = {};

  // Internal state variables
  DateTime _invoiceDate = DateTime.now();
  bool _isTextFieldFocused = false;
  bool _isPartySelected = false;
  bool isItemSelected = false;
  bool _isRoundedOff = false;
  bool _isFullyPaid = false;

  // Selected party and transaction details
  String? _selectedPartyId;
  String _invoiceNumber = '1';
  String _selectedPartyName = '';
  String _paymentType = 'Cash';
  String _stateOfSupply = 'Select State';
  final double _selectedPartyBalance = 0.0;
  double? _originalTotal;
  double? _originalBalance;
  PrefixType prefixType = PrefixType.none;
  String customPrefix = '';
  final FocusNode focusNode = FocusNode();
  late Box<PartyModel> _hiveBox;
  final List<ItemSelectionModel> selectedItems = [];
  final List<String> _transportationDetails = [];
  String? _selectedBankId;
  List<Map<String, String>> _bankAccounts = [];

  // Transaction type and subtype
  TransactionType _transactionType = TransactionType.sale;
  SalesType _salesType = SalesType.sale;
  PurchaseType _purchaseType = PurchaseType.purchase;
  PrefixType selectedPrefix = PrefixType.none;
  SavedPrefix? selectedSavedPrefix;

  // Getters for accessing private variables
  DateTime get invoiceDate => _invoiceDate;
  bool get isTextFieldFocused => _isTextFieldFocused;
  bool get isPartySelected => _isPartySelected;
  String get invoiceNumber => _invoiceNumber;
  String get selectedPartyName => _selectedPartyName;
  String get paymentType => _paymentType;
  String get stateOfSupply => _stateOfSupply;
  double get selectedPartyBalance => _selectedPartyBalance;
  List<String> get transportationDetails => _transportationDetails;
  bool get isRoundedOff => _isRoundedOff;
  bool get isFullyPaid => _isFullyPaid;
  TransactionType get transactionType => _transactionType;
  SalesType get salesType => _salesType;
  PurchaseType get purchaseType => _purchaseType;
  String? get selectedBankId => _selectedBankId;
  List<Map<String, String>> get bankAccounts => _bankAccounts;

// In TransactionProvider constructor
  TransactionProvider() {
    _initializeHive();
    _setupListeners();
    initializeLastNumbers();
    loadBankDetails(); // Add this line
  }
  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _initializeHive() async {
    if (!Hive.isBoxOpen('partyBox')) {
      _hiveBox = await Hive.openBox<PartyModel>('partyBox');
    } else {
      _hiveBox = Hive.box<PartyModel>('partyBox');
    }

    // Also ensure the sale box is open
    if (!Hive.isBoxOpen('saleBox')) {
      await Hive.openBox<SaleModel>('saleBox');
    }
  }

  void _setupListeners() {
    partyNamecontroller.addListener(textFieldFocusChange);
    balanceController.addListener(_updateBalance);
    focusNode.addListener(_onFocusChange);

    shippingChargeController.addListener(_updateTotalAmount);
    packagingChargeController.addListener(_updateTotalAmount);
    additionalChargeController.addListener(_updateTotalAmount);
    discountController.addListener(_updateTotalAmount);
  }

  void refresh() {
    notifyListeners();
  }

  void setSelectedBankId(String? bankId) {
    _selectedBankId = bankId;
    notifyListeners();
  }

  Future<void> loadBankDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final String? bankDetailsJson = prefs.getString('bankDetails');
    final String? selectedBankId = prefs.getString('selectedBankId');

    if (bankDetailsJson != null) {
      final List<dynamic> dynamicList = json.decode(bankDetailsJson);
      _bankAccounts = dynamicList.map((item) {
        return Map<String, String>.from(item);
      }).toList();
      _selectedBankId = selectedBankId;
    }
    notifyListeners();
  }

  Future<void> saveBankDetails(List<Map<String, String>> details) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bankDetails', json.encode(details));
    _bankAccounts = details;
    notifyListeners();
  }

  Future<void> saveSelectedBank(String? bankId) async {
    final prefs = await SharedPreferences.getInstance();
    if (bankId != null) {
      await prefs.setString('selectedBankId', bankId);
    } else {
      await prefs.remove('selectedBankId');
    }
    _selectedBankId = bankId;
    notifyListeners();
  }

  void _disposeControllers() {
    partyNamecontroller.removeListener(textFieldFocusChange);
    balanceController.removeListener(_updateBalance);
    focusNode.removeListener(_onFocusChange);

    partyNamecontroller.dispose();
    dateController.dispose();
    itemController.dispose();
    totalController.dispose();
    paidAmountController.dispose();
    receivedAmountController.dispose();
    balanceController.dispose();
    additionalChargeController.dispose();
    shippingChargeController.dispose();
    packagingChargeController.dispose();
    deliveryDateController.dispose();
    transportationNameController.dispose();
    vehicleNumberController.dispose();
    deliveryLocationController.dispose();
    discountController.dispose();
  }

  void initializeRoundOff(bool isChecked) {
    if (isChecked) {
      _originalTotal ??= double.tryParse(totalController.text) ?? 0.0;
      _originalBalance ??= double.tryParse(balanceController.text) ?? 0.0;

      double roundedTotal = _originalTotal!.roundToDouble();
      double roundedBalance = _originalBalance!.roundToDouble();
      totalController.text = roundedTotal.toStringAsFixed(2);
      balanceController.text = roundedBalance.toStringAsFixed(0);
    } else {
      if (_originalTotal != null) {
        totalController.text = _originalTotal!.toStringAsFixed(2);
      }
      if (_originalBalance != null) {
        balanceController.text = _originalBalance!.toStringAsFixed(2);
      }
      _originalTotal = null;
      _originalBalance = null;
    }
    notifyListeners();
  }

  void _updateTotalAmount() {
    final double totalAmount = calculateTotalAmount();
    totalController.text = totalAmount.toStringAsFixed(2);
    balanceController.text = totalAmount.toStringAsFixed(2);
    notifyListeners();
  }

  void _updateBalance() {
    final totalAmount = double.tryParse(totalController.text) ?? 0;
    final paidAmount = double.tryParse(paidAmountController.text) ?? 0;
    final receivedAmount = double.tryParse(receivedAmountController.text) ?? 0;
    final balanceAmount = totalAmount - (paidAmount + receivedAmount);
    balanceController.text = balanceAmount.toStringAsFixed(2);
    notifyListeners();
  }

  void textFieldFocusChange() {
    _isTextFieldFocused = partyNamecontroller.text.isNotEmpty;
    notifyListeners();
  }

  void _onFocusChange() {
    _isTextFieldFocused = focusNode.hasFocus;
    if (focusNode.hasFocus && partyNamecontroller.text.isEmpty) {
      // Trigger a refresh to show all parties when focused
      notifyListeners();
    }
  }

  void onSelectParty(PartyModel party) {
    _selectedPartyName = party.name!;
    _selectedPartyId = party.id; // Store the ID
    partyNamecontroller.text = _selectedPartyName;
    _isTextFieldFocused = false;
    _isPartySelected = true;
    focusNode.unfocus();
    notifyListeners();
  }

  void addItems(List<ItemSelectionModel> items) {
    selectedItems.clear();
    selectedItems.addAll(items);
    isItemSelected = true;
    _updateTotalAmount();
    notifyListeners();
  }

  void updateInvoiceDate(DateTime newDate) {
    _invoiceDate = newDate;
    dateController.text = DateFormat('dd MMM y').format(newDate);
    notifyListeners();
  }

// In EditTransactionProvider
  void editInvoice(
    String newNumber,
    DateTime newDate,
    PrefixType newPrefixType,
    String newCustomPrefix,
  ) {
    _invoiceNumber = newNumber;
    setPrefixType(newPrefixType,
        savedPrefix: newPrefixType == PrefixType.saved
            ? SavedPrefix(code: newCustomPrefix)
            : null,
        custom: newPrefixType == PrefixType.custom ? newCustomPrefix : null);
    updateInvoiceDate(newDate);
  }

  Future<void> onSaveAndNew({
    required PartyProvider partyProvider,
    required ItemProvider itemProvider,
    required BuildContext context,
  }) async {
    try {
      // Save current transaction based on its type
      if (purchaseType == PurchaseType.purchase) {
        final result = await onSavePurchase(partyProvider, itemProvider);
        if (result == null) return; // If save failed, don't proceed
      } else if (purchaseType == PurchaseType.purchaseOrder) {
        final result = await onSavePurchaseReturn(itemProvider, partyProvider);
        if (result == null) return; // If save failed, don't proceed
      } else if (purchaseType == PurchaseType.purchaseOrder) {
        final result = await onSavePurchaseOrder(itemProvider, partyProvider);
        if (result == null) return; // If save failed, don't proceed
      } else if (_salesType == SalesType.salesOrder) {
        final result = await onSaveSalesOrder(partyProvider, itemProvider);
        if (result == null) return; // If save failed, don't proceed
      } else if (_salesType == SalesType.sale) {
        final result = await onSaveSale(partyProvider, itemProvider);
        if (result == null) return; // If save failed, don't proceed
      } else if (_salesType == SalesType.salesReturn) {
        final result = await onSaveSalesReturn(partyProvider, itemProvider);
        if (result == null) return; // If save failed, don't proceed
      } else if (_salesType == SalesType.deliveryChallan) {
        final result = await onSaveSalesDelivery(partyProvider, itemProvider);
        if (result == null) return; // If save failed, don't proceed
      } else if (_salesType == SalesType.proforma) {
        final result = await onSaveProforma(partyProvider, itemProvider);
        if (result == null) return; // If save failed, don't proceed
      }

      // Reset form for new transaction
      resetForNewTransaction();

      // Show success message
      showToast(context, 'Transaction saved successfully');
    } catch (e) {
      showToast(context, 'Error: ${e.toString()}');
    }
  }

  void setPrefixType(PrefixType type,
      {SavedPrefix? savedPrefix, String? custom}) {
    selectedPrefix = type;
    if (type == PrefixType.saved) {
      selectedSavedPrefix = savedPrefix;
      customPrefix = savedPrefix?.code ?? '';
    } else if (type == PrefixType.custom) {
      customPrefix = custom ?? '';
      selectedSavedPrefix = null;
    } else {
      customPrefix = '';
      selectedSavedPrefix = null;
    }
    notifyListeners();
  }

  Future<PurchaseModel?> _createPurchaseModel({
    required PurchaseType purchaseType,
    required PartyProvider partyProvider,
    required ItemProvider itemProvider,
  }) async {
    try {
      if (!purchaseKey.currentState!.validate()) return null;

      if (partyNamecontroller.text.isEmpty) {
        throw Exception('Party name cannot be empty.');
      }

      if (selectedItems.isEmpty) {
        throw Exception("At least one item must be added.");
      }
      for (var item in selectedItems) {
        final itemExists = await itemProvider.itemExists(item.id);
        if (!itemExists) {
          throw Exception(
              "Invalid item ID: ${item.id}. Item may have been deleted or modified.");
        }
      }
      final totalAmount = double.tryParse(totalController.text) ?? 0;
      final paidAmount = double.tryParse(paidAmountController.text) ?? 0;
      final balanceAmount = totalAmount - paidAmount;
      final shippingCharges =
          double.tryParse(shippingChargeController.text) ?? 0;
      final discounts = double.tryParse(discountController.text) ?? 0;
      final additionalCharges =
          double.tryParse(additionalChargeController.text) ?? 0;
      final packagingCharge =
          double.tryParse(packagingChargeController.text) ?? 0;
      final partyId = await _getOrCreatePartyId(partyProvider);
      if (partyId == null) throw Exception('Failed to get/create party ID');
      final paymentHistory = _getCurrentPaymentHistory();

      final purchaseModel = PurchaseModel(
        invoiceNumber: _invoiceNumber,
        partyName: partyNamecontroller.text,
        date: _invoiceDate,
        totalAmount: totalAmount,
        balanceAmount: balanceAmount,
        paidAmount: paidAmount,
        type: purchaseType,
        paymentType: _paymentType,
        id: '${purchaseType.name}_$_invoiceNumber',
        item: List<ItemSelectionModel>.from(selectedItems),
        transportaionDetails: _transportationDetails,
        stateOfSupply: _stateOfSupply,
        isRoundedOff: _isRoundedOff,
        isFullyPaid: _isFullyPaid,
        additionalCharges: additionalCharges,
        discounts: discounts,
        packingCharges: packagingCharge,
        shippingCharges: shippingCharges,
        partyId: partyId,
        paymentHistory: paymentHistory,
      );
      debugPrint(purchaseModel.toString());

      final box = await Hive.openBox<PurchaseModel>('purchaseBox');
      await box.put(purchaseModel.id, purchaseModel);
      _lastPurchaseNumbers[_purchaseType] = int.parse(_invoiceNumber);
      for (var item in selectedItems) {
        await itemProvider.updateStockForTransaction(
          item.id, // Ensure this is the correct item ID
          item.quantity,
          purchaseType == PurchaseType.purchaseReturn ? false : true,
        );
      }
      return purchaseModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<SaleModel?> _createSaleModel({
    required SalesType saleType,
    required PartyProvider partyProvider,
    required ItemProvider itemProvider,
  }) async {
    try {
      if (!saleKey.currentState!.validate()) {
        throw Exception('Please fill all required fields correctly');
      }

      if (partyNamecontroller.text.isEmpty) {
        throw Exception('Party name cannot be empty.');
      }

      if (selectedItems.isEmpty) {
        throw Exception("At least one item must be added.");
      }
      for (var item in selectedItems) {
        final itemExists = await itemProvider.itemExists(item.id);
        if (!itemExists) {
          throw Exception(
              "Invalid item ID: ${item.id}. Item may have been deleted or modified.");
        }

        // For sales, also check if there's enough stock
        if (saleType == SalesType.sale ||
            saleType == SalesType.deliveryChallan) {
          final availableStock = await itemProvider.getItemStock(item.id);
          if (availableStock < item.quantity) {
            throw Exception(
                "Insufficient stock for ${item.itemName}. Available: $availableStock, Required: ${item.quantity}");
          }
        }
      }
      final totalAmount = double.tryParse(totalController.text) ?? 0.0;
      final receivedAmount =
          double.tryParse(receivedAmountController.text) ?? 0.0;
      final balanceAmount = totalAmount - receivedAmount;
      final shippingCharges =
          double.tryParse(shippingChargeController.text) ?? 0.0;
      final discounts = double.tryParse(discountController.text) ?? 0.0;
      final additionalCharges =
          double.tryParse(additionalChargeController.text) ?? 0.0;
      final packagingCharge =
          double.tryParse(packagingChargeController.text) ?? 0.0;

      final partyId = await _getOrCreatePartyId(partyProvider);
      if (partyId == null) throw Exception('Failed to get/create party ID');
      final paymentHistory = _getCurrentPaymentHistory();

      final saleModel = SaleModel(
        invoiceNumber: _invoiceNumber,
        partyName: partyNamecontroller.text,
        date: _invoiceDate,
        totalAmount: totalAmount,
        balanceAmount: balanceAmount,
        receivedAmount: receivedAmount,
        type: saleType,
        paymentType: _paymentType,
        id: '${saleType.name}_$_invoiceNumber',
        item: List<ItemSelectionModel>.from(selectedItems),
        transportaionDetails: _transportationDetails,
        stateOfSupply: _stateOfSupply,
        isRoundedOff: _isRoundedOff,
        isFullyPaid: _isFullyPaid,
        additionalCharges: additionalCharges,
        discounts: discounts,
        packingCharges: packagingCharge,
        shippingCharges: shippingCharges,
        partyId: partyId,
        paymentHistory: paymentHistory,
      );

      final box = await Hive.openBox<SaleModel>('saleBox');
      await box.put(saleModel.id, saleModel);
      _lastSaleNumbers[_salesType] = int.parse(_invoiceNumber);
      // Update stock quantity for each item in the sale
      for (var item in selectedItems) {
        await itemProvider.updateStockForTransaction(
          item.id, // Ensure this is the correct item ID
          item.quantity,
          saleType == SalesType.salesReturn ? true : false,
        );
      }
      debugPrint(saleModel.toString());
      notifyListeners();
      return saleModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> _getOrCreatePartyId(PartyProvider partyProvider) async {
    // Return immediately if we already have a selected party ID
    if (_selectedPartyId != null) return _selectedPartyId;

    // Check if party exists by name
    final existingParty =
        partyProvider.getPartyByName(partyNamecontroller.text);

    if (existingParty != null) {
      return existingParty.id; // Return ID of existing party
    }

    // Create new party if doesn't exist
    final newParty = PartyModel(
      name: partyNamecontroller.text,
      id: const Uuid().v4(),
      date: DateTime.now(),
      openingBalance: 0.0,
      isCustomer: _transactionType == TransactionType.sale,
      creditPeriod: 'None',
      creditAmount: 0.0,
    );

    await partyProvider.addParty(newParty);
    return newParty.id;
  }

  Future<PurchaseModel?> onSavePurchase(
    PartyProvider partyProvider,
    ItemProvider itemProvider,
  ) async {
    return _createPurchaseModel(
      purchaseType: PurchaseType.purchase,
      partyProvider: partyProvider,
      itemProvider: itemProvider,
    );
  }

  Future<PurchaseModel?> onSavePurchaseReturn(
    ItemProvider itemProvider,
    PartyProvider partyProvider,
  ) async {
    return _createPurchaseModel(
      purchaseType: PurchaseType.purchaseReturn,
      itemProvider: itemProvider,
      partyProvider: partyProvider,
    );
  }

  Future<PurchaseModel?> onSavePurchaseOrder(
    ItemProvider itemProvider,
    PartyProvider partyProvider,
  ) async {
    return _createPurchaseModel(
      purchaseType: PurchaseType.purchaseOrder,
      partyProvider: partyProvider,
      itemProvider: itemProvider,
    );
  }

  Future<SaleModel?> onSaveSale(
      PartyProvider partyProvider, ItemProvider itemProvider) async {
    return _createSaleModel(
      saleType: SalesType.sale,
      partyProvider: partyProvider,
      itemProvider: itemProvider,
    );
  }

  Future<SaleModel?> onSaveSalesReturn(
      PartyProvider partyProvider, ItemProvider itemProvider) async {
    return _createSaleModel(
      saleType: SalesType.salesReturn,
      partyProvider: partyProvider,
      itemProvider: itemProvider,
    );
  }

  Future<SaleModel?> onSaveSalesEstimate(
      PartyProvider partyProvider, ItemProvider itemProvider) async {
    return _createSaleModel(
      saleType: SalesType.estimation,
      partyProvider: partyProvider,
      itemProvider: itemProvider,
    );
  }

  Future<SaleModel?> onSaveSalesDelivery(
      PartyProvider partyProvider, ItemProvider itemProvider) async {
    return _createSaleModel(
      saleType: SalesType.deliveryChallan,
      partyProvider: partyProvider,
      itemProvider: itemProvider,
    );
  }

  Future<SaleModel?> onSaveSalesOrder(
      PartyProvider partyProvider, ItemProvider itemProvider) async {
    return _createSaleModel(
      saleType: SalesType.salesOrder,
      partyProvider: partyProvider,
      itemProvider: itemProvider,
    );
  }

  Future<SaleModel?> onSaveProforma(
      PartyProvider partyProvider, ItemProvider itemProvider) async {
    return _createSaleModel(
      saleType: SalesType.proforma,
      partyProvider: partyProvider,
      itemProvider: itemProvider,
    );
  }

  double calculateTotalDiscount() {
    return selectedItems.fold(0.0, (total, item) => total + item.discount);
  }

  double calculateTotalQuantity() {
    return selectedItems.fold(0.0, (total, item) => total + item.quantity);
  }

  double calculateTotalTaxAmount() {
    return selectedItems.fold(0.0, (total, item) => total + item.taxAmount);
  }

  double calculateTotalSubTotal() {
    return selectedItems.fold(0.0, (total, item) => total + item.subTotal);
  }

  double calculateTotalAmount() {
    double subTotal = calculateTotalSubTotal();
    double shipping = double.tryParse(shippingChargeController.text) ?? 0.0;
    double packaging = double.tryParse(packagingChargeController.text) ?? 0.0;
    double additional = double.tryParse(additionalChargeController.text) ?? 0.0;
    double taxAmount = calculateTotalTaxAmount();
    double discount = double.tryParse(discountController.text) ?? 0.0;
    double discountFromItem = calculateTotalDiscount();
    return subTotal +
        shipping +
        packaging +
        additional +
        taxAmount -
        discount -
        discountFromItem;
  }

  void addSelectedItem(ItemSelectionModel item) {
    selectedItems.add(item);
    calculateTotalAmount();
    notifyListeners();
  }

  int getItemCount() {
    return selectedItems.length;
  }

  Future<List<PartyModel>> getAllParties() async {
    await _initializeHive();
    return _hiveBox.values.toList();
  }

  void updateSelectedItem(int index, ItemSelectionModel updatedItem) {
    if (index >= 0 && index < selectedItems.length) {
      selectedItems[index] = updatedItem;
      _updateTotalAmount(); // Update the total amount after modifying the item
      notifyListeners(); // Notify listeners to refresh the UI
    } else {
      debugPrint('Error: Invalid index $index for updating item');
    }
  }

  void removeSelectedItem(int index) {
    if (index >= 0 && index < selectedItems.length) {
      selectedItems.removeAt(index);
      _updateTotalAmount();
      notifyListeners();
    } else {
      debugPrint('Error: Invalid index $index for removing item');
    }
  }

  Future<List<PartyModel>> searchPartyByName(String query) async {
    await _initializeHive();
    return _hiveBox.values
        .where(
            (party) => party.name!.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void setPaymentType(String value) {
    _paymentType = value;
    notifyListeners();
  }

  void setStateOfSupply(String value) {
    _stateOfSupply = value;
    notifyListeners();
  }

  void setRoundedOff(bool value) {
    _isRoundedOff = value;
    if (value) {
      _roundOffTotal();
    } else {
      _unroundTotal();
    }
    notifyListeners();
  }

  void setFullyPaid(bool value, {bool isSale = true}) {
    _isFullyPaid = value;
    if (value) {
      if (isSale) {
        receivedAmountController.text = totalController.text;
      } else {
        paidAmountController.text = totalController.text;
      }
      balanceController.text = "0.00";
    }
    notifyListeners();
  }

  void _roundOffTotal() {
    double currentTotal = double.parse(totalController.text);
    double roundedTotal = currentTotal.round().toDouble();
    totalController.text = roundedTotal.toStringAsFixed(2);
    _updateBalance();
  }

  void _unroundTotal() {
    _updateTotalAmount();
  }

  void updateTransportationDetails(List<String> details) {
    _transportationDetails.clear();
    _transportationDetails.addAll(details);
    notifyListeners();
  }

// Modify resetForNewTransaction to use the correct invoice number
  Future<void> resetForNewTransaction() async {
    clearAllFields();

    _invoiceDate = DateTime.now();
    _isTextFieldFocused = false;
    _isPartySelected = false;
    isItemSelected = false;
    _isRoundedOff = false;
    _isFullyPaid = false;
    _selectedPartyId = null;
    // Get the next invoice number based on transaction type
    _invoiceNumber = await _getNextInvoiceNumber();
    _selectedBankId = null;
    await loadBankDetails();
    _selectedPartyName = '';
    _paymentType = 'Cash';
    _stateOfSupply = 'Select State';
    prefixType = PrefixType.none;
    customPrefix = '';

    notifyListeners();
  }

  // Add a method to initialize and load saved numbers
  Future<void> initializeLastNumbers() async {
    // Initialize sales types
    for (var type in SalesType.values) {
      _lastSaleNumbers[type] =
          await _getLastUsedNumber(TransactionType.sale, type);
    }

    // Initialize purchase types
    for (var type in PurchaseType.values) {
      _lastPurchaseNumbers[type] =
          await _getLastUsedNumber(TransactionType.purchase, type);
    }
  }

  Future<int> _getLastUsedNumber(
      TransactionType transactionType, dynamic subtype) async {
    try {
      if (transactionType == TransactionType.sale) {
        final saleBox = await Hive.openBox<SaleModel>('saleBox');
        final salesOfType =
            saleBox.values.where((sale) => sale.type == subtype).toList();
        if (salesOfType.isEmpty) return 0;
        return salesOfType
            .map((s) => int.tryParse(s.invoiceNumber) ?? 0)
            .reduce(max);
      } else {
        final purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
        final purchasesOfType =
            purchaseBox.values.where((p) => p.type == subtype).toList();
        if (purchasesOfType.isEmpty) return 0;
        return purchasesOfType
            .map((p) => int.tryParse(p.invoiceNumber) ?? 0)
            .reduce(max);
      }
    } catch (e) {
      debugPrint('Error getting last used number: $e');
      return 0;
    }
  }

  Future<String> _getNextInvoiceNumber() async {
    try {
      if (_transactionType == TransactionType.sale) {
        final currentMax =
            await _getLastUsedNumber(TransactionType.sale, _salesType);
        final nextNumber = currentMax + 1;
        _lastSaleNumbers[_salesType] = nextNumber;
        return nextNumber.toString();
      } else {
        final currentMax =
            await _getLastUsedNumber(TransactionType.purchase, _purchaseType);
        final nextNumber = currentMax + 1;
        _lastPurchaseNumbers[_purchaseType] = nextNumber;
        return nextNumber.toString();
      }
    } catch (e) {
      debugPrint('Error getting next invoice number: $e');
      return '1';
    }
  }

  void clearAllFields() {
    partyNamecontroller.clear();
    dateController.clear();
    itemController.clear();
    totalController.clear();
    balanceController.clear();
    paidAmountController.clear();
    receivedAmountController.clear();
    shippingChargeController.clear();
    discountController.clear();
    packagingChargeController.clear();
    additionalChargeController.clear();
    transportationNameController.clear();
    deliveryDateController.clear();
    vehicleNumberController.clear();
    deliveryLocationController.clear();

    selectedItems.clear();
    _transportationDetails.clear();
    _isPartySelected = false;
    _isTextFieldFocused = false;
    isItemSelected = false;
    _isRoundedOff = false;
    _isFullyPaid = false;

    _paymentType = 'Cash';
    _stateOfSupply = 'Select State';

    notifyListeners();
  }

  Future<List<PurchaseModel>> getAllPurchases() async {
    final purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
    return purchaseBox.values.toList();
  }

  Future<List<SaleModel>> getAllSales() async {
    final saleBox = await Hive.openBox<SaleModel>('saleBox');
    return saleBox.values.toList();
  }

  Future<List<PurchaseModel>> searchPurchasesByPartyName(String query) async {
    final purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
    return purchaseBox.values
        .where((purchase) =>
            purchase.partyName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<List<SaleModel>> searchSalesByPartyName(String query) async {
    final saleBox = await Hive.openBox<SaleModel>('saleBox');
    return saleBox.values
        .where((sale) =>
            sale.partyName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<List<PurchaseModel>> getPurchasesByDateRange(
      DateTime startDate, DateTime endDate) async {
    final purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
    return purchaseBox.values
        .where((purchase) =>
            purchase.date.isAfter(startDate) && purchase.date.isBefore(endDate))
        .toList();
  }

  Future<List<SaleModel>> getSalesByDateRange(
      DateTime startDate, DateTime endDate) async {
    final saleBox = await Hive.openBox<SaleModel>('saleBox');
    return saleBox.values
        .where((sale) =>
            sale.date.isAfter(startDate) && sale.date.isBefore(endDate))
        .toList();
  }

  Future<PurchaseModel?> getPurchaseById(String id) async {
    final purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
    return purchaseBox.get(id);
  }

  Future<SaleModel?> getSaleById(String id) async {
    final saleBox = await Hive.openBox<SaleModel>('saleBox');
    return saleBox.get(id);
  }

  Future<void> deletePurchase(String id) async {
    final purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
    await purchaseBox.delete(id);
    notifyListeners();
  }

  Future<void> deleteSale(String id) async {
    final saleBox = await Hive.openBox<SaleModel>('saleBox');
    await saleBox.delete(id);
    notifyListeners();
  }

  Future<void> updatePurchase(PurchaseModel updatedPurchase) async {
    final purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
    await purchaseBox.put(updatedPurchase.id, updatedPurchase);
    notifyListeners();
  }

  Future<void> updateSale(SaleModel updatedSale) async {
    final saleBox = await Hive.openBox<SaleModel>('saleBox');
    await saleBox.put(updatedSale.id, updatedSale);
    notifyListeners();
  }

  double calculateTotalPurchaseAmount() {
    return selectedItems.fold(0.0, (total, item) => total + item.subTotal);
  }

  double calculateTotalSaleAmount() {
    return selectedItems.fold(0.0, (total, item) => total + item.subTotal);
  }

  void showToast(BuildContext context, String message) {
    ToastService.show(
      context,
      message: message,
      type: ToastType.success,
    );
  }

  void setTransactionType(TransactionType type) {
    _transactionType = type;
    notifyListeners();
  }

  void setSalesType(SalesType type) {
    _salesType = type;
    notifyListeners();
  }

  void setPurchaseType(PurchaseType type) {
    _purchaseType = type;
    notifyListeners();
  }

  Future<SaleModel?> convertSaleType(
      SaleModel originalSale, SalesType newType) async {
    try {
      // Create a new sale with the updated type
      final convertedSale = originalSale.copyWith(
        type: newType,
        id: '${newType.name}_${originalSale.invoiceNumber}',
      );

      // Delete the original sale
      await deleteSale(originalSale.id!);

      // Add the converted sale
      final saleBox = await Hive.openBox<SaleModel>('saleBox');
      await saleBox.put(convertedSale.id, convertedSale);

      return convertedSale;
    } catch (e) {
      debugPrint('Error converting sale type: $e');
      return null;
    }
  }

  Future<PurchaseModel?> convertPurchaseType(
      PurchaseModel originalPurchase, PurchaseType newType) async {
    try {
      // Create a new purchase with the updated type
      final convertedPurchase = originalPurchase.copyWith(
        type: newType,
        id: '${newType.name}_${originalPurchase.invoiceNumber}',
      );

      // Delete the original purchase
      await deletePurchase(originalPurchase.id!);

      // Add the converted purchase
      final purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
      await purchaseBox.put(convertedPurchase.id, convertedPurchase);

      return convertedPurchase;
    } catch (e) {
      debugPrint('Error converting purchase type: $e');
      return null;
    }
  }

  void addPartialPayment(double amount, {bool isSale = true}) {
    if (isSale) {
      final currentReceived =
          double.tryParse(receivedAmountController.text) ?? 0.0;
      final newReceived = currentReceived + amount;
      receivedAmountController.text = newReceived.toStringAsFixed(2);
    } else {
      final currentPaid = double.tryParse(paidAmountController.text) ?? 0.0;
      final newPaid = currentPaid + amount;
      paidAmountController.text = newPaid.toStringAsFixed(2);
    }
    _updateBalance();
    notifyListeners();
  }

  List<PaymentRecord> _getCurrentPaymentHistory() {
    final receivedAmount =
        double.tryParse(receivedAmountController.text) ?? 0.0;
    if (receivedAmount > 0) {
      return [
        PaymentRecord(
          amount: receivedAmount,
          date: _invoiceDate,
          method: _paymentType,
          reference: 'Initial payment',
        )
      ];
    }
    return [];
  }

  Future<void> recordPayment({
    required String transactionId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? reference,
  }) async {
    try {
      final saleBox = await Hive.openBox<SaleModel>('saleBox');
      final purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
      final sale = saleBox.get(transactionId);
      final purchase = purchaseBox.get(transactionId);

      if (purchase != null) {
        // Update the purchase with new payment
        final newPaid = (purchase.paidAmount ?? 0) + amount;
        final newBalance = purchase.totalAmount - newPaid;

        final updatedPurchase = purchase.copyWith(
            paidAmount: newPaid,
            balanceAmount: newBalance,
            // Note: You'll need to add a paymentHistory field to your PurchaseModel
            paymentHistory: [...(purchase.paymentHistory ?? [])]);
        debugPrint(updatedPurchase.toString());
        await purchaseBox.put(transactionId, updatedPurchase);
        notifyListeners();
      } else if (sale != null) {
        // Update the sale with new payment
        final newReceived = (sale.receivedAmount ?? 0) + amount;
        final newBalance = sale.totalAmount - newReceived;

        final updatedSale = sale.copyWith(
            receivedAmount: newReceived,
            balanceAmount: newBalance,
            // Note: You'll need to add a paymentHistory field to your SaleModel
            paymentHistory: [...(sale.paymentHistory ?? [])]);
        debugPrint(updatedSale.toString());
        await saleBox.put(transactionId, updatedSale);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error recording payment: $e');
      rethrow;
    }
  }
}
