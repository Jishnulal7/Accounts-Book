import 'package:account_book/app/screens/transactions/export.dart';
import 'package:account_book/app/screens/transactions/sales/sale.dart';

class SaleOrder extends StatelessWidget {
  final ItemSelectionModel? itemSelection;
  final VoidCallback? onItemAdded;
  final bool isDrawer;

  const SaleOrder({
    super.key,
    this.itemSelection,
    this.onItemAdded,
    this.isDrawer = false,

  });

  @override
  Widget build(BuildContext context) {
    return SalesTransaction(
      salesType: SalesType.salesOrder,
      itemSelection: itemSelection,
      onItemAdded: onItemAdded,
      isDrawer: isDrawer,
    );
  }
}
