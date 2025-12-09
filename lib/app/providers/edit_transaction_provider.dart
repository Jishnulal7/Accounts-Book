import 'dart:convert';
import 'package:account_book/app/data/constants/invoice_prefix_manager.dart';
import 'package:account_book/app/data/helpers/enums/invoice_prefix.dart';
import 'package:account_book/app/data/helpers/enums/transaction_type.dart';
import 'package:account_book/app/data/model/payment_record.dart';
import 'package:account_book/app/providers/item_provider.dart';
import 'package:flutter/material.dart';
import 'package:account_book/app/data/model/item_selection_model.dart';
import 'package:account_book/app/data/model/party_model.dart';
import 'package:account_book/app/data/model/purchase_model.dart';
import 'package:account_book/app/data/model/sale_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditTransactionProvider with ChangeNotifier {
  final dynamic initialTransaction;
  final GlobalKey<FormState> billKey = GlobalKey<FormState>();

  late TextEditingController controller;
  late TextEditingController dateController;
  late TextEditingController itemController;
  late TextEditingController totalController;
  late TextEditingController balanceController;
  late TextEditingController amountController;
  late TextEditingController shippingChargeController;
  late TextEditingController packagingChargeController;
  late TextEditingController additionalChargeController;
  late TextEditingController roundOffController;
  late TextEditingController transportationNameController;
  late TextEditingController deliveryDateController;
  late TextEditingController vehicleNumberController;
  late TextEditingController deliveryLocationController;
  late TextEditingController discountController;

  DateTime _invoiceDate = DateTime.now();
  bool _isTextFieldFocused = false;
  bool _isPartySelected = false;
  bool isItemSelected = false;
  bool _isRoundedOff = false;
  bool _isFullyPaid = false;

  String _invoiceNumber = '1';
  String _selectedPartyName = '';
  String _paymentType = 'Cash';
  String _stateOfSupply = 'Select State';
  PrefixType prefixType = PrefixType.none;
  String customPrefix = '';
  final double _selectedPartyBalance = 0.0;
  double _originalTotal = 0.0;

  final TransactionType? _transactionType;
  final FocusNode focusNode = FocusNode();
  late Box<PartyModel> _hiveBox;
  List<ItemSelectionModel> selectedItems = [];
  List<String> transportationDetails = [];
  String? _selectedBankId;
  List<Map<String, String>> _bankAccounts = [];
  List<SavedPrefix> savedPrefixes = [];
  PrefixType selectedPrefix = PrefixType.none;
  SavedPrefix? selectedSavedPrefix;

