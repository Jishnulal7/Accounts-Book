import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/components/tabs.dart';
import 'package:account_book/app/widgets/empty_transaction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class TransferSection extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String title;
  final Function(TransactionModel) editTransactions;
  final Function(TransactionModel) deleteTransactions;
  final Function(TransactionModel, DateTime) copyTransaction;
  final DateTime selectDailyDate;

  const TransferSection({
    super.key,
    required this.transactions,
    required this.title,
    required this.editTransactions,
    required this.deleteTransactions,
    required this.copyTransaction,
    required this.selectDailyDate,
  });

  @override
  Widget build(BuildContext context) {
    final transfers = transactions
        .where((t) => t.transactionType == TransactionType.transfer)
        .toList();

    if (transfers.isEmpty) {
      return EmptyTransactionState(
        date: selectDailyDate,
        index: 1,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transfers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildCompactTransferTile(
        context,
        transfers[index],
      ),
    );
  }

  Widget _buildCompactTransferTile(
      BuildContext context, TransactionModel transfer) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;

    return InkWell(
      onLongPress: () => _showOptions(context, transfer),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(transfer.date),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '$currencySymbol${transfer.amount.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColor.kPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _buildCompactAccountInfo(
                    transfer.fromAccount,
                    transfer,
                    isFrom: true,
                    subAccount: transfer.fromSubAccount,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColor.kPrimary,
                  ),
                ),
                Expanded(
                  child: _buildCompactAccountInfo(
                    transfer.toAccount,
                    transfer,
                    isFrom: false,
                    subAccount: transfer.toSubAccount,
                  ),
                ),
              ],
            ),
            if (transfer.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                transfer.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactAccountInfo(
    String accountName,
    TransactionModel transfer, {
    required bool isFrom,
    String? subAccount,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isFrom) const Spacer(),
        TabsHelper().buildIcon(accountName, transfer, isAccount: true),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment:
                isFrom ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(
                accountName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (subAccount != null && subAccount.isNotEmpty)
                Text(
                  subAccount,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                isFrom ? 'From' : 'To',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (isFrom) const Spacer(),
      ],
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  void _showOptions(BuildContext context, TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOption(
                  context,
                  icon: Icons.edit,
                  color: Colors.blue,
                  label: 'Edit',
                  onPressed: () {
                    Navigator.pop(context);
                    editTransactions(transaction);
                  },
                ),
                _buildOption(
                  context,
                  icon: Icons.delete,
                  color: Colors.red,
                  label: 'Delete',
                  onPressed: () {
                    Navigator.pop(context);
                    deleteTransactions(transaction);
                  },
                ),
                _buildOption(
                  context,
                  icon: Icons.copy,
                  color: Colors.green,
                  label: 'Copy',
                  onPressed: () {
                    Navigator.pop(context);
                    copyTransaction(transaction, selectDailyDate);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          color: color,
          onPressed: onPressed,
          tooltip: label,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
