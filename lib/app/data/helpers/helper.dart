import 'package:flutter/material.dart';
import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/model/purchase_model.dart';
import 'package:account_book/app/data/model/sale_model.dart';

class Helper {
  salesType(SaleModel sale) {
    Text text;
    switch (sale.type) {
      case SalesType.sale:
        text = const Text(
          'Sale',
          style: TextStyle(color: Colors.deepOrangeAccent),
        );
        break;

      case SalesType.salesReturn:
        text = const Text(
          'Sales Return',
          style: TextStyle(color: Colors.deepOrangeAccent),
        );
        break;

      case SalesType.estimation:
        text = const Text(
          'Estimate',
          style: TextStyle(color: Colors.deepOrangeAccent),
        );
        break;
      case SalesType.deliveryChallan:
        text = const Text(
          'Delivery Challan',
          style: TextStyle(color: Colors.deepOrangeAccent),
        );
        break;
      case SalesType.proforma:
        text = const Text(
          'Proforma',
          style: TextStyle(color: Colors.deepOrangeAccent),
        );
        break;
      case SalesType.salesOrder:
        text = const Text(
          'Sale Order',
          style: TextStyle(color: Colors.deepOrangeAccent),
        );
        break;
    }
    return text;
  }

  purchaseType(PurchaseModel purchase) {
    Text text;
    switch (purchase.type) {
      case PurchaseType.purchase:
        text = Text(
          'Purchase',
          style: TextStyle(color: AppColor.kGreen),
        );
        break;

      case PurchaseType.purchaseOrder:
        text = const Text(
          'Purchase Order',
          style: TextStyle(color: Colors.deepOrangeAccent),
        );
        break;
      case PurchaseType.purchaseReturn:
        text = const Text(
          'Purchase Return',
          style: TextStyle(color: Colors.deepOrangeAccent),
        );
        break;
    }
    return text;
  }
}
