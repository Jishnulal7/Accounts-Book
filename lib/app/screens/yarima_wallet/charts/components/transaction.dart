import 'package:account_book/app/data/helpers/category_text.dart';
import 'package:account_book/app/data/helpers/color_helper.dart';
import 'package:account_book/app/data/helpers/icon_helper.dart' show CustomIcons;
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TransactionWidget extends StatelessWidget {
  const TransactionWidget({
    super.key,
    required this.width,
    required this.transaction,
  });

  final double width;
  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * .05),
      child: ListTile(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AccountTransactionCard(
              transaction: transaction,
              color: ColorHelper().darkorWhite(context),
              isEditable: false,
            ),
          );
        },
        dense: true,
        leading: Image.asset(
          CustomIcons().getImagePathForCategory(getCategoryText(transaction)),
          width: 30,
        ),
        title: Text(
          getCategoryText(transaction),
          style: const TextStyle(fontSize: 15),
        ),
        subtitle: Text(transaction.description),
        trailing: Text(
          transaction.transactionType == TransactionType.payment
              ? '$currencySymbol${transaction.amount}'
              : '$currencySymbol${transaction.amount}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: ColorHelper().selectColor(transaction),
          ),
        ),
      ),
    );
  }
}
