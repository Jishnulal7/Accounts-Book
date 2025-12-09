import 'package:account_book/app/screens/transactions/export.dart';
import 'package:account_book/app/screens/transactions/sales/sale.dart';

class CreateSale extends StatelessWidget {
  final ItemSelectionModel? itemSelection;
  final VoidCallback? onItemAdded;
  final bool isStandalone;
  final bool isDrawer;
  final Function? onSaleCreated;

  const CreateSale({
    super.key,
    this.itemSelection,
    this.onItemAdded,
    this.isStandalone = false,
    this.onSaleCreated,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    return SalesTransaction(
      salesType: SalesType.sale,
      itemSelection: itemSelection,
      onItemAdded: onItemAdded,
      isDrawer: isDrawer,
    );
  }
}
