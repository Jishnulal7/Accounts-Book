import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/icon_helper.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CategoryTransactionCard extends StatelessWidget {
  const CategoryTransactionCard({
    super.key,
    required this.transaction,
    required this.color,
    this.onEdit,
    this.onDelete,
    required this.title,
  });
  final TransactionModel transaction;
  final Color color;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String title;
  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          onEdit!();
                        },
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () {
                          onDelete!();
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                title == 'Payment Categories' ? 'Payment' : 'Receipt',
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.center,
                child: Text(
                  '$currencySymbol${transaction.amount.toStringAsFixed(1)}',
                  style: TextStyle(
                      fontSize: 35,
                      color: title == 'Payment Categories'
                          ? AppColor.kRed
                          : AppColor.kGreen),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  DateFormat('dd MMM yyyy').format(transaction.date),
                  style: const TextStyle(
                      fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
              SizedBox(
                height: 20,
                child: Divider(color: color),
              ),
              ListTile(
                dense: true,
                leading: const Text(
                  'Account',
                  style: TextStyle(fontSize: 15),
                ),
                title: Row(
                  children: [
                    const SizedBox(
                      width: 8,
                    ),
                    Image.asset(
                      width: 30,
                      CustomIcons()
                          .getImagePathForAccounts(transaction.fromAccount),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        overflow: TextOverflow.ellipsis,
                        transaction.fromAccount,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                dense: true,
                leading: const Text(
                  'Category',
                  style: TextStyle(fontSize: 15),
                ),
                title: Row(
                  children: [
                    Image.asset(
                      width: 30,
                      CustomIcons()
                          .getImagePathForCategory(transaction.categoryName!),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        transaction.categoryName!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                dense: true,
                leading: const Text(
                  'Description',
                  style: TextStyle(fontSize: 15),
                ),
                title: Text(
                  transaction.description,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
