import 'package:account_book/app/screens/items/exports.dart';
import 'package:intl/intl.dart';

class AdjustStock extends StatefulWidget {
  final ItemModel item;
  const AdjustStock({super.key, required this.item});

  @override
  State<AdjustStock> createState() => _AdjustStockState();
}

class _AdjustStockState extends State<AdjustStock> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  DateTime selectMonth = DateTime.now();
  final formKey = GlobalKey<FormState>();

  int updatedStock = 0;
  double updatedPrice = 0.0;
  SingingCharacter _selectedOption = SingingCharacter.option1;

  @override
  void initState() {
    super.initState();
    updatedStock = widget.item.stockQuantity ?? 0;
    updatedPrice = widget.item.amount ?? 0.0;
  }

  void _onOptionSelected(SingingCharacter selected) {
    setState(() {
      _selectedOption = selected;
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String updatedTitle,
    required String updatedValue,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 300;
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: isWide ? 12.0 : 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      updatedTitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      updatedValue,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColor.kPrimary,
                          ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions and orientation
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    // Adaptive padding based on screen width
    final horizontalPadding = screenSize.width < 360
        ? 12.0
        : screenSize.width * 0.05; // 5% of screen width for larger screens

    // Calculate form width based on screen size and orientation
    final formMaxWidth = isLandscape
        ? 600.0 // Fixed max width in landscape
        : screenSize.width * 0.9; // 90% of screen width in portrait

    // Info cards layout - side by side on wide screens
    final useRowForInfoCards = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Stock'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: formMaxWidth,
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SampleRadioButton(onOptionSelected: _onOptionSelected),
                  const SizedBox(height: 16),
      
                  CustomTextField(
                    onTap: () => selectMonthYear(context),
                    controller: _dateController,
                    hintText:
                        DateFormat('dd MMM y').format(selectMonth).toString(),
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  const SizedBox(height: 16),
      
                  CustomTextField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Quantity Can't be empty";
                      }
                      return null;
                    },
                    controller: _quantityController,
                    hintText: 'Quantity',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        final adjustment = int.tryParse(value) ?? 0;
                        updatedStock = (_selectedOption ==
                                SingingCharacter.option1)
                            ? (widget.item.stockQuantity ?? 0) + adjustment
                            : (widget.item.stockQuantity ?? 0) - adjustment;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
      
                  CustomTextField(
                    controller: _priceController,
                    hintText: 'Enter Price',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        updatedPrice = double.tryParse(value) ??
                            widget.item.amount ??
                            0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
      
                  // Info cards section - responsive layout
                  if (useRowForInfoCards)
                    // Side by side layout for wide screens
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            title: 'Current Stock',
                            value: '${widget.item.stockQuantity}',
                            updatedTitle: 'Updated Stock',
                            updatedValue: '$updatedStock',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            title: 'Current Price',
                            value: '${widget.item.amount}',
                            updatedTitle: 'Updated Price',
                            updatedValue: '$updatedPrice',
                          ),
                        ),
                      ],
                    )
                  else
                    // Stacked layout for narrow screens
                    Column(
                      children: [
                        _buildInfoCard(
                          title: 'Current Stock',
                          value: '${widget.item.stockQuantity}',
                          updatedTitle: 'Updated Stock',
                          updatedValue: '$updatedStock',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          title: 'Current Price',
                          value: '${widget.item.amount}',
                          updatedTitle: 'Updated Price',
                          updatedValue: '$updatedPrice',
                        ),
                      ],
                    ),
      
                  // Add details text field for additional information
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _detailsController,
                    hintText: 'Additional Notes (Optional)',
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8,
          left: horizontalPadding,
          right: horizontalPadding,
          top: 8,
        ),
        child: PrimaryButton(
          onTap: () => saveAdjustment(context),
          text: 'Save',
          textColor: AppColor.kWhite,
          bgColor: AppColor.kPrimary,
          borderRadius: 20,
        ),
      ),
    );
  }

  Future<void> selectMonthYear(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        selectMonth = pickedDate;
        _dateController.text = DateFormat('dd MMM y').format(selectMonth);
      });
    }
  }

  void saveAdjustment(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      try {
        final itemProvider = Provider.of<ItemProvider>(context, listen: false);
        final adjustedQuantity = int.tryParse(_quantityController.text) ?? 0;
        final adjustedPrice =
            double.tryParse(_priceController.text) ?? widget.item.amount ?? 0.0;

        final adjustment = StockAdjustmentModel(
          id: 'ADJ-${DateTime.now().millisecondsSinceEpoch}',
          itemId: widget.item.id!,
          date: selectMonth,
          quantity: adjustedQuantity.toDouble(),
          rate: adjustedPrice,
          amount: adjustedQuantity * adjustedPrice,
          reason: _detailsController.text,
          type: _selectedOption == SingingCharacter.option1
              ? AdjustmentType.addition
              : AdjustmentType.reduction,
        );

        final newStock = _selectedOption == SingingCharacter.option1
            ? widget.item.stockQuantity! + adjustedQuantity
            : widget.item.stockQuantity! - adjustedQuantity;

        if (newStock < 0) {
          throw Exception('Insufficient stock for reduction');
        }

        final updatedItem = widget.item.copyWith(
          stockQuantity: newStock,
          amount: adjustedPrice,
          date: widget.item.date,
        );

        await itemProvider.adjustStock(updatedItem, adjustment);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stock adjusted successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }
}
