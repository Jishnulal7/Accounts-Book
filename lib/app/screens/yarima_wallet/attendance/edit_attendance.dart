import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/enums/toast.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_helper.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/attendance_name_selection.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/components/category_service.dart';
import 'package:account_book/app/screens/yarima_wallet/category/components/category_helper.dart';
import 'package:account_book/app/screens/yarima_wallet/transaction/account_selection.dart';
import 'package:account_book/app/screens/yarima_wallet/transaction/category_selection.dart';
import 'package:account_book/app/widgets/custom_button.dart';
import 'package:account_book/app/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:provider/provider.dart';

class EditAttendanceScreen extends StatefulWidget {
  final AttendanceModel attendance;
  final Function(AttendanceModel) onSave;
  final DateTime selectedDailyDate;
  final Box<TransactionModel> transactionBox;
  const EditAttendanceScreen({
    super.key,
    required this.attendance,
    required this.onSave,
    required this.selectedDailyDate,
    required this.transactionBox,
  });

  @override
  EditAttendanceScreenState createState() => EditAttendanceScreenState();
}

class EditAttendanceScreenState extends State<EditAttendanceScreen> {
  late DateTime selectedDate;
  final _key = GlobalKey<FormState>();
  final CategoryService _categoryService = CategoryService();
  AccountHelper accountModel = AccountHelper();

  late int toggleIndex;
  late String selectedName;
  late String selectAccount;
  String? subAccountName;

  late TextEditingController wageController;
  late TextEditingController siteController;
  late TextEditingController extraChargesController;
  late TextEditingController descriptionController;
  late TextEditingController amountController;

  double balance = 0.0;
  double openingBalance = 0.0;
  double totalAmount = 0.0;

  bool isPayment = true;
  bool isGeneralCategory = false;
  bool showCalculator = false;
  bool isCalculatorEnabled = false;
  late TextEditingController activeController;
  String? selectedGeneralCategory;
  String? selectedcategoryName;
  String? selectedSubCategory;
  String? selectedCategoryIcon;
  String paymentPath = 'assets/categories/payment.png';
  String receiptPath = 'assets/categories/receipt.png';
  String defaultWalletPath = 'assets/categories/wallet.png';
  String? selectedFirstAccountIcon;
  String? selectedFirstAccountName;
  TransactionType transactionType = TransactionType.payment;
  String? selectedSubAccountName;
  String? selectedGeneralSubCategory;
  @override
  void initState() {
    super.initState();
    selectedDate = widget.attendance.date;
    toggleIndex = widget.attendance.isPresent ? 0 : 1;
    selectedName = widget.attendance.name;
    selectAccount = widget.attendance.account;
    subAccountName = widget.attendance.subName;
    selectedFirstAccountName = widget.attendance.account;
    selectedcategoryName = widget.attendance.categoryName;
    selectedCategoryIcon = widget.attendance.categoryPath;
    selectedFirstAccountIcon = widget.attendance.accountPath;
    selectedGeneralSubCategory = widget.attendance.generalSubCategory ?? '';
    selectedSubAccountName = widget.attendance.subAccount ?? '';
    selectedGeneralCategory = widget.attendance.generalCategoryName;
    selectedSubCategory = widget.attendance.subCategory ?? '';
    isGeneralCategory =
        selectedGeneralCategory != null && selectedGeneralCategory!.isNotEmpty;
    wageController =
        TextEditingController(text: widget.attendance.wage.toString());
    siteController = TextEditingController(text: widget.attendance.siteName);
    extraChargesController =
        TextEditingController(text: widget.attendance.extraCharges.toString());
    descriptionController =
        TextEditingController(text: widget.attendance.description);
    amountController =
        TextEditingController(text: widget.attendance.payment.toString());

    balance = widget.attendance.balance;
    openingBalance = widget.attendance.openingBalance;

    wageController.addListener(updateBalance);
    extraChargesController.addListener(updateBalance);
    amountController.addListener(updateBalance);

    _loadCalculatorSetting();
  }

