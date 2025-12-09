import 'package:account_book/app/data/model/item_selection_model.dart';
import 'package:account_book/app/data/model/purchase_model.dart';
import 'package:account_book/app/screens/transactions/purchase/purchase.dart';
import 'package:flutter/material.dart';

class PurchaseOrder extends StatelessWidget {
  final ItemSelectionModel? itemSelection;
  final VoidCallback? onItemAdded;
  final bool isDrawer;

  const PurchaseOrder({
    super.key,
    this.itemSelection,
    this.onItemAdded,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    return PurchaseTransaction(
      purchaseType: PurchaseType.purchaseOrder,
      itemSelection: itemSelection,
      onItemAdded: onItemAdded,
      isDrawer: isDrawer,
    );
  }
}
