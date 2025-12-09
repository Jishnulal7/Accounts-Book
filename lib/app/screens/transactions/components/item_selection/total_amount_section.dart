import 'package:account_book/app/screens/transactions/export.dart';

class TotalsAndTaxesSection extends StatelessWidget {
  const TotalsAndTaxesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemSelectionProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildTotalTile('Subtotal', provider.subtotal.toStringAsFixed(2)),
        const SizedBox(height: 10),
        _buildTotalTile('Tax', provider.taxAmount.toStringAsFixed(2)),
        const SizedBox(height: 10),
        _buildTotalTile('Discount', provider.discount.toStringAsFixed(2)),
        const SizedBox(height: 10),
        _buildTotalTile('Total', provider.total.toStringAsFixed(2)),
      ],
    );
  }

  Widget _buildTotalTile(String title, String value) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
