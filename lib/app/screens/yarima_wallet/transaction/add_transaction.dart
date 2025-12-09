import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/color_helper.dart';
import 'package:account_book/app/data/helpers/enums/toast.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/data/model/transfer_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_helper.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/attendance_name_selection.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/components/category_service.dart';
import 'package:account_book/app/screens/yarima_wallet/category/components/category_helper.dart';
import 'package:account_book/app/screens/yarima_wallet/transaction/account_selection.dart';
import 'package:account_book/app/screens/yarima_wallet/transaction/category_selection.dart';
import 'package:account_book/app/widgets/custom_button.dart';
import 'package:account_book/app/widgets/custom_switch.dart';
import 'package:account_book/app/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Function(TransactionModel) onAddTransaction;
  final Function onAddAttendance;
  final Box<TransactionModel> transactionBox;
  final TransactionType? initialTransactionType;
  const AddTransactionScreen({
    super.key,
    required this.selectedDate,
    required this.onAddTransaction,
    required this.transactionBox,
    required this.onAddAttendance,
    this.initialTransactionType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  int transactionsIndex = 1;
  int attendanceIndex = 0;
  double amount = 0.0;
  double totalAmount = 0.0;
  double balance = 0.0;
  double openingBalance = 0.0;
  double originalWage = 0.0;

  String description = '';
  String siteName = '';
  String? selectedCategory = '';
  String? selectedcategoryName;
  String? selectedGeneralCategory;
  String? selectedGeneralSubCategory;
  String? selectedSubCategory = '';
  String? selectedFirstAccountName;
  String? firstSubAccountName = '';
  String? secondSubAccountName = '';
  String? selectedSecondAccountName;
  String id = const Uuid().v1();
  String selectedName = 'Name';
  String subAccountName = '';

  bool isReceipt = false;
  bool isPayment = true;
  bool isTransfer = false;
  bool isAmountValid = true;
  bool isAttendance = false;
  // bool isAttendanceEnabled = false;
  bool showCalculator = false;
  bool isCalculatorEnabled = false;
  bool isGeneralCategory = false;
  AccountHelper accountModel = AccountHelper();
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController siteController = TextEditingController();
  TextEditingController wageController = TextEditingController();
  TextEditingController extraChargesController = TextEditingController();
  TextEditingController activeController = TextEditingController();
  final _key = GlobalKey<FormState>();
  final CategoryService _categoryService = CategoryService();

  String? selectedCategoryIcon;
  String? selectedFirstAccountIcon;
  String? selectedSecondAccountIcon;
  TransactionType transactionType = TransactionType.payment;

  late DateTime selectedDate;

  String paymentPath = 'assets/categories/payment.png';
  String receiptPath = 'assets/categories/receipt.png';
  String defaultWalletPath = 'assets/categories/wallet.png';

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    _initializeCategory();
    _loadLastSelections();
    // _loadAttendanceState();
    wageController.addListener(_updateBalance);
    extraChargesController.addListener(_updateBalance);
    amountController.addListener(_updateBalance);
    _preserveTransactionType();

    // Set the initial transaction type if provided
    if (widget.initialTransactionType != null) {
      setState(() {
        transactionType = widget.initialTransactionType!;
        isReceipt = transactionType == TransactionType.receipt;
        isPayment = transactionType == TransactionType.payment;
        isTransfer = transactionType == TransactionType.transfer;
        transactionsIndex = isReceipt
            ? 0
            : isPayment
                ? 1
                : 2;
      });
    }
  }

  void _updateBalance() {
    setState(() {
      double wage = double.tryParse(wageController.text) ?? 0;
      double extraCharges = double.tryParse(extraChargesController.text) ?? 0;
      double payment = double.tryParse(amountController.text) ?? 0;
      balance = openingBalance + wage + extraCharges - payment;
      totalAmount = wage + extraCharges;
    });
  }

  void _initializeCategory() {
    setState(() {
      selectedCategory = isReceipt
          ? CategoryHelper().receiptCategories[0]['name']
          : CategoryHelper().paymentCategories[0]['name'];
    });
  }

  void _resetSelections() {
    setState(() {
      selectedcategoryName = null;
      selectedCategoryIcon = null;
      selectedSubCategory = null;
      _initializeCategory();
    });
  }

  Future<void> _loadOpeningBalance() async {
    var box = await Hive.openBox<AttendanceModel>('attendanceBox');
    var lastEntry = box.values.lastWhere(
      (entry) =>
          entry.date.isBefore(selectedDate) && entry.name == selectedCategory,
      orElse: () => AttendanceModel(
        generalCategoryName: '',
        date: selectedDate,
        name: '',
        isPresent: false,
        wage: 0,
        siteName: '',
        extraCharges: 0,
        description: '',
        payment: 0,
        balance: 0,
        account: '',
        openingBalance: 0,
        subName: '',
        id: '',
        categoryName: '',
        accountPath: '',
        categoryPath: '',
        generalSubCategory: '',
        subCategory: '',
        subAccount: '',
      ),
    );
    setState(() {
      openingBalance = lastEntry.balance;
    });
    _updateBalance();
  }

  Future<void> _loadLastSelections() async {
    // final prefs = await SharedPreferences.getInstance();
    setState(() {
      // transactionsIndex = prefs.getInt('lastToggleIndex') ?? 1;
      isReceipt = transactionsIndex == 0;
      isPayment = transactionsIndex == 1;
      isTransfer = transactionsIndex == 2;
      selectedFirstAccountName = 'Cash';
      selectedFirstAccountIcon = 'assets/categories/cash-bill-dollar.png';
    });
  }

  // Future<void> _saveToggleIndex(int index) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setInt('lastToggleIndex', index);
  // }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: Locale('en', 'GB'),
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        // Preserve the original time while updating the date
        selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          selectedDate.hour,
          selectedDate.minute,
          selectedDate.second,
        );
      });
      await _loadOpeningBalance();
      // Add this: Preserve transaction type after date change
      _preserveTransactionType();
    }
  }