  @override
  void dispose() {
    wageController.dispose();
    siteController.dispose();
    extraChargesController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void updateBalance() {
    setState(() {
      double wage = double.tryParse(wageController.text) ?? 0;
      double extraCharges = double.tryParse(extraChargesController.text) ?? 0;
      double payment = double.tryParse(amountController.text) ?? 0;
      balance = openingBalance + wage + extraCharges - payment;
      totalAmount = wage + extraCharges;
    });
  }

  Future<void> _loadCalculatorSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isCalculatorEnabled = prefs.getBool('isCalculator') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData currentTheme = Theme.of(context);
    Color textColor = currentTheme.brightness == Brightness.dark
        ? AppColor.kPurple
        : AppColor.kPurple;
    double screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Form(
        key: _key,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            spacing: 10,
            children: [
              _buildDateAndAttendance(),
              _buildToggleSwitch(textColor),
              _buildAccountButton(),

              _buildCategoryAndAccountsButton(),

              _buildAmountAndDescriptionFields(
                'Wage',
                wageController,
                'Site Name',
                siteController,
              ),
              const SizedBox(height: 5),
              _buildAmountAndDescriptionFields(
                'Extra charges',
                extraChargesController,
                'Description',
                descriptionController,
              ),

              _buildPaymentSection(screenWidth),

              _buildTotal(),
              _buildOpBalance(),
              _buildBalance(balance),
              _buildPayment(),
              // if (showCalculator) _buildCalculator(),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateAndAttendance() {
    String date = DateFormat('dd MMMM y').format(selectedDate);
    String formattedTime = DateFormat.jm().format(selectedDate);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            _selectDate(context);
          },
          child: Row(
            children: [
              Text(date),
              const SizedBox(width: 5),
              Text(formattedTime),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          selectedDate.hour,
          selectedDate.minute,
          selectedDate.second,
        );
      });
    }
  }

  Widget _buildToggleSwitch(Color textColor) {
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
        initialLabelIndex: toggleIndex,
        labels: const ['Present', 'Absent'],
        onToggle: (index) {
          setState(() {
            toggleIndex = index!;
            if (toggleIndex == 1) {
              // Absent
              wageController.text = '0';
            }
          });
        },
      ),
    );
  }

  void setAttendanceStatus(bool isPresent) {
    setState(() {
      toggleIndex = isPresent ? 0 : 1;
      if (!isPresent) {
        wageController.text = '0';
      }
    });
  }

  Widget _buildAccountButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton(
          onPressed: () {
            accountSelection();
          },
          child: Text(selectedName),
        ),
      ],
    );
  }

  Widget _buildOpBalance() {
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
      ),
    );
  }

  void accountSelection() async {
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return AttendanceNameSelector(
          categories: _categoryService.getCategories(),
          onSubcategorySelected: (String fullName, double wage,
              double openingBalance, String subAccount) {
            setState(() {
              selectedName = fullName;
              subAccountName = subAccount;
              wageController.text = wage.toStringAsFixed(1);
              this.openingBalance = openingBalance;
              updateBalance();
            });
          },
        );
      },
    );
  }

  Widget _buildAmountAndDescriptionFields(
    String amountLabel,
    TextEditingController controller,
    String descriptionLabel,
    TextEditingController descriptionController,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildAmountField(amountLabel, controller),
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
    return TextFormField(
      controller: controller,
      maxLength: 8,
      readOnly: isCalculatorEnabled,
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        prefixIcon: Icon(Icons.currency_rupee, color: AppColor.kPurple),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: AppColor.kRed),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColor.kWhite
                : AppColor.kGrayscale100,
          ),
        ),
      ),
      onChanged: (_) => updateBalance(),
      onTap: () {
        if (isCalculatorEnabled) {
          setState(() {
            activeController = controller;
            showCalculator = true;
          });
        }
      },
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
      controller: descriptionController,
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
      onTap: () {
        setState(() {
          showCalculator = false;
        });
      },
    );
  }

  Widget _buildPaymentSection(double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
            width: width / 2.25,
            child: _buildAmountField('Payment', amountController)),
      ],
    );
  }

  Widget _buildCategoryAndAccountsButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildAccountButton(selectedFirstAccountName, selectedFirstAccountIcon),
        _buildCategoryButton(),
      ],
    );
  }

  Widget buildAccountButton(String? accountName, String? accountIcon) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => _accountSelection(),
        label: Column(
          children: [
            if (subAccountName != null && subAccountName!.isNotEmpty)
              Text(
                subAccountName!,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              accountName ?? 'Account',
              style: TextStyle(
                fontSize: (subAccountName != null && subAccountName!.isNotEmpty)
                    ? 14
                    : null,
                color: (subAccountName != null && subAccountName!.isNotEmpty)
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
        onPressed: () => _categorySelection(
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
            : Image.asset(toggleIndex == 0 ? receiptPath : paymentPath,
                width: 24),
      ),
    );
  }

// In the EditScreenState class

  Future<void> _categorySelection(List<Map<String, dynamic>> categories) async {
    var result = await showModalBottomSheet<Map<String, dynamic>?>(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return CategorySelection(
              categories: categories,
              transactionType:
                  isPayment ? TransactionType.payment : TransactionType.receipt,
              onCategoryCreated: (String newCategoryName, String selectedIcon) {
                addCategory(newCategoryName, selectedIcon);
              },
              onCategorySelected:
                  (String categoryName, String? newSubCategory, String? icon,
                      {String? generalCategory, String? generalSubCategory}) {
                setSelectedCategory(
                    categoryName, icon, newSubCategory, generalCategory);
              },
              selectedDailyDate: widget.selectedDailyDate,
              transactionBox: widget.transactionBox,
            );
          },
        );
      },
    );

    if (result != null) {
      setSelectedCategory(
        result['name'] as String?,
        result['imagePath'] as String?,
        result['subCategory'] as String?,
        result['generalCategory'] as String?,
      );
    }
  }

  void setSelectedCategory(String? categoryName, String? icon,
      String? subCategory, String? generalCategory) {
    setState(() {
      selectedcategoryName = categoryName ?? '';
      selectedCategoryIcon = icon;
      selectedSubCategory = subCategory;
      toggleIndex = isPayment ? 1 : 0;
      selectedGeneralCategory = generalCategory ?? '';
      isGeneralCategory = (generalCategory ?? '').isNotEmpty;
    });
  }

  void addCategory(String name, String icon) {
    setState(() {
      CategoryHelper().addCategory(name, icon, transactionType);
      selectedcategoryName = name;
    });
  }

  Future<void> _accountSelection() async {
    AccountHelper accountModel = AccountHelper();
    var result = await showModalBottomSheet(
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
              selectedDate: widget.selectedDailyDate,
              onCategorySelected: (String selectedAccount, String? subAccount,
                  String imagePath) {
                setState(() {
                  selectedFirstAccountName = selectedAccount;
                  selectedFirstAccountIcon = imagePath;
                  subAccountName = subAccount ?? '';
                });
              },
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedFirstAccountName = result['name'];
        selectedFirstAccountIcon = result['imagePath'];
        subAccountName = result['subAccount'];
      });
    }
  }

  Widget _buildTotal() {
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

  Widget _buildPayment() {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    var payment = double.tryParse(amountController.text) ?? 0;
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        'Payment : $currencySymbol$payment',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBalance(double balance) {
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

  // Widget _buildCalculator() {
  //   return Calculator(
  //     onValueChanged: (value) {
  //       setState(() {
  //         activeController.text = value;
  //         updateBalance();
  //       });
  //     },
  //   );
  // }

  Widget _buildSaveButton() {
    return CustomOutlineButton(
      height: 40,
      width: 130,
      borderRadius: 20,
      onTap: _saveAttendance,
      text: 'Save Changes',
    );
  }

  void _saveAttendance() {
    if (_key.currentState!.validate() &&
        selectedName != 'Select Category' &&
        toggleIndex != -1) {
      // Determine which category name to use based on whether it's a general category
      final categoryNameToUse =
          isGeneralCategory ? '' : selectedcategoryName ?? '';
      final generalCategoryToUse =
          isGeneralCategory ? selectedGeneralCategory : '';

      // Update the existing AttendanceModel instead of creating a new one
      widget.attendance.date = selectedDate;
      widget.attendance.name = selectedName;
      widget.attendance.isPresent = toggleIndex == 0 ? true : false;
      widget.attendance.wage = double.parse(wageController.text);
      widget.attendance.siteName = siteController.text;
      widget.attendance.extraCharges =
          double.parse(extraChargesController.text);
      widget.attendance.description = descriptionController.text;
      widget.attendance.payment = double.parse(amountController.text);
      widget.attendance.balance = balance;
      widget.attendance.account = selectAccount;
      widget.attendance.openingBalance = openingBalance;
      widget.attendance.subName =
          subAccountName ?? ''; // Null check and default to empty string
      widget.attendance.accountPath =
          selectedFirstAccountIcon ?? defaultWalletPath; // Provide a default
      widget.attendance.categoryPath = selectedCategoryIcon ??
          (toggleIndex == 0 ? receiptPath : paymentPath); // Provide a default
      widget.attendance.categoryName = categoryNameToUse;
      widget.attendance.generalCategoryName = generalCategoryToUse ?? '';
      widget.attendance.generalSubCategory = selectedGeneralSubCategory ?? '';
      widget.attendance.subCategory = selectedSubCategory ?? '';
      widget.attendance.subAccount = selectedSubAccountName ?? '';

      // Save the updated attendance
      widget.onSave(widget.attendance);
      ToastService.show(
        context,
        message: 'Attendance updated successfully',
        type: ToastType.success,
      );

      Navigator.of(context).pop();
    } else if (selectedcategoryName == 'Select Category') {
      ToastService.show(
        context,
        message: 'Please select a category',
        type: ToastType.warning,
      );
    } else if (toggleIndex == -1) {
      ToastService.show(
        context,
        message: 'Please select attendance status',
        type: ToastType.warning,
      );
    }
  }
}
