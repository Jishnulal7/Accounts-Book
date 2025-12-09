import 'package:account_book/app/screens/items/exports.dart';

class EditItem extends StatefulWidget {
  const EditItem({
    super.key,
    required this.itemId,
  });

  final String itemId;

  @override
  State<EditItem> createState() => _EditItemState();
}

class _EditItemState extends State<EditItem> {
  final formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> controllers = {
    'name': TextEditingController(),
    'stock': TextEditingController(),
    'date': TextEditingController(),
    'amount': TextEditingController(),
    'hsn': TextEditingController(),
    'category': TextEditingController(),
    'description': TextEditingController(),
    'lowStock': TextEditingController(),
    'newUnit': TextEditingController(),
    'shortUnit': TextEditingController(),
    'subCategory': TextEditingController(),
  };

  late List<String> _unitList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().fetchItemDetails(widget.itemId);
    });
    _loadUnits();
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddUnitDialog(
          newUnitController: controllers['newUnit']!,
          shortUnitController: controllers['shortUnit']!,
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

  void _updateControllers(ItemProvider provider) {
    controllers['name']!.text = provider.item.itemName ?? '';
    controllers['subCategory']!.text = provider.item.subCategory ?? '';
    controllers['stock']!.text = provider.item.stockQuantity?.toString() ?? '0';
    controllers['date']!.text = provider.getFormattedDate();
    controllers['amount']!.text = provider.item.amount?.toString() ?? '0';
    controllers['hsn']!.text = provider.item.hsn ?? '';
    controllers['category']!.text = provider.item.itemCategory ?? '';
    controllers['description']!.text = provider.item.itemDescription ?? '';
    controllers['lowStock']!.text =
        provider.item.lowStockQuantity?.toString() ?? '0';
  }

  Future<void> selectMonthYear(BuildContext context) async {
    final provider = context.read<ItemProvider>();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: provider.selectMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.kPrimary,
            ),
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

  void editItem() {
    if (!formKey.currentState!.validate()) return;

    final provider = context.read<ItemProvider>();
    provider.updateItem({
      'itemName': controllers['name']!.text,
      'stockQuantity': controllers['stock']!.text,
      'amount': controllers['amount']!.text,
      'hsn': controllers['hsn']!.text,
      'itemCategory': controllers['category']!.text,
      'itemDescription': controllers['description']!.text,
      'lowStockQuantity': controllers['lowStock']!.text,
      'subCategory': controllers['subCategory']!.text,
    });

    Navigator.pop(context, true);
    _showSnackBar('Item updated successfully');
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
    return Consumer<ItemProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        _updateControllers(provider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Item'),
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
                  // Item Type Section with Radio buttons
                  _buildItemTypeSection(provider),
                  const SizedBox(height: 20),

                  _buildSection(
                    title: 'Basic Information',
                    children: [
                      buildTextField('Item Name', controllers['name']!),
                      buildTextField(
                          'Item Sub Category', controllers['subCategory']!),
                      buildUnitDropdown(context, provider),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (!provider.isService) ...[
                    _buildSection(
                      title: 'Stock Details',
                      children: [
                        buildStockAndDateRow(context, provider),
                        const SizedBox(height: 10),
                        buildLowStockAlert(context, provider),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  _buildSection(
                    title: 'Pricing & Tax',
                    children: [
                      buildTextField('Amount', controllers['amount']!,
                          keyboardType: TextInputType.number),
                      buildHsnAndTaxRow(context, provider),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildSection(
                    title: 'Additional Details',
                    children: [
                      buildTextField('Item Category', controllers['category']!),
                      buildTextField(
                          'Item Description', controllers['description']!,
                          maxLines: 3),
                    ],
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: buildSaveButton(context),
        );
      },
    );
  }

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
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColor.kPrimary,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Service'),
                    value: false,
                    groupValue: provider.isCustomerSelected,
                    onChanged: (value) => provider.setIsCustomerSelected(false),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColor.kPrimary,
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

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int? maxLines,
    Function()? onTap,
    Widget? suffixIcon,
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
          hintText: 'Enter $label',
          maxLines: maxLines,
          onTap: onTap,
          suffixIcon: suffixIcon,
          readOnly: readOnly,
          // keyboardType: keyboardType,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget buildUnitDropdown(BuildContext context, ItemProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unit',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: provider.selectedUnit,
          onChanged: (String? newValue) {
            if (newValue == 'Add Unit') {
              _showAddUnitBottomSheet(context);
            } else {
              provider.setSelectedUnit(newValue!);
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
                ));
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
      ],
    );
  }

  Widget buildStockAndDateRow(BuildContext context, ItemProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: buildTextField(
            'Opening Stock',
            controllers['stock']!,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: buildTextField(
            'Date',
            controllers['date']!,
            keyboardType: TextInputType.number,
            onTap: () => selectMonthYear(context),
            suffixIcon: const Icon(Icons.calendar_month_outlined),
            readOnly: true,
          ),
        ),
      ],
    );
  }

  Widget buildHsnAndTaxRow(BuildContext context, ItemProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HSN / SAC',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 5),
              CustomTextField(
                controller: controllers['hsn']!,
                hintText: 'Enter HSN / SAC',
                keyboardType: TextInputType.number,
                suffixIcon: const Icon(Icons.search),
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
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tax Rate',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: provider.selectedTaxRate,
                onChanged: (String? newValue) =>
                    provider.setSelectedTaxRate(newValue!),
                items: ListData().taxRates.map((String rate) {
                  return DropdownMenuItem<String>(
                      value: rate, child: Text(rate));
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

  Widget buildLowStockAlert(BuildContext context, ItemProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications),
                SizedBox(width: 10),
                Text('Low stock alert', style: TextStyle(fontSize: 16)),
              ],
            ),
            CustomSwitch(
              isSwitchOn: provider.lowStockQuantityAlert,
              onToggle: (bool value) =>
                  provider.setLowStockQuantityAlert(value),
            ),
          ],
        ),
        if (provider.lowStockQuantityAlert)
          buildTextField('Low Stock Quantity', controllers['lowStock']!,
              keyboardType: TextInputType.number),
      ],
    );
  }

  Widget buildSaveButton(BuildContext context) {
    return BottomAppBar(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: PrimaryButton(
          onTap: editItem,
          text: 'Save',
          textColor: AppColor.kWhite,
          bgColor: AppColor.kPrimary,
          height: 50,
          width: double.infinity,
          borderRadius: 20,
        ),
      ),
    );
  }
}
