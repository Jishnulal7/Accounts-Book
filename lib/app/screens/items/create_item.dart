import 'package:account_book/app/data/helpers/enums/toast.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/items/exports.dart';
import 'package:intl/intl.dart';

class CreateItem extends StatefulWidget {
  final TextEditingController? nameController;
  final VoidCallback? onItemCreated;

  const CreateItem({super.key, this.nameController, this.onItemCreated});

  @override
  State<CreateItem> createState() => _CreateItemState();
}

class _CreateItemState extends State<CreateItem> {
  final Map<String, TextEditingController> controllers = {
    'name': TextEditingController(),
    'stock': TextEditingController(),
    'date': TextEditingController(),
    'amount': TextEditingController(),
    'hsn': TextEditingController(),
    'category': TextEditingController(),
    'subCategory': TextEditingController(),
    'description': TextEditingController(),
    'lowStock': TextEditingController(),
  };
  late List<String> _unitList = [];
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeData();
    if (widget.nameController != null) {
      controllers['name'] = widget.nameController!;
    }
  }

  Future<void> _initializeData() async {
    await _loadUnits();
    controllers['date']?.text =
        DateFormat('dd MMM y').format(DateTime.now()).toString();
  }

  Future<void> _loadUnits() async {
    final prefs = await SharedPreferences.getInstance();
    final customUnits = prefs.getStringList('custom_units') ?? [];
    setState(() {
      _unitList = List.from(ListData().unitData)..addAll(customUnits);
    });
  }

  Future<void> _saveUnits() async {
    final prefs = await SharedPreferences.getInstance();
    final customUnits =
        _unitList.where((unit) => !ListData().unitData.contains(unit)).toList();
    await prefs.setStringList('custom_units', customUnits);
  }

  void _showAddUnitBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddUnitDialog(
          newUnitController: TextEditingController(),
          shortUnitController: TextEditingController(),
          onSave: () => _handleNewUnit(
            context,
            controllers['newUnit']!.text,
            controllers['shortUnit']!.text,
          ),
        ),
      ),
    );
  }

  void _handleNewUnit(BuildContext context, String newUnit, String shortForm) {
    if (newUnit.isEmpty || shortForm.isEmpty) return;

    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final newUnitEntry = '$newUnit ($shortForm)';

    if (_unitList.contains(newUnitEntry)) {
      _showSnackBar('Unit "$newUnitEntry" already exists!');
      return;
    }

    setState(() {
      _unitList.insert(2, newUnitEntry);
    });

    ListData().unitDataMap[newUnit] = shortForm;
    itemProvider.setSelectedUnit(newUnitEntry);
    _saveUnits();
    Navigator.pop(context);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _selectMonthYear(
      BuildContext context, ItemProvider provider) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: provider.selectMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColor.kPrimary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      provider.setSelectMonth(pickedDate);
      controllers['date']!.text = provider.getFormattedDate();
    }
  }

  Future<void> _saveItem(BuildContext context, ItemProvider provider) async {
    if (!formKey.currentState!.validate()) {
      _showError(context, 'Amount is required');
      return;
    }

    try {
      // Convert empty stock value to zero
      final stockQuantity =
          controllers['stock']!.text.isEmpty ? '0' : controllers['stock']!.text;

      // Ensure amount is not empty and is a valid number
      final amount = controllers['amount']!.text;
      if (amount.isEmpty) {
        _showError(context, 'Amount is required');
        return;
      }
      if (double.tryParse(amount) == null) {
        _showError(context, 'Enter a valid amount');
        return;
      }

      final newItemValues = {
        'itemName': controllers['name']!.text,
        'amount': amount, // Use the validated amount
        'hsn': controllers['hsn']!.text,
        'itemCategory': controllers['category']!.text,
        'itemDescription': controllers['description']!.text,
        'stockQuantity': stockQuantity, // Use the converted stock value
        'lowStockQuantity': controllers['lowStock']!.text,
        'unit': provider.selectedUnit,
        'gst': provider.selectedTaxRate,
        'itemType': provider.isCustomerSelected ? 'Goods' : 'Service',
        'date': provider.selectMonth,
        'subCategory': controllers['subCategory']!.text,
        'lowStockQuantityAlert': provider.lowStockQuantityAlert,
      };

      await provider.createNewItem(newItemValues);
      widget.onItemCreated?.call();
      if (!context.mounted) return;
      Navigator.pop(context);
      _showSuccess(context, 'Item created successfully');
    } catch (e) {
      _showError(context, 'Error creating item: ${e.toString()}');
      debugPrint(e.toString());
    }
  }

  void _showError(BuildContext context, String message) {
    ToastService.show(
      context,
      message: message,
      type: ToastType.success,
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Consumer<ItemProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Create New Item'),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Item Type section moved above Basic Information
                  _buildItemTypeSection(provider),
                  const SizedBox(height: 20),

                  _buildSection(
                    title: 'Basic Information',
                    children: [
                      _buildTextField(
                        'Item Name',
                        controllers['name']!,
                        hintText: 'Bottle',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return "Item Name Can't be empty";
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        'Sub-Category',
                        controllers['subCategory']!,
                      ),
                      _buildUnitField(context, provider),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (!provider.isService) ...[
                    _buildSection(
                      title: 'Stock Details',
                      children: [
                        _buildStockAndDateRow(context, provider, isMobile),
                        const SizedBox(height: 10),
                        _buildLowStockAlert(context, provider),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  _buildSection(
                    title: 'Pricing & Tax',
                    children: [
                      _buildTextField(
                        'Amount',
                        controllers['amount']!,
                        hintText: '$currencySymbol  1000',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return "Amount is required";
                          }
                          if (double.tryParse(value!) == null) {
                            return "Enter a valid number";
                          }
                          if (double.parse(value) <= 0) {
                            return "Amount must be greater than zero";
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                      ),
                      _buildHsnAndTaxRow(context, provider, isMobile),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildSection(
                    title: 'Additional Details',
                    children: [
                      _buildTextField(
                        'Category',
                        controllers['category']!,
                        hintText: 'Local Sale',
                      ),
                      _buildTextField(
                        'Description',
                        controllers['description']!,
                        hintText: '50 Plastic Bottles',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildSaveButton(context, provider),
        );
      },
    );
  }

  // New widget for Item Type section
  Widget _buildItemTypeSection(ItemProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Item Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Goods'),
                    value: true,
                    groupValue: provider.isCustomerSelected,
                    onChanged: (value) => provider.setIsCustomerSelected(true),
                    activeColor: AppColor.kPrimary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Service'),
                    value: false,
                    groupValue: provider.isCustomerSelected,
                    onChanged: (value) => provider.setIsCustomerSelected(false),
                    activeColor: AppColor.kPrimary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Separated unit field for better organization
  Widget _buildUnitField(BuildContext context, ItemProvider provider) {
    final width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: provider.selectedUnit,
          style: TextStyle(
            fontSize: ListData().fontSizeForDropDown(width),
            color: Colors.black,
          ),
          onChanged: (String? newValue) {
            if (newValue == 'Add Unit') {
              _showAddUnitBottomSheet(context);
            } else if (newValue != null) {
              provider.setSelectedUnit(newValue);
            }
          },
          items: _unitList.map((String unit) {
            return DropdownMenuItem<String>(
              value: unit,
              child: Text(
                unit,
                style: TextStyle(
                  color: ListData().darkorWhite(context),
                ),
              ),
            );
          }).toList(),
          decoration: const InputDecoration(
            hintText: 'Select Unit',
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hintText,
    TextInputType? keyboardType,
    int? maxLines,
    FormFieldValidator<String>? validator,
    Widget? suffixIcon,
    Function()? onTap,
    bool? readOnly,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 5),
        CustomTextField(
          controller: controller,
          hintText: hintText ?? 'Enter $label',
          maxLines: maxLines,
          validator: validator,
          onTap: onTap,
          suffixIcon: suffixIcon,
          readOnly: readOnly,
          // keyboardType: keyboardType!,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildStockAndDateRow(
      BuildContext context, ItemProvider provider, bool isMobile) {
    return isMobile
        ? Column(
            children: [
              _buildTextField(
                'Opening Stock',
                controllers['stock']!,
                hintText: '10',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isNotEmpty == true) {
                    // Only validate if not empty
                    if (int.tryParse(value!) == null) {
                      return "Enter a valid number";
                    }
                  }
                  return null; // Allow empty field
                },
              ),
              _buildTextField(
                'Date',
                controllers['date']!,
                hintText: DateFormat('dd MMM y').format(DateTime.now()),
                readOnly: true,
                suffixIcon: const Icon(Icons.calendar_month_outlined),
                onTap: () => _selectMonthYear(context, provider),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  'Opening Stock',
                  controllers['stock']!,
                  hintText: '10',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isNotEmpty == true) {
                      // Only validate if not empty
                      if (int.tryParse(value!) == null) {
                        return "Enter a valid number";
                      }
                    }
                    return null; // Allow empty field
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'Date',
                  controllers['date']!,
                  hintText: DateFormat('dd MMM y').format(DateTime.now()),
                  readOnly: true,
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                  onTap: () => _selectMonthYear(context, provider),
                ),
              ),
            ],
          );
  }

  Widget _buildLowStockAlert(BuildContext context, ItemProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_outlined),
                SizedBox(width: 10),
                Text(
                  'Low Stock Alert',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            CustomSwitch(
              isSwitchOn: provider.lowStockQuantityAlert,
              onToggle: (value) => provider.setLowStockQuantityAlert(value),
            ),
          ],
        ),
        if (provider.lowStockQuantityAlert) ...[
          const SizedBox(height: 16),
          _buildTextField(
            'Low Stock Quantity',
            controllers['lowStock']!,
            hintText: '2',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (provider.lowStockQuantityAlert && (value?.isEmpty ?? true)) {
                return "Low stock quantity required";
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildHsnAndTaxRow(
      BuildContext context, ItemProvider provider, bool isMobile) {
    return isMobile
        ? Column(
            children: [
              _buildTextField(
                'HSN / SAC',
                controllers['hsn']!,
                hintText: '9207',
                readOnly: true,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return HsnSearchScreen(
                        onSelectHsn: (selectedHsn) {
                          controllers['hsn']!.text = selectedHsn;
                        },
                      );
                    },
                  );
                },
                keyboardType: TextInputType.number,
                suffixIcon: const Icon(Icons.search),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tax Rate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    value: provider.selectedTaxRate,
                    style: TextStyle(
                      fontSize: ListData().fontSizeForDropDown(
                          MediaQuery.of(context).size.width),
                      color: Colors.black,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        provider.setSelectedTaxRate(newValue);
                      }
                    },
                    items: ListData().taxRates.map((String tax) {
                      return DropdownMenuItem<String>(
                        value: tax,
                        child: Text(
                          tax,
                          style: TextStyle(
                            color: ListData().darkorWhite(context),
                          ),
                        ),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      hintText: 'Select Tax Rate',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  'HSN / SAC',
                  controllers['hsn']!,
                  hintText: '9207',
                  readOnly: true,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) {
                        return HsnSearchScreen(
                          onSelectHsn: (selectedHsn) {
                            controllers['hsn']!.text = selectedHsn;
                          },
                        );
                      },
                    );
                  },
                  keyboardType: TextInputType.number,
                  suffixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tax Rate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      value: provider.selectedTaxRate,
                      style: TextStyle(
                        fontSize: ListData().fontSizeForDropDown(
                            MediaQuery.of(context).size.width),
                        color: Colors.black,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          provider.setSelectedTaxRate(newValue);
                        }
                      },
                      items: ListData().taxRates.map((String tax) {
                        return DropdownMenuItem<String>(
                          value: tax,
                          child: Text(
                            tax,
                            style: TextStyle(
                              color: ListData().darkorWhite(context),
                            ),
                          ),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        hintText: 'Select Tax Rate',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildSaveButton(BuildContext context, ItemProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: PrimaryButton(
        onTap: () => _saveItem(context, provider),
        text: 'Save',
        textColor: AppColor.kWhite,
        bgColor: AppColor.kPrimary,
        borderRadius: 20,
      ),
    );
  }
}
