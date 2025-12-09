import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/transactions/export.dart';

class ItemCard extends StatelessWidget {
  final List<ItemSelectionModel> itemSelections;

  const ItemCard({
    super.key,
    required this.itemSelections,
  });

  // Helper method to group identical items (unchanged)
  List<ItemSelectionModel> _groupIdenticalItems(
      List<ItemSelectionModel> items) {
    Map<String, ItemSelectionModel> groupedItems = {};

    for (var item in items) {
      String key = item.itemName;

      if (groupedItems.containsKey(key)) {
        var existingItem = groupedItems[key]!;
        groupedItems[key] = ItemSelectionModel(
          id: existingItem.id,
          itemName: existingItem.itemName,
          quantity: existingItem.quantity + item.quantity,
          unit: existingItem.unit,
          rate: existingItem.rate,
          taxType: existingItem.taxType,
          subTotal: existingItem.subTotal + item.subTotal,
          discount: existingItem.discount + item.discount,
          discountPercentage: existingItem.discountPercentage,
          taxAmount: existingItem.taxAmount + item.taxAmount,
          totalAmount: existingItem.totalAmount + item.totalAmount,
          hsnCode: existingItem.hsnCode,
          partyName: existingItem.partyName,
        );
      } else {
        groupedItems[key] = item;
      }
    }

    return groupedItems.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = Provider.of<CurrencyNotifier>(context).currencySymbol;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWindows = Platform.isWindows;
        final isWideScreen = constraints.maxWidth > 600;

        // Use Windows-specific layout for desktop
        if (isWindows && isWideScreen) {
          return _buildWindowsLayout(currencySymbol);
        }

        // Use original mobile layout for Android or narrow windows
        return _buildMobileLayout(currencySymbol);
      },
    );
  }

  Widget _buildWindowsLayout(String currencySymbol) {
    final groupedSelections = _groupIdenticalItems(itemSelections);
    const textStyle = TextStyle(fontSize: 14);

    return ListView.builder(
      shrinkWrap: true,
      itemCount: groupedSelections.length,
      itemBuilder: (context, index) {
        final itemSelection = groupedSelections[index];
        final taxRate = _getTaxRate(itemSelection.taxType);
        final taxType = _getTaxType(itemSelection.taxType);

        return Card(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: index != groupedSelections.length - 1
                      ? Colors.grey.withOpacity(0.2)
                      : Colors.transparent,
                ),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left section - Item details
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemSelection.itemName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'HSN Code: ${itemSelection.hsnCode}',
                          style: textStyle,
                        ),
                      ],
                    ),
                  ),
                  // Middle section - Quantity and rate
                  Expanded(
                    flex: 2,
                    child: _buildQuantityAndRate(
                        itemSelection, textStyle, currencySymbol),
                  ),
                  // Right section - Amounts
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildAmountRow('Subtotal:', itemSelection.subTotal,
                            textStyle, currencySymbol),
                        _buildAmountRow(
                            'Discount (${itemSelection.discountPercentage}%):',
                            itemSelection.discount,
                            textStyle,
                            currencySymbol),
                        _buildAmountRow('Tax ($taxType $taxRate%):',
                            itemSelection.taxAmount, textStyle, currencySymbol),
                        const Divider(),
                        _buildAmountRow(
                            'Total:',
                            itemSelection.totalAmount,
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            currencySymbol),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(String currencySymbol) {
    const textStyle = TextStyle(fontSize: 13);
    final groupedSelections = _groupIdenticalItems(itemSelections);

    return Column(
      children: [
        ...groupedSelections.map((itemSelection) {
          String taxRate = _getTaxRate(itemSelection.taxType);
          String taxType = _getTaxType(itemSelection.taxType);

          return Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      buildItemHeader(itemSelection, textStyle, currencySymbol),
                      const Divider(color: Colors.grey),
                      buildItemSubtotal(
                          itemSelection, textStyle, currencySymbol),
                      const Divider(color: Colors.grey),
                      buildDiscountRow(
                          itemSelection, textStyle, currencySymbol),
                      const Divider(color: Colors.grey),
                      buildTaxRow(itemSelection, taxType, taxRate, textStyle,
                          currencySymbol),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildQuantityAndRate(ItemSelectionModel itemSelection,
      TextStyle textStyle, String currencySymbol) {
    String unit = _formatUnit(itemSelection.unit);

    return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      // crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${itemSelection.quantity.toStringAsFixed(1)} $unit',
              style: textStyle,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('×'),
            ),
            Text(
              '$currencySymbol ${itemSelection.rate.toStringAsFixed(2)}',
              style: textStyle,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountRow(
      String label, double amount, TextStyle style, String currencySymbol) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('$currencySymbol ${amount.toStringAsFixed(2)}', style: style),
      ],
    );
  }

  String _getTaxRate(String taxType) {
    if (taxType == 'Exempted' || taxType == 'None') {
      return '0.0';
    }
    return taxType.replaceAll(RegExp(r'[^\d.]+'), '');
  }

  String _getTaxType(String taxType) {
    if (taxType == 'Exempted' || taxType == 'None') {
      return '';
    }
    return taxType;
  }

  String _formatUnit(String unit) {
    if (unit.contains('(') && unit.contains(')')) {
      return unit.substring(
        unit.indexOf('(') + 1,
        unit.indexOf(')'),
      );
    }
    return unit;
  }

  // Original helper methods remain unchanged
  Row buildItemHeader(ItemSelectionModel itemSelection, TextStyle textStyle,
      String currencySymbol) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Item:  ${itemSelection.itemName}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$currencySymbol  ${itemSelection.totalAmount.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Row buildItemSubtotal(ItemSelectionModel itemSelection, TextStyle textStyle,
      String currencySymbol) {
    String unit = _formatUnit(itemSelection.unit);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Item Subtotal'),
        Row(
          children: [
            Text(itemSelection.quantity.toStringAsFixed(1)),
            const SizedBox(width: 2),
            Text(unit),
            const SizedBox(width: 2),
            const Text('x'),
            const SizedBox(width: 2),
            Text(itemSelection.rate.toStringAsFixed(2)),
            const SizedBox(width: 2),
            const Text('='),
            const SizedBox(width: 2),
            Text(
                '$currencySymbol  ${itemSelection.subTotal.toStringAsFixed(2)}'),
          ],
        ),
      ],
    );
  }

  Row buildDiscountRow(ItemSelectionModel itemSelection, TextStyle textStyle,
      String currencySymbol) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Discount (%) : ${itemSelection.discountPercentage}'),
        Text('$currencySymbol  ${itemSelection.discount.toStringAsFixed(2)}'),
      ],
    );
  }

  Row buildTaxRow(
    ItemSelectionModel itemSelection,
    String taxType,
    String taxRate,
    TextStyle textStyle,
    String currencySymbol,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Tax (%) $taxType : $taxRate"),
        Text('$currencySymbol  ${itemSelection.taxAmount.toStringAsFixed(2)}'),
      ],
    );
  }
}
