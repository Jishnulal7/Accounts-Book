import 'package:account_book/app/data/model/item_selection_model.dart';
import 'package:account_book/app/data/model/purchase_model.dart';
import 'package:account_book/app/screens/transactions/purchase/purchase.dart';
import 'package:flutter/material.dart';

class PurchaseReturn extends StatelessWidget {
  final ItemSelectionModel? itemSelection;
  final VoidCallback? onItemAdded;
  final bool isDrawer;

  const PurchaseReturn({
    super.key,
    this.itemSelection,
    this.onItemAdded,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    return PurchaseTransaction(
      purchaseType: PurchaseType.purchaseReturn,
      itemSelection: itemSelection,
      onItemAdded: onItemAdded,
      isDrawer: isDrawer,
    );
  }
}
