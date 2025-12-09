import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/enums/toast.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/data/model/transfer_model.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_helper.dart';
import 'package:account_book/app/screens/yarima_wallet/category/components/category_helper.dart';
import 'package:account_book/app/screens/yarima_wallet/transaction/account_selection.dart';
import 'package:account_book/app/screens/yarima_wallet/transaction/category_selection.dart';
import 'package:account_book/app/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:toggle_switch/toggle_switch.dart';

class EditScreen extends StatefulWidget {
  final TransactionModel? transaction;
  final DateTime selectedDailyDate;
  final Box<TransactionModel> transactionBox;
  const EditScreen({
    super.key,
    required this.transaction,
    required this.selectedDailyDate,
    required this.transactionBox,
  });

  @override
  EditScreenState createState() => EditScreenState();
}

class EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  bool isPayment = true;
  bool isTransfer = false;
  bool isGeneralCategory = false;

  String selectedCategory = '';
  String? selectedcategoryName;
  String? selectedCategoryIcon;
  String? selectedFirstAccountName;
  String? selectedFirstAccountIcon;
  String? selectedSecondAccountName;
  String? selectedSecondAccountIcon;
  String? selectedSubCategory;
  String? selectedGeneralCategory;
  String? selectedGeneralCategoryImagePath;
  String? firstSubAccountName;
  String? secondSubAccountName;
  String paymentPath = 'assets/categories/payment.png';
  String receiptPath = 'assets/categories/receipt.png';
  String defaultWalletPath = 'assets/categories/wallet.png';

  TransactionType transactionType = TransactionType.payment;
  late DateTime selectedDate;
  int toggleIndex = 0;

  @override
  void initState() {
    super.initState();
    initializeControllers();
    initializeSelections();
    selectedDate = widget.transaction?.date ?? widget.selectedDailyDate;
  }

  void initializeControllers() {
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.transaction?.description ?? '',
    );
  }

  void initializeSelections() {
    if (widget.transaction != null) {
      selectedCategory = widget.transaction!.categoryName ?? '';
      selectedcategoryName = widget.transaction!.categoryName;
      selectedSubCategory = widget.transaction!.subCategory;
      selectedFirstAccountName = widget.transaction!.fromAccount;
      selectedSecondAccountName = widget.transaction!.toAccount;
      transactionType = widget.transaction!.transactionType;
      selectedGeneralCategory = widget.transaction!.generalCategory;
      selectedGeneralCategoryImagePath =
          widget.transaction!.generalSubCategory ?? '';
      firstSubAccountName = widget.transaction!.fromSubAccount ?? '';
      secondSubAccountName = widget.transaction!.toSubAccount ?? '';
      // Update toggle index based on transaction type
      isGeneralCategory = selectedGeneralCategory != null &&
          selectedGeneralCategory!.isNotEmpty;
      if (transactionType == TransactionType.transfer) {
        toggleIndex = 2;
        isTransfer = true;
        isPayment = false;
      } else if (transactionType == TransactionType.payment) {
        toggleIndex = 1;
        isPayment = true;
        isTransfer = false;
      } else {
        toggleIndex = 0;
        isPayment = false;
        isTransfer = false;
      }

      initializeIcons();
    }
  }

  void initializeIcons() {
    selectedCategoryIcon = widget.transaction?.iconData;
    selectedFirstAccountIcon = widget.transaction?.fromAccountImagePath;
    selectedSecondAccountIcon = widget.transaction?.toAccountImagePath;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData currentTheme = Theme.of(context);
    Color textColor = currentTheme.brightness == Brightness.dark
        ? AppColor.kPurple
        : AppColor.kPurple;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 16,
            children: [
              _buildDateAndAttendance(context),
              buildToggleSwitch(textColor),
              isTransfer ? buildTransferRow() : buildPaymentReceiptRow(),
              buildAmountDescriptionRow(),
              buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
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
    }
  }

  Widget buildToggleSwitch(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ToggleSwitch(
        activeBgColor: [textColor],
        minWidth: 100,
        initialLabelIndex: toggleIndex,
        totalSwitches: 3,
        labels: const ['Receipt', 'Payment', 'Transfer'],
        activeBgColors: [
          [AppColor.kGreen],
          [AppColor.kRed],
          [AppColor.kPrimary],
        ],
        onToggle: (index) {
          setState(() {
            toggleIndex = index!;
            isPayment = index == 1;
            isTransfer = index == 2;
            resetAccountSelections();

            // Update transactionType based on the toggle
            if (index == 2) {
              transactionType = TransactionType.transfer;
            } else if (index == 1) {
              transactionType = TransactionType.payment;
            } else {
              transactionType = TransactionType.receipt;
            }
          });
        },
      ),
    );
  }

  void resetAccountSelections() {
    selectedFirstAccountName = null;
    selectedFirstAccountIcon = null;
    selectedSecondAccountName = null;
    selectedSecondAccountIcon = null;
  }

  Widget _buildDateAndAttendance(BuildContext context) {
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

  Widget buildTransferRow() {
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

  Widget buildPaymentReceiptRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAccountButton(1, selectedFirstAccountName,
            selectedFirstAccountIcon, firstSubAccountName),
        const SizedBox(width: 16),
        buildCategoryButton(),
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

  Widget buildCategoryButton() {
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

  Widget buildAmountDescriptionRow() {
    return Row(
      children: [
        Expanded(
          child: buildAmountField(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: buildDescriptionField(),
        ),
      ],
    );
  }

  Widget buildAmountField() {
    ThemeData currentTheme = Theme.of(context);

    Color color = currentTheme.brightness == Brightness.dark
        ? AppColor.kWhite
        : AppColor.kGrayscale100;
    return TextFormField(
      maxLength: 8,
      validator: (value) =>
          value == null || value.isEmpty ? 'Please enter the amount' : null,
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        counterText: '',
        border: const OutlineInputBorder(),
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
        labelText: 'Amount',
        prefixIcon: Icon(Icons.currency_rupee, color: AppColor.kPurple),
      ),
    );
  }

  Widget buildDescriptionField() {
    ThemeData currentTheme = Theme.of(context);

    Color color = currentTheme.brightness == Brightness.dark
        ? AppColor.kWhite
        : AppColor.kGrayscale100;
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        border: const OutlineInputBorder(),
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
        prefixIcon: Icon(Icons.edit_note, color: AppColor.kPurple),
      ),
    );
  }

  Widget buildSaveButton() {
    return OutlinedButton(
      onPressed: onEdit,
      child: const Text('Save'),
    );
  }

  void onEdit() {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedTransaction = createUpdatedTransaction();

        var transactionsBox = Hive.box<TransactionModel>('transactions');
        transactionsBox.put(widget.transaction!.key, updatedTransaction);
        Navigator.of(context).pop(updatedTransaction);
      } catch (e) {
        debugPrint('An error occurred: $e');
      }
    } else {
      displayErrorMessage();
    }
  }

  TransactionModel createUpdatedTransaction() {
    final double updatedAmount = double.tryParse(_amountController.text) ?? 0.0;
    final TransactionType updatedType = getUpdatedTransactionType();

    if (updatedType == TransactionType.transfer) {
      return Transfer(
        amount: updatedAmount,
        description: _descriptionController.text,
        transactionType: updatedType,
        date: selectedDate,
        categoryName: '',
        id: widget.transaction!.id,
        iconData: '',
        fromAccount: selectedFirstAccountName.toString(),
        toAccount: selectedSecondAccountName.toString(),
        fromAccountImagePath: selectedFirstAccountIcon.toString(),
        toAccountImagePath: selectedSecondAccountIcon.toString(),
        fromSubAccount: firstSubAccountName.toString(),
        toSubAccount: secondSubAccountName.toString(),
      );
    } else {
      // Determine which category name to use based on whether it's a general category
      final categoryNameToUse = isGeneralCategory
          ? selectedGeneralCategory
          : selectedcategoryName ?? '';
      final subCategoryNameToUse = isGeneralCategory
          ? selectedGeneralCategoryImagePath
          : selectedSubCategory ?? '';

      return TransactionModel(
        toSubAccount: '',
        amount: updatedAmount,
        description: _descriptionController.text,
        transactionType: updatedType,
        date: selectedDate,
        categoryName: categoryNameToUse,
        id: widget.transaction!.id,
        iconData: selectedCategoryIcon.toString(),
        fromAccount: selectedFirstAccountName.toString(),
        toAccount: '',
        fromAccountImagePath: selectedFirstAccountIcon.toString(),
        toAccountImagePath: '',
        subCategory: subCategoryNameToUse,
        generalCategory: '',
        generalSubCategory: '',
        fromSubAccount: firstSubAccountName ?? '',
      );
    }
  }

  TransactionType getUpdatedTransactionType() {
    return isTransfer
        ? TransactionType.transfer
        : (isPayment ? TransactionType.payment : TransactionType.receipt);
  }

  void displayErrorMessage() {
    String errorMessage = '';

    if (toggleIndex == 0 || toggleIndex == 1) {
      errorMessage = getPaymentReceiptErrorMessage();
    } else if (toggleIndex == 2) {
      errorMessage = getTransferErrorMessage();
    }
    ToastService.show(
      context,
      message: errorMessage,
      type: ToastType.error,
    );
  }

  String getPaymentReceiptErrorMessage() {
    if (selectedFirstAccountName == null) {
      return 'Select the account';
    } else if (selectedcategoryName == null) {
      return 'Select the category';
    } else if (_amountController.text.isEmpty) {
      return 'Please enter amount';
    } else {
      return 'Please enter description';
    }
  }

  String getTransferErrorMessage() {
    if (selectedFirstAccountName == null || selectedSecondAccountName == null) {
      return 'Select both accounts';
    } else if (selectedFirstAccountName == selectedSecondAccountName) {
      return 'Select different accounts';
    } else if (_amountController.text.isEmpty) {
      return 'Please enter amount';
    } else {
      return '';
    }
  }

  Future<void> _accountSelection(int accountIndex) async {
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
              onCategorySelected: (String selectedFirstAccount,
                  String? subAccountName, String imagePath) {
                setState(() {
                  if (accountIndex == 1) {
                    selectedFirstAccountName = selectedFirstAccount;
                    selectedFirstAccountIcon = imagePath;
                    firstSubAccountName = subAccountName;
                  } else {
                    selectedSecondAccountName = selectedFirstAccount;
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
      selectedCategory = categoryName ?? '';
      selectedSubCategory = subCategory;
      toggleIndex = isPayment ? 1 : 0;
      selectedGeneralCategory = generalCategory ?? '';
      isGeneralCategory = (generalCategory ?? '').isNotEmpty;
    });
  }

  void addCategory(String name, String icon) {
    setState(() {
      CategoryHelper().addCategory(name, icon, transactionType);
      selectedCategory = name;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