// In EditTransactionProvider constructor
  EditTransactionProvider([this.initialTransaction, this._transactionType]) {
    _initializeControllers();
    _initializeHive();
    _setupListeners();
    if (initialTransaction != null) {
      _loadTransactionData();
    }
    loadSavedPrefixes(); // Add this
    loadBankDetails();
  }

  void _initializeControllers() {
    controller =
        TextEditingController(text: initialTransaction?.partyName ?? '');
    dateController = TextEditingController();
    itemController = TextEditingController();
    totalController = TextEditingController(
      text: initialTransaction?.totalAmount?.toString() ?? '0.00',
    );
    balanceController = TextEditingController(
      text: initialTransaction?.balanceAmount?.toString() ?? '0.00',
    );
    amountController = TextEditingController(
      text: _transactionType == TransactionType.purchase
          ? initialTransaction?.paidAmount?.toString() ?? '0.00'
          : initialTransaction?.receivedAmount?.toString() ?? '0.00',
    );
    shippingChargeController = TextEditingController(
      text: initialTransaction?.shippingCharges?.toString() ?? '0.00',
    );
    packagingChargeController = TextEditingController(
      text: initialTransaction?.packingCharges?.toString() ?? '0.00',
    );
    additionalChargeController = TextEditingController(
      text: initialTransaction?.additionalCharges?.toString() ?? '0.00',
    );
    roundOffController = TextEditingController();
    transportationNameController = TextEditingController();
    deliveryDateController = TextEditingController();
    vehicleNumberController = TextEditingController();
    deliveryLocationController = TextEditingController();
    discountController = TextEditingController(
      text: initialTransaction?.discounts?.toString() ?? '0.00',
    );
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

  Future<void> loadSavedPrefixes() async {
    try {
      savedPrefixes = await PrefixManager.getSavedPrefixes();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved prefixes: $e');
    }
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
    controller.addListener(textFieldFocusChange);
    balanceController.addListener(_updateBalance);
    focusNode.addListener(_onFocusChange);
  }

  void _loadTransactionData() {
    _invoiceNumber = initialTransaction.invoiceNumber;
    _invoiceDate = initialTransaction.date;
    _paymentType = initialTransaction.paymentType!;
    _stateOfSupply = initialTransaction.stateOfSupply.toString();
    totalController.text = initialTransaction.totalAmount.toString();
    amountController.text = _transactionType == TransactionType.purchase
        ? initialTransaction.paidAmount.toString()
        : initialTransaction.receivedAmount.toString();
    balanceController.text = initialTransaction.balanceAmount.toString();
    controller.text = initialTransaction.partyName;

    selectedItems = initialTransaction.item;
    transportationDetails = initialTransaction.transportaionDetails ?? [];

    // Initialize controllers
    transportationNameController.text =
        transportationDetails.isNotEmpty ? transportationDetails[0] : '';
    vehicleNumberController.text =
        transportationDetails.length > 1 ? transportationDetails[1] : '';
    deliveryDateController.text =
        transportationDetails.length > 2 ? transportationDetails[2] : '';
    deliveryLocationController.text =
        transportationDetails.length > 3 ? transportationDetails[3] : '';
    _isFullyPaid = initialTransaction.isFullyPaid;
    _isRoundedOff = initialTransaction.isRoundedOff;

    if (initialTransaction.paymentHistory != null &&
        initialTransaction.paymentHistory!.isNotEmpty) {
      // Calculate total from payment history
      double totalPaid = initialTransaction.paymentHistory!
          .fold(0.0, (sum, record) => sum + record.amount);
      amountController.text = totalPaid.toStringAsFixed(2);
    }
    if (initialTransaction.invoicePrefix != null) {
      if (initialTransaction.invoicePrefix == 'INV') {
        setPrefixType(PrefixType.inv);
      } else if (initialTransaction.invoicePrefix.isNotEmpty) {
        // Check if this is a saved prefix
        bool isSavedPrefix = savedPrefixes
            .any((p) => p.code == initialTransaction.invoicePrefix);
        if (isSavedPrefix) {
          setPrefixType(PrefixType.saved,
              savedPrefix: SavedPrefix(code: initialTransaction.invoicePrefix));
        } else {
          setPrefixType(PrefixType.custom,
              custom: initialTransaction.invoicePrefix);
        }
      } else {
        setPrefixType(PrefixType.none);
      }
    }
    updateTotalAmount();
    notifyListeners();
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

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    controller.dispose();
    dateController.dispose();
    itemController.dispose();
    totalController.dispose();
    amountController.dispose();
    balanceController.dispose();
    additionalChargeController.dispose();
    shippingChargeController.dispose();
    packagingChargeController.dispose();
    roundOffController.dispose();
    transportationNameController.dispose();
    deliveryDateController.dispose();
    vehicleNumberController.dispose();
    deliveryLocationController.dispose();
    discountController.dispose();
  }

  void textFieldFocusChange() {
    _isTextFieldFocused = controller.text.isNotEmpty;
    notifyListeners();
  }

  void _updateBalance() {
    final totalAmount = double.tryParse(totalController.text) ?? 0;
    final amount = double.tryParse(amountController.text) ?? 0;
    final balanceAmount = totalAmount - amount;
    balanceController.text = balanceAmount.toStringAsFixed(2);
    notifyListeners();
  }

  void updateTotalAmount() {
    double subtotal = calculateTotalSubTotal();
    double shippingCharge = double.tryParse(shippingChargeController.text) ?? 0;
    double packagingCharge =
        double.tryParse(packagingChargeController.text) ?? 0;
    double additionalCharge =
        double.tryParse(additionalChargeController.text) ?? 0;
    double discount = double.tryParse(discountController.text) ?? 0;
    double taxAmount = calculateTotalTaxAmount();
    double discountFromItem = calculateTotalDiscount();
    double total = subtotal +
        shippingCharge +
        packagingCharge +
        taxAmount +
        additionalCharge -
        discount -
        discountFromItem;

    totalController.text = total.toStringAsFixed(2);
    _updateBalance();
    notifyListeners();
  }

  void _onFocusChange() {
    _isTextFieldFocused = focusNode.hasFocus || controller.text.isNotEmpty;
    notifyListeners();
  }

  void selectParty(PartyModel party) {
    _selectedPartyName = party.name!;
    controller.text = _selectedPartyName;
    _isTextFieldFocused = false;
    _isPartySelected = true;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void updateSelectedItems(List<ItemSelectionModel> items) {
    selectedItems = items;
    isItemSelected = true;
    totalController.text = calculateTotalSubTotal().toStringAsFixed(2);
    notifyListeners();
  }

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

  void updateInvoiceDate(DateTime newDate) {
    _invoiceDate = newDate;
    dateController.text = DateFormat('dd MMM y').format(newDate);
    notifyListeners();
  }

  Future<void> onSave(
    BuildContext context,
    VoidCallback onTransactionUpdated,
    ItemProvider itemProvider,
  ) async {
    if (!billKey.currentState!.validate()) return;

    if (controller.text.isEmpty) {
      _showToast(context, 'Party name cannot be empty.');
      return;
    }

    if (selectedItems.isEmpty) {
      _showToast(context, 'Please add at least one item.');
      return;
    }

    if (totalController.text.isEmpty) {
      _showToast(context, "Total Amount can't be empty");
      return;
    }

    // Only check for duplicate invoice numbers if the number has changed
    if (initialTransaction.invoiceNumber != _invoiceNumber) {
      if (await _isInvoiceNumberExists(_invoiceNumber)) {
        _showToast(context, 'Invoice Number already exists');
        return;
      }
    }

    try {
      final updatedTransactionModel =
          await _createTransactionModel(itemProvider);
      if (updatedTransactionModel != null) {
        // If invoice number changed, delete the old transaction
        if (initialTransaction.invoiceNumber != _invoiceNumber) {
          if (_transactionType == TransactionType.purchase) {
            final box = await Hive.openBox<PurchaseModel>('purchaseBox');
            await box.delete(initialTransaction.id);
          } else {
            final box = await Hive.openBox<SaleModel>('saleBox');
            await box.delete(initialTransaction.id);
          }
        }

        onTransactionUpdated();
        Navigator.pop(context, updatedTransactionModel);
      }
    } catch (e) {
      _showToast(context, 'Error saving transaction: $e');
    }
  }

  Future<dynamic> _createTransactionModel(ItemProvider itemProvider) async {
    final totalAmount = double.tryParse(totalController.text) ?? 0;
    final amount = double.tryParse(amountController.text) ?? 0;
    final balanceAmount = totalAmount - amount;
    final shippingCharges = double.tryParse(shippingChargeController.text) ?? 0;
    final packagingCharges =
        double.tryParse(packagingChargeController.text) ?? 0;
    final additionalCharges =
        double.tryParse(additionalChargeController.text) ?? 0;
    final discounts = double.tryParse(discountController.text) ?? 0;

    transportationDetails = [
      transportationNameController.text,
      vehicleNumberController.text,
      deliveryDateController.text,
      deliveryLocationController.text,
    ];

    // Preserve the original payment history if it exists
    final paymentHistory =
        initialTransaction.paymentHistory ?? _getCurrentPaymentHistory();

    if (_transactionType == TransactionType.purchase) {
      final purchaseType = initialTransaction.type as PurchaseType;

      final updatedPurchaseModel = PurchaseModel(
        invoicePrefix: '',
        invoiceNumber: _invoiceNumber,
        partyName: controller.text,
        date: _invoiceDate,
        totalAmount: totalAmount,
        balanceAmount: balanceAmount,
        paidAmount: amount,
        type: purchaseType,
        paymentType: _paymentType,
        id: initialTransaction.id ?? 'purchase_$_invoiceNumber',
        item: selectedItems,
        stateOfSupply: _stateOfSupply,
        transportaionDetails: transportationDetails,
        isRoundedOff: _isRoundedOff,
        isFullyPaid: _isFullyPaid,
        additionalCharges: additionalCharges,
        discounts: discounts,
        packingCharges: packagingCharges,
        shippingCharges: shippingCharges,
        partyId: initialTransaction.partyId,
        paymentHistory: paymentHistory, // Use preserved payment history
      );

      final box = await Hive.openBox<PurchaseModel>('purchaseBox');
      await box.put(updatedPurchaseModel.id, updatedPurchaseModel);
      for (var item in selectedItems) {
        await itemProvider.updateStockForTransaction(
          item.id,
          item.quantity,
          false,
        );
      }
      return updatedPurchaseModel;
    } else {
      final salesType = initialTransaction.type as SalesType;

      final updatedSaleModel = SaleModel(
        invoicePrefix: '',
        invoiceNumber: _invoiceNumber,
        partyName: controller.text,
        date: _invoiceDate,
        totalAmount: totalAmount,
        balanceAmount: balanceAmount,
        receivedAmount: amount,
        type: salesType,
        paymentType: _paymentType,
        id: initialTransaction.id ?? 'sale_$_invoiceNumber',
        item: selectedItems,
        stateOfSupply: _stateOfSupply,
        transportaionDetails: transportationDetails,
        isRoundedOff: _isRoundedOff,
        isFullyPaid: _isFullyPaid,
        additionalCharges: additionalCharges,
        discounts: discounts,
        packingCharges: packagingCharges,
        shippingCharges: shippingCharges,
        partyId: initialTransaction.partyId,
        paymentHistory: paymentHistory,
      );

      final box = await Hive.openBox<SaleModel>('saleBox');
      await box.put(updatedSaleModel.id, updatedSaleModel);
      for (var item in selectedItems) {
        await itemProvider.updateStockForTransaction(
          item.id,
          item.quantity,
          true,
        );
      }
      return updatedSaleModel;
    }
  }

  Future<bool> _isInvoiceNumberExists(String invoiceNumber) async {
    if (_transactionType == TransactionType.purchase) {
      final box = await Hive.openBox<PurchaseModel>('purchaseBox');
      return box.values.any((purchase) =>
          purchase.invoiceNumber == invoiceNumber &&
          purchase.type == initialTransaction.type &&
          purchase.id != initialTransaction.id);
    } else {
      final box = await Hive.openBox<SaleModel>('saleBox');
      return box.values.any((sale) =>
          sale.invoiceNumber == invoiceNumber &&
          sale.type == initialTransaction.type &&
          sale.id != initialTransaction.id);
    }
  }

  Future<void> onDelete(
    BuildContext context,
    VoidCallback onTransactionDeleted,
    ItemProvider itemProvider,
  ) async {
    // Show a confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              const Text('Are you sure you want to delete this transaction?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        if (_transactionType == TransactionType.purchase) {
          final box = await Hive.openBox<PurchaseModel>('purchaseBox');
          await box.delete(initialTransaction.id);
          for (var item in selectedItems) {
            await itemProvider.updateStockForTransaction(
              item.id,
              item.quantity,
              false, // false because we're removing a purchase, so we need to decrease stock
            );
          }
        } else {
          final box = await Hive.openBox<SaleModel>('saleBox');
          await box.delete(initialTransaction.id);
          for (var item in selectedItems) {
            await itemProvider.updateStockForTransaction(
              item.id,
              item.quantity,
              true, // true because we're removing a sale, so we need to increase stock
            );
          }
        }
        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully')),
        );

        // Call the callback to update the dashboard
        onTransactionDeleted();

        // Navigate back to the previous screen
        Navigator.pop(context);
      } catch (e) {
        // Show an error message if deletion fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete transaction: $e')),
        );
      }
    }
  }

  void removeSelectedItem(int index) {
    if (index >= 0 && index < selectedItems.length) {
      selectedItems.removeAt(index);
      updateTotalAmount();
      notifyListeners();
    }
  }

  void updateSelectedItem(int index, ItemSelectionModel updatedItem) {
    if (index >= 0 && index < selectedItems.length) {
      selectedItems[index] = updatedItem;
      updateTotalAmount();
      notifyListeners();
    } else {
      debugPrint('Error: Invalid index $index for updating item');
    }
  }

  // Helper methods
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

  Future<List<PartyModel>> getAllParties() async {
    await _initializeHive();
    return _hiveBox.values.toList();
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

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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

  void setFullyPaid(bool value) {
    _isFullyPaid = value;
    if (value) {
      amountController.text = totalController.text;
      balanceController.text = "0.00";
    }
    notifyListeners();
  }

  void _roundOffTotal() {
    _originalTotal = double.parse(totalController.text);
    double roundedTotal = _originalTotal.round().toDouble();
    totalController.text = roundedTotal.toStringAsFixed(2);
    _updateBalance();
  }

  void _unroundTotal() {
    if (_originalTotal != 0.0) {
      totalController.text = _originalTotal.toStringAsFixed(2);
      _updateBalance();
    } else {
      updateTotalAmount();
    }
  }

  List<PaymentRecord> _getCurrentPaymentHistory() {
    final amount = double.tryParse(amountController.text) ?? 0.0;
    if (amount > 0) {
      return [
        PaymentRecord(
          amount: amount,
          date: _invoiceDate,
          method: _paymentType,
          reference: 'Initial payment',
        )
      ];
    }
    return [];
  }

  Future<bool> addPaymentRecord({
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? reference,
  }) async {
    if (initialTransaction == null) {
      debugPrint('Cannot add payment record - no transaction selected');
      return false;
    }

    final newRecord = PaymentRecord(
      amount: amount,
      date: paymentDate,
      method: paymentMethod,
      reference: reference ?? 'Additional payment',
    );

    // Initialize payment history if it doesn't exist
    initialTransaction.paymentHistory ??= [];

    // Add the new record
    initialTransaction.paymentHistory!.add(newRecord);

    // Update the amount controller with the new total
    final currentAmount = double.tryParse(amountController.text) ?? 0.0;
    amountController.text = (currentAmount + amount).toStringAsFixed(2);
    _updateBalance();
    notifyListeners();

    return true;
  }

  Future<void> updatePaymentRecord({
    required int index,
    required double newAmount,
    required DateTime newDate,
    required String newMethod,
    String? newReference,
  }) async {
    if (initialTransaction.paymentHistory == null ||
        index >= initialTransaction.paymentHistory!.length) {
      return;
    }

    // Calculate the difference to adjust the total
    final oldAmount = initialTransaction.paymentHistory![index].amount;
    final amountDifference = newAmount - oldAmount;

    // Update the record
    initialTransaction.paymentHistory![index] =
        initialTransaction.paymentHistory![index].copyWith(
      amount: newAmount,
      date: newDate,
      method: newMethod,
      reference: newReference,
    );

    // Update the total amount
    final currentAmount = double.tryParse(amountController.text) ?? 0.0;
    amountController.text =
        (currentAmount + amountDifference).toStringAsFixed(2);
    _updateBalance();
    notifyListeners();
  }

  Future<void> removePaymentRecord(int index) async {
    if (initialTransaction.paymentHistory == null ||
        index >= initialTransaction.paymentHistory!.length) {
      return;
    }

    // Get the amount being removed
    final removedAmount = initialTransaction.paymentHistory![index].amount;

    // Remove the record
    initialTransaction.paymentHistory!.removeAt(index);

    // Update the total amount
    final currentAmount = double.tryParse(amountController.text) ?? 0.0;
    amountController.text = (currentAmount - removedAmount).toStringAsFixed(2);
    _updateBalance();
    notifyListeners();
  }

  Future<List<PaymentRecord>> getPaymentHistory() async {
    if (initialTransaction.paymentHistory != null) {
      return initialTransaction.paymentHistory!;
    }
    return _getCurrentPaymentHistory();
  }

  // Getters
  bool get isTextFieldFocused => _isTextFieldFocused;
  bool get isPartySelected => _isPartySelected;
  String get invoiceNumber => _invoiceNumber;
  DateTime get invoiceDate => _invoiceDate;
  String get selectedPartyName => _selectedPartyName;
  String get paymentType => _paymentType;
  String get stateOfSupply => _stateOfSupply;
  double get selectedPartyBalance => _selectedPartyBalance;
  List<String> get getTransportationDetails => transportationDetails;
  bool get isRoundedOff => _isRoundedOff;
  bool get isFullyPaid => _isFullyPaid;
  String? get selectedBankId => _selectedBankId;
  List<Map<String, String>> get bankAccounts => _bankAccounts;
}
