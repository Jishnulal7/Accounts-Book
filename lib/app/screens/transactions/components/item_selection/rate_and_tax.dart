import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/transactions/export.dart';

class RateAndTaxFields extends StatelessWidget {
  const RateAndTaxFields({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemSelectionProvider>(context);
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a rate';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: provider.selectedTaxRate,
            onChanged: (newValue) {
              provider.setTaxRate(newValue!);
            },
            items: ListData().taxRates.map((String rate) {
              return DropdownMenuItem<String>(
                value: rate,
                child: Text(rate),
              );
            }).toList(),
            decoration: const InputDecoration(
              labelText: 'Tax Rate',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a tax rate';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
