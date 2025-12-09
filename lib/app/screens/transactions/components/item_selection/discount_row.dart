import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/transactions/export.dart';

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
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}'))
            ],
            onChanged: (value) {
              provider.updateSubtotal();
            },
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
            onChanged: (value) {
              provider.updateSubtotal();
            },
          ),
        ),
      ],
    );
  }
}
