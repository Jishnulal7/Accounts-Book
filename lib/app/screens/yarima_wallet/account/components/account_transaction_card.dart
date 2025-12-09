import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/category_text.dart';
import 'package:account_book/app/data/helpers/icon_helper.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AccountTransactionCard extends StatelessWidget {
  const AccountTransactionCard({
    super.key,
    required this.transaction,
    required this.color,
    this.onEdit,
    this.onDelete,
    this.onAccountAdded,
    required this.isEditable,
  });

  final TransactionModel transaction;
  final Color color;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAccountAdded;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildAmount(context),
              const SizedBox(height: 8),
              _buildDate(),
              const SizedBox(height: 16),
              Divider(color: color),
              const SizedBox(height: 16),
              _buildTransactionDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _getTransactionTypeText(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Row(
          children: [
            if (isEditable) ...[
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: onDelete,
              ),
            ],
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmount(BuildContext ctx) {
    final currencySymbol = Provider.of<CurrencyNotifier>(ctx).currencySymbol;
    return Text(
      '$currencySymbol${transaction.amount.toStringAsFixed(1)}',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _getAmountColor(),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDate() {
    return Text(
      DateFormat('dd MMM yyyy').format(transaction.date),
      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTransactionDetails() {
    return Column(
      children: [
        _buildDetailRow(
          label: transaction.transactionType == TransactionType.transfer
              ? 'From'
              : 'Account',
          value: transaction.fromAccount,
          iconPath:
              CustomIcons().getImagePathForAccounts(transaction.fromAccount),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          label: transaction.transactionType == TransactionType.transfer
              ? 'To'
              : 'Category',
          value: transaction.transactionType == TransactionType.transfer
              ? transaction.toAccount
              : getCategoryText(transaction),
          iconPath: CustomIcons().getImagePathForCategory(
            transaction.transactionType == TransactionType.transfer
                ? transaction.toAccount
                : transaction.generalCategory ?? transaction.categoryName ?? '',
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          label: 'Description',
          value: transaction.description,
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      {required String label, required String value, String? iconPath}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Row(
            children: [
              if (iconPath != null) ...[
                Image.asset(iconPath, width: 24, height: 24),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(value, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTransactionTypeText() {
    switch (transaction.transactionType) {
      case TransactionType.payment:
        return 'Payment';
      case TransactionType.receipt:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  Color _getAmountColor() {
    switch (transaction.transactionType) {
      case TransactionType.payment:
        return AppColor.kRed;
      case TransactionType.receipt:
        return AppColor.kGreen;
      case TransactionType.transfer:
        return AppColor.kPrimary;
    }
  }
}
