import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/category_text.dart';
import 'package:account_book/app/data/helpers/color_helper.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/widgets/empty_transaction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class TransactionSection extends StatelessWidget {
  final List<TransactionModel> transactions;
  final Function(TransactionModel) editTransactions;
  final Function(TransactionModel) deleteTransactions;
  final Function(TransactionModel, DateTime) copyTransaction;
  final DateTime selectedDate;

  const TransactionSection({
    super.key,
    required this.transactions,
    required this.editTransactions,
    required this.deleteTransactions,
    required this.copyTransaction,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = transactions.where((transaction) {
      return transaction.date.year == selectedDate.year &&
          transaction.date.month == selectedDate.month &&
          transaction.date.day == selectedDate.day;
    }).toList();

    if (filteredTransactions.isEmpty) {
      return EmptyTransactionState(date: selectedDate, index: 0);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredTransactions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildCompactTransactionTile(
        context,
        filteredTransactions[index],
      ),
    );
  }

  Widget _buildCompactTransactionTile(
      BuildContext context, TransactionModel transaction) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Image.asset(
        transaction.iconData ?? '',
        width: 24,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              getCategoryText(transaction),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${transaction.amount.toStringAsFixed(1)}$currencySymbol',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: ColorHelper().selectColor(transaction),
            ),
          ),
        ],
      ),
      subtitle: Column(
        children: [
          Row(
            children: [
              Image.asset(
                transaction.fromAccountImagePath,
                width: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  getAccountText(transaction),
                  style: TextStyle(
                    color: ColorHelper().darkorWhite(context),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatTime(transaction.date),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              transaction.description,
              style: TextStyle(
                color: ColorHelper().darkorWhite(context),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onLongPress: () => _showOptions(context, transaction),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  void _showOptions(BuildContext context, TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildOptionsMenu(context, transaction),
    );
  }

  Widget _buildOptionsMenu(BuildContext context, TransactionModel transaction) {
    return Padding(
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
                color: AppColor.kPrimary,
                label: 'Edit',
                onPressed: () {
                  Navigator.pop(context);
                  editTransactions(transaction);
                },
              ),
              _buildOption(
                context,
                icon: Icons.delete,
                color: AppColor.kRed,
                label: 'Delete',
                onPressed: () {
                  Navigator.pop(context);
                  deleteTransactions(transaction);
                },
              ),
              _buildOption(
                context,
                icon: Icons.copy,
                color: AppColor.kGreen,
                label: 'Copy',
                onPressed: () {
                  Navigator.pop(context);
                  copyTransaction(transaction, selectedDate);
                },
              ),
            ],
          ),
        ],
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
