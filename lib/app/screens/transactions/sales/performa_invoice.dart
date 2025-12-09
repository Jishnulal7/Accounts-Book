import 'package:account_book/app/screens/transactions/export.dart';
import 'package:account_book/app/screens/transactions/sales/sale.dart';

class ProformaInvoice extends StatelessWidget {
  final ItemSelectionModel? itemSelection;
  final VoidCallback? onItemAdded;
  final bool isDrawer;

  const ProformaInvoice({
    super.key,
    this.itemSelection,
    this.onItemAdded,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    return SalesTransaction(
      isDrawer: isDrawer,
      salesType: SalesType.proforma,
      itemSelection: itemSelection,
      onItemAdded: onItemAdded,
    );
  }
}