// Add this new method to preserve transaction type
  void _preserveTransactionType() {
    setState(() {
      // Ensure transaction type matches the current toggle state
      transactionType = isReceipt
          ? TransactionType.receipt
          : isTransfer
              ? TransactionType.transfer
              : TransactionType.payment;

      // Ensure the indices match the transaction type
      if (isReceipt) {
        transactionsIndex = 0;
      } else if (isPayment) {
        transactionsIndex = 1;
      } else if (isTransfer) {
        transactionsIndex = 2;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            _buildSwitchRow(),
            _buildDate(),
            if (isAttendance) _buildAttendanceForm(),
            _buildTransactionForm()
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Attendance',
          style: TextStyle(
              fontWeight: isAttendance ? FontWeight.normal : FontWeight.bold,
              color: ColorHelper().darkorWhite(context)),
        ),
        const SizedBox(width: 10),
        CustomSwitch(
          isSwitchOn: isAttendance,
          onToggle: (value) {
            setState(() {
              isAttendance = value;
              if (value) {
                // When switch is turned on, change to payment category
                transactionsIndex = 1;
                transactionType = TransactionType.payment;
                isReceipt = false;
                isPayment = true;
                isTransfer = false;
                _resetSelections();
                // _saveToggleIndex(transactionsIndex);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceForm() {
    ThemeData currentTheme = Theme.of(context);
    Color textColor = currentTheme.brightness == Brightness.dark
        ? AppColor.kPurple
        : AppColor.kPurple;
    return SingleChildScrollView(
      child: Form(
          child: Column(
        children: [
          // if (isAttendanceEnabled)
          _buildAttendanceToggleSwitch(textColor),
          _buildNameButton(),
        ],
      )),
    );
  }

  Widget _buildTransactionForm() {
    return Form(
      key: _key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (!isAttendance) _buildTransactionToggleSwitch(AppColor.kPurple),
          _buildAccountAndCategorySelection(),
          if (isAttendance)
            _buildAmountAndDescriptionFields(
              'Wage',
              wageController,
              'Site Name',
              siteController,
            ),
          if (isAttendance) const SizedBox(height: 10),
          _buildAmountAndDescriptionFields(
            'Amount',
            amountController,
            'Description',
            descriptionController,
          ),
          const SizedBox(height: 10),
          if (isAttendance)
            Align(
              alignment: Alignment.centerRight,
              child: _buildAmountField('Extra Charges', extraChargesController),
            ),
          if (isAttendance) const SizedBox(height: 10),
          if (isAttendance) _buildTotal(),
          if (isAttendance) _buildOpBalance(),
          if (isAttendance) _buildPayment(),
          if (isAttendance) _buildBalance(balance),
          _buildAddButton(),
        ],
      ),
    );
  }

  _buildOpBalance() {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Align(
        alignment: Alignment.topLeft,
        child: Text(
          'Op Bal: $currencySymbol$openingBalance',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ));
  }

  _buildPayment() {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    var payment = double.tryParse(amountController.text) ?? 0;
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        'Payment: $currencySymbol $payment',
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _buildTotal() {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        'Wage : $currencySymbol$totalAmount',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _buildBalance(double balance) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        'Closing Balance: $currencySymbol$balance',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDate() {
    String date = DateFormat('dd MMMM y').format(selectedDate);
    String formattedTime = DateFormat.jms().format(selectedDate);
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => _selectDate(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(date),
            const SizedBox(
              width: 5,
            ),
            Text(formattedTime),
          ],
        ),
      ),
    );
  }

  Widget _buildNameButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton(
        onPressed: () {
          nameSelection();
        },
        child: Text(selectedName),
      ),
    );
  }

  void nameSelection() async {
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return AttendanceNameSelector(
          categories: _categoryService.getCategories(),
          onNameAdded: () {
            setState(() {});
          },
          onSubcategorySelected: (String fullName, double openingBalance,
              double wage, String subAccount) {
            setState(() {
              selectedName = fullName;
              selectedCategory = fullName;
              subAccountName = subAccount;
              wageController.text = wage.toStringAsFixed(1);
              originalWage = wage;
              this.openingBalance = openingBalance;
              _updateBalance();
            });
          },
        );
      },
    );
  }

  Widget _buildAttendanceToggleSwitch(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ToggleSwitch(
        cornerRadius: 20,
        activeBgColor: [textColor],
        minWidth: 100,
        activeBgColors: [
          [AppColor.kGreen],
          [AppColor.kRed],
        ],
        initialLabelIndex: attendanceIndex,
        labels: const ['Present', 'Absent'],
        onToggle: (index) {
          setState(() {
            attendanceIndex = index!;
            if (attendanceIndex == 1) {
              // Absent
              wageController.text = '0';
            } else {
              // Present
              if (selectedName != 'Name') {
                wageController.text = originalWage.toStringAsFixed(1);
              }
            }
            _updateBalance();
          });
        },
      ),
    );
  }

  Widget _buildTransactionToggleSwitch(Color textColor) {
    return Visibility(
      visible: !isAttendance,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ToggleSwitch(
          activeBgColor: [textColor],
          minWidth: 100,
          cornerRadius: 20,
          activeBgColors: [
            [AppColor.kGreen],
            [AppColor.kRed],
            [AppColor.kPrimary]
          ],
          initialLabelIndex: transactionsIndex,
          labels: const ['Receipt', 'Payment', 'Transfer'],
          onToggle: (index) {
            setState(() {
              transactionsIndex = index!;
              transactionType = index == 0
                  ? TransactionType.receipt
                  : index == 1
                      ? TransactionType.payment
                      : TransactionType.transfer;
              isReceipt = index == 0;
              isPayment = index == 1;
              isTransfer = index == 2;
              _resetSelections();
              // _saveToggleIndex(transactionsIndex);
            });
          },
        ),
      ),
    );
  }

  Widget _buildAccountAndCategorySelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: transactionsIndex == 2
          ? _buildTransferAccountSelection()
          : _buildPaymentOrReceiptSelection(),
    );
  }

  Widget _buildTransferAccountSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAccountButton(1, selectedFirstAccountName,
            selectedFirstAccountIcon, firstSubAccountName),
        const SizedBox(width: 16),
        _buildAccountButton(2, selectedSecondAccountName,
            selectedSecondAccountIcon, secondSubAccountName),
      ],
    );
  }

  Widget _buildPaymentOrReceiptSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAccountButton(1, selectedFirstAccountName,
            selectedFirstAccountIcon, firstSubAccountName),
        const SizedBox(width: 16),
        _buildCategoryButton(),
      ],
    );
  }

  Widget _buildAccountButton(int accountIndex, String? accountName,
      String? accountIcon, String? subAccountName) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => _accountSelection(accountIndex),
        label: Column(
          children: [
            if (subAccountName != null && subAccountName.isNotEmpty)
              Text(
                subAccountName,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              accountName ?? 'Account',
              style: TextStyle(
                fontSize: subAccountName != null && subAccountName.isNotEmpty
                    ? 14
                    : null,
                color: subAccountName != null && subAccountName.isNotEmpty
                    ? Colors.grey
                    : null,
              ),
            )
          ],
        ),
        icon: accountIcon != null
            ? Image.asset(
                accountIcon,
                width: 24,
              )
            : Image.asset(defaultWalletPath, width: 24),
      ),
    );
  }

  Widget _buildCategoryButton() {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => categorySelection(
          isPayment
              ? CategoryHelper().paymentCategories
              : CategoryHelper().receiptCategories,
        ),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedSubCategory != null && selectedSubCategory!.isNotEmpty)
              Text(
                selectedSubCategory!,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              isGeneralCategory
                  ? (selectedGeneralCategory ?? 'General Category')
                  : (selectedcategoryName ?? 'Category'),
              style: TextStyle(
                fontSize: selectedSubCategory != null &&
                        selectedSubCategory!.isNotEmpty
                    ? 14
                    : null,
                color: selectedSubCategory != null &&
                        selectedSubCategory!.isNotEmpty
                    ? Colors.grey
                    : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        icon: selectedCategoryIcon != null
            ? Image.asset(
                selectedCategoryIcon!,
                width: 24,
              )
            : Image.asset(transactionsIndex == 0 ? receiptPath : paymentPath,
                width: 24),
      ),
    );
  }

  Widget _buildAmountAndDescriptionFields(
    String amountLabel,
    TextEditingController contoller,
    String descriptionLabel,
    TextEditingController descriptionController,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildAmountField(amountLabel, contoller),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              _buildDescriptionField(descriptionLabel, descriptionController),
        ),
      ],
    );
  }

  Widget _buildAmountField(String label, TextEditingController controller) {
    ThemeData currentTheme = Theme.of(context);
    double width = MediaQuery.of(context).size.width;
    Color color = currentTheme.brightness == Brightness.dark
        ? AppColor.kWhite
        : AppColor.kGrayscale100;
    return SizedBox(
      width: isAttendance ? width / 2.25 : width,
      child: TextFormField(
        controller: controller,
        maxLength: 8,
        decoration: InputDecoration(
          counterText: '',
          labelText: label,
          errorText: isAmountValid ? null : 'Invalid amount',
          prefixIcon: Icon(
            Icons.currency_rupee,
            color: AppColor.kPurple,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: AppColor.kRed,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: color,
            ),
          ),
        ),
        onTap: () {
          setState(() {
            activeController = controller;
          });
        },
        keyboardType: TextInputType.number,
        onChanged: (_) => _updateBalance(),
        validator: (value) {
          if (isAttendance) {
            // When attendance is enabled, allow empty or zero values
            return null;
          } else {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }

            double? parsedValue = double.tryParse(value);
            if (parsedValue == null || parsedValue <= 0) {
              return 'Amount must be greater than zero';
            }
          }

          return null;
        },
      ),
    );
  }

  Widget _buildDescriptionField(
    String descriptionLabel,
    TextEditingController descriptionController,
  ) {
    ThemeData currentTheme = Theme.of(context);

    Color color = currentTheme.brightness == Brightness.dark
        ? AppColor.kWhite
        : AppColor.kGrayscale100;
    return TextFormField(
      decoration: InputDecoration(
        labelText: descriptionLabel,
        prefixIcon: Icon(
          Icons.edit_note,
          color: AppColor.kPurple,
        ),
        labelStyle: const TextStyle(),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(
            color: AppColor.kRed,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(
            color: color,
          ),
        ),
      ),
      onChanged: (value) {
        setState(() {
          if (isAttendance && descriptionController == siteController) {
            siteName = value;
          } else {
            description = value;
          }
        });
      },
    );
  }

  void _clearForm() {
    setState(() {
      selectedName = 'Select Category';
      attendanceIndex = 0;
      wageController.clear();
      siteController.clear();
      extraChargesController.clear();
      descriptionController.clear();
      amountController.clear();
      balance = 0.0;
    });
  }

  Widget _buildAddButton() {
    return CustomOutlineButton(
      height: 40,
      width: 130,
      borderRadius: 20,
      onTap: _onAddButtonPressed,
      text: 'Save',
    );
  }

  void _onAddButtonPressed() {
    if (isAttendance) {
      _saveAttendance();
    } else {
      _saveTransaction();
    }
  }

  void _saveAttendance() async {
    if (_key.currentState!.validate() &&
        selectedName != 'Name' &&
        attendanceIndex != -1) {
      // Current problematic code
      double extraCharges = double.tryParse(extraChargesController.text) ?? 0;
      double payment = double.tryParse(amountController.text) ?? 0;
      double wage = double.tryParse(wageController.text) ?? 0;
      final bool isGeneralCategoryTransaction =
          isGeneralCategory && selectedGeneralCategory != null;
      AttendanceModel attendanceModel = AttendanceModel(
        date: selectedDate,
        name: selectedName,
        isPresent: attendanceIndex == 0,
        wage: wage,
        siteName: siteName,
        extraCharges: extraCharges,
        description: description,
        payment: payment,
        balance: balance,
        account: selectedFirstAccountName.toString(),
        openingBalance: openingBalance,
        subName: subAccountName,
        id: id,
        categoryName: isGeneralCategoryTransaction
            ? selectedGeneralCategory
            : selectedcategoryName,
        categoryPath: selectedCategoryIcon ?? paymentPath,
        accountPath: selectedFirstAccountIcon.toString(),
        generalCategoryName: '',
        generalSubCategory: '',
        subCategory: isGeneralCategoryTransaction
            ? selectedGeneralSubCategory
            : selectedSubCategory ?? '',
        subAccount: firstSubAccountName ?? '',
      );

      var box = await Hive.openBox<AttendanceModel>('attendanceBox');
      await box.add(attendanceModel);
      widget.onAddAttendance();

      ToastService.show(
        context,
        message: 'Attendance saved successfully',
        type: ToastType.success,
      );
      _clearForm();
      Navigator.pop(context);
    } else if (selectedName == 'Name') {
      ToastService.show(
        context,
        message: 'Please select a name',
        type: ToastType.warning,
      );
    } else if (attendanceIndex == -1) {
      ToastService.show(
        context,
        message: 'Please select attendance status',
        type: ToastType.warning,
      );
    }
  }

  void _saveTransaction() {
    if (_key.currentState?.validate() ?? false) {
      if (_isFormValid()) {
        try {
          // Double check transaction type before saving
          _preserveTransactionType();

          TransactionModel newTransaction = _createTransaction();
          widget.onAddTransaction(newTransaction);
          Navigator.pop(context);
          ToastService.show(
            context,
            message: 'Transaction saved successfully',
            type: ToastType.success,
          );
        } catch (e) {
          debugPrint('Error saving transaction: $e');
          ToastService.show(
            context,
            message: 'Failed to save transaction. Please try again.',
            type: ToastType.error,
          );
        }
      } else {
        _showErrorMessage();
      }
    }
  }

  bool _isFormValid() {
    return ((transactionsIndex != 2 &&
            selectedcategoryName != null &&
            selectedFirstAccountName != null) ||
        (transactionsIndex == 2 &&
            selectedFirstAccountName != null &&
            selectedSecondAccountName != null &&
            selectedFirstAccountName != selectedSecondAccountName));
  }

  TransactionModel _createTransaction() {
    amount = double.tryParse(amountController.text) ?? 0.0;
    if (transactionsIndex == 0 || transactionsIndex == 1) {
      // Determine if this is a general category transaction
      final bool isGeneralCategoryTransaction =
          isGeneralCategory && selectedGeneralCategory != null;

      return TransactionModel(
        toSubAccount: secondSubAccountName ?? '',
        fromSubAccount: firstSubAccountName,
        id: id,
        date: selectedDate,
        amount: amount,
        description: description,
        // Only set categoryName if it's not a general category transaction
        categoryName: isGeneralCategoryTransaction
            ? selectedGeneralCategory
            : selectedcategoryName,
        transactionType: transactionType,
        iconData: selectedCategoryIcon,
        fromAccount: selectedFirstAccountName.toString(),
        toAccount: selectedSecondAccountName.toString(),
        fromAccountImagePath: selectedFirstAccountIcon ?? defaultWalletPath,
        toAccountImagePath: selectedSecondAccountIcon ?? defaultWalletPath,
        subCategory: isGeneralCategoryTransaction
            ? selectedGeneralSubCategory
            : selectedSubCategory,
        // Only set general category fields if it's a general category transaction
        generalCategory: '',
        generalSubCategory: '',
      );
    } else {
      // Transfer transaction remains unchanged
      return Transfer(
        id: id,
        amount: amount,
        description: description,
        date: selectedDate,
        fromAccount: selectedFirstAccountName.toString(),
        toAccount: selectedSecondAccountName.toString(),
        transactionType: transactionType,
        fromAccountImagePath: selectedFirstAccountIcon ?? defaultWalletPath,
        toAccountImagePath: selectedSecondAccountIcon ?? defaultWalletPath,
        fromSubAccount: firstSubAccountName,
        toSubAccount: secondSubAccountName ?? '',
      );
    }
  }

  void _showErrorMessage() {
    String errorMessage = '';
    if (transactionsIndex == 0 || transactionsIndex == 1) {
      if (selectedFirstAccountName == null) {
        errorMessage = 'Select the account';
      } else if (selectedcategoryName == null) {
        errorMessage = 'Select the category';
      } else if (amountController.text.isEmpty) {
        errorMessage = 'Please enter amount';
      }
    } else if (transactionsIndex == 2 &&
        (selectedFirstAccountName == null ||
            selectedSecondAccountName == null)) {
      errorMessage = 'Select both accounts';
    } else if (transactionsIndex == 2 &&
        selectedFirstAccountName == selectedSecondAccountName) {
      errorMessage = 'Select different accounts';
    } else if (transactionsIndex == 2 && amountController.text.isEmpty) {
      errorMessage = 'Please enter amount';
    }
    ToastService.show(
      context,
      message: errorMessage,
      type: ToastType.error,
    );
  }

  Future<void> _accountSelection(int accountIndex) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return AccountSelection(
              accounts: accountModel.accountCategories,
              selectedDate: widget.selectedDate,
              onCategorySelected: (String selectedAccount,
                  String? subAccountName, String imagePath) {
                setState(() {
                  if (accountIndex == 1) {
                    selectedFirstAccountName = selectedAccount;
                    selectedFirstAccountIcon = imagePath;
                    firstSubAccountName = subAccountName;
                  } else {
                    selectedSecondAccountName = selectedAccount;
                    selectedSecondAccountIcon = imagePath;
                    secondSubAccountName = subAccountName;
                  }
                });
              },
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        if (accountIndex == 1) {
          selectedFirstAccountName = result['name'];
          selectedFirstAccountIcon = result['imagePath'];
          firstSubAccountName = result['subAccount'];
        } else {
          selectedSecondAccountName = result['name'];
          selectedSecondAccountIcon = result['imagePath'];
          secondSubAccountName = result['subAccount'];
        }
      });
    }
  }

  void addCategory(String name, String icon, TransactionType type) {
    setState(() {
      CategoryHelper().addCategory(name, icon, type);
      selectedCategory = name;
    });
  }

  void categorySelection(List<Map<String, dynamic>> categories) async {
    var transactionType =
        isPayment ? TransactionType.payment : TransactionType.receipt;
    var result = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return CategorySelection(
              categories: categories,
              transactionType: transactionType,
              onCategoryCreated: (String newCategoryName, String selectedIcon) {
                setState(() {
                  addCategory(
                    newCategoryName,
                    selectedIcon,
                    transactionType,
                  );
                });
              },
              onCategorySelected: (
                String categoryName,
                String? subcategoryName,
                String? icon, {
                String? generalCategory,
                String? generalSubCategory,
              }) {
                setState(() {
                  selectedcategoryName = categoryName;
                  selectedCategoryIcon = icon;
                  selectedSubCategory = subcategoryName;
                  selectedGeneralCategory = generalCategory;
                  selectedGeneralSubCategory = generalSubCategory;
                  isGeneralCategory = generalCategory != null;
                  // Preserve the transaction type here
                  transactionType = isReceipt
                      ? TransactionType.receipt
                      : TransactionType.payment;
                });
              },
              previouslySelectedCategory: selectedcategoryName,
              selectedDailyDate: widget.selectedDate,
              transactionBox: widget.transactionBox,
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() {
        selectedcategoryName = result['name'];
        selectedCategoryIcon = result['imagePath'];
        selectedSubCategory = result['subcategory'];
        selectedGeneralCategory = result['generalCategory'];
        isGeneralCategory = result['generalCategory'] != null;
      });
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    wageController.dispose();
    extraChargesController.dispose();
    siteController.dispose();
    super.dispose();
  }
}
