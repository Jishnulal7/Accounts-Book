import 'package:account_book/app/data/helpers/icon_helper.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class TabsHelper {
  Widget buildIcon(String name, TransactionModel transaction,
      {required bool isAccount}) {
    final boxName = isAccount
        ? 'accounts'
        : (transaction.amount >= 0 ? 'receipt' : 'payment');
    final box = GetStorage('${boxName}_categories');
    final categoryData = box.read(name);

    if (categoryData != null && categoryData['imagePath'] != null) {
      final imagepath = categoryData['imagePath'];

      return Image.asset(
        imagepath,
        width: 20,
      );
    } else {
      // Fallback to CustomIcons if no custom icon is found
      return Image.asset(
        isAccount
            ? CustomIcons().getImagePathForAccounts(name)
            : CustomIcons().getImagePathForCategory(name),
        width: 20,
      );
    }
  }
}
