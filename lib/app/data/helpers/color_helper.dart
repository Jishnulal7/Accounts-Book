import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/data/constants/colors.dart';
import 'package:flutter/material.dart';


class ColorHelper {
  Color color(TransactionModel transaction) {
    Color textColor;
    switch (transaction.transactionType) {
      case TransactionType.payment:
        textColor = AppColor.kRed;
        break;
      case TransactionType.receipt:
        textColor = AppColor.kGreen;
        break;
      case TransactionType.transfer:
        textColor = AppColor.kPrimary;
        break;
      }
    return textColor;
  }

  Color selectColor(TransactionModel transaction) {
    if (transaction.transactionType != TransactionType.payment) {
      return AppColor.kGreen;
    } else {
      return AppColor.kRed;
    }
  }

  Color darkorWhite(BuildContext context) {
    ThemeData currentTheme = Theme.of(context);

    if (currentTheme.brightness == Brightness.dark) {
      return AppColor.kWhite;
    } else {
      return AppColor.kGrayscaleDark100;
    }
  }

  Color whiteOrDark(BuildContext context) {
    ThemeData currentTheme = Theme.of(context);

    if (currentTheme.brightness == Brightness.dark) {
      return AppColor.kGrayscaleDark100;
    } else {
      return AppColor.kWhite;
    }
  }

  int getDaysInMonth(int month) {
    if (month == 4 || month == 6 || month == 9 || month == 11) {
      return 30;
    } else if (month == 2) {
      final year = DateTime.now().year;
      if ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) {
        return 29;
      } else {
        return 28;
      }
    } else {
      return 31;
    }
  }
}
