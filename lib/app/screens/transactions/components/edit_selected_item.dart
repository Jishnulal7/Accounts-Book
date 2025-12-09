import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/providers/transaction_provider.dart';
import 'package:account_book/app/screens/transactions/export.dart';

class EditSelectedItemDialog extends StatelessWidget {
  final int index;
  final ItemSelectionModel item;

  const EditSelectedItemDialog({
    super.key,
    required this.index,
    required this.item,
  });

  static Future<ItemSelectionModel?> show(
    BuildContext context, {
    required int index,
    required ItemSelectionModel item,
  }) {
    return showDialog<ItemSelectionModel>(
      context: context,
      builder: (context) => EditSelectedItemDialog(
        index: index,
        item: item,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ItemSelectionProvider(
        partyName: item.partyName,
        selectedItems: [item],
      )..initializeWithItem(item),
      child: _EditSelectedItemDialogContent(
        index: index,
        originalItem: item,
      ),
    );
  }
}

class _EditSelectedItemDialogContent extends StatelessWidget {
  final int index;
  final ItemSelectionModel originalItem;

  const _EditSelectedItemDialogContent({
    required this.index,
    required this.originalItem,
  });

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemSelectionProvider>(context);
    final saleProvider =
        Provider.of<TransactionProvider>(context, listen: false);

    Future<void> handleItemUpdate() async {
      try {
        final updatedItem = itemProvider.createItemSelectionModel();

        // Ensure the updated item maintains the same ID
        updatedItem.id = originalItem.id;

        if (index >= 0 && index < saleProvider.getItemCount()) {
          // Update existing item
          saleProvider.updateSelectedItem(index, updatedItem);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item updated successfully')),
          );
        } else {
          // Handle invalid index
          saleProvider.addSelectedItem(updatedItem);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added as new entry')),
          );
        }

        Navigator.of(context).pop(updatedItem);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: ${e.toString()}')),
        );
      }
    }

    return AlertDialog(
      title: const Text('Edit Item'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Form(
          child: Column(
            children: [
              const ItemNameField(),
              const SizedBox(height: 8),
              if (itemProvider.isListViewVisible)
                Expanded(child: const ItemListView()),
              if (itemProvider.isTextFieldFocused) ...[
                const QuantityAndUnitFields(),
                const SizedBox(height: 8),
                const RateAndTaxFields(),
                const SizedBox(height: 8),
                const DiscountRow(),
                const SizedBox(height: 8),
                if (itemProvider.isItemSelected)
                  const Card(child: TotalsAndTaxesSection()),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: handleItemUpdate,
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class RateAndTaxFields extends StatelessWidget {
  const RateAndTaxFields({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemSelectionProvider>(context);
    final taxRates = ListData().taxRates;
    String currentValue = provider.selectedTaxRate;
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    // Create effective tax rates list including current value if not present
    List<String> effectiveTaxRates = List.from(taxRates);
    if (!effectiveTaxRates.contains(currentValue)) {
      effectiveTaxRates.add(currentValue);
    }

    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            controller: provider.rateController,
            labelText: 'Rate($currencySymbol )',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: currentValue,
            onChanged: (newValue) {
              if (newValue != null) {
                provider.setTaxRate(newValue);
              }
            },
            items: effectiveTaxRates.map((String rate) {
              return DropdownMenuItem<String>(
                value: rate,
                child: Text(rate),
              );
            }).toList(),
            decoration: const InputDecoration(
              labelText: 'Tax Rate',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class DiscountRow extends StatelessWidget {
  const DiscountRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemSelectionProvider>(context);
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: CustomTextField(
            readOnly: true,
            suffixIcon: const Icon(Icons.currency_rupee_rounded),
            controller: provider.discountController,
            labelText: 'Discount($currencySymbol )',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomTextField(
            suffixIcon: const Icon(Icons.percent_outlined),
            controller: provider.percentageController,
            labelText: 'Discount(%)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
            ],
          ),
        ),
      ],
    );
  }
}
