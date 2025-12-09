import 'package:account_book/app/screens/transactions/export.dart';
import 'package:account_book/app/screens/transactions/sales/sale.dart';

class DeliveryChallan extends StatelessWidget {
  final ItemSelectionModel? itemSelection;
  final VoidCallback? onItemAdded;
  final bool isDrawer;

  const DeliveryChallan({
    super.key,
    this.itemSelection,
    this.onItemAdded,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    return SalesTransaction(
      isDrawer: isDrawer,
      salesType: SalesType.deliveryChallan,
      itemSelection: itemSelection,
      onItemAdded: onItemAdded,
    );
  }
}
