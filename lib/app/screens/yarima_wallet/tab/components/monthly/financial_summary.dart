import 'package:account_book/app/providers/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CompactFinancialSummaryWidget extends StatelessWidget {
  final String totalReceipts;
  final String totalPayments;
  final String balance;
  final String carryForward;

  const CompactFinancialSummaryWidget({
    super.key,
    required this.totalReceipts,
    required this.totalPayments,
    required this.balance,
    required this.carryForward,
  });

  @override
  Widget build(BuildContext context) {
    // Access the current currency symbol using Provider
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          spacing: 4,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow(
                'C/F', carryForward, Colors.purple, currencySymbol),
            _buildSummaryRow(
                'Receipts', totalReceipts, Colors.green, currencySymbol),
            _buildSummaryRow(
                'Payments', totalPayments, Colors.red, currencySymbol),
            _buildSummaryRow('Balance', balance, Colors.blue, currencySymbol),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label, String value, Color color, String currencySymbol) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          '$currencySymbol$value', // Use the dynamic currency symbol
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
