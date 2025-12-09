import 'package:account_book/app/screens/transactions/export.dart';
import 'package:intl/intl.dart';

class InvoiceInfo extends StatelessWidget {
  final String invoiceNumber;
  final DateTime invoiceDate;
  final TransactionType transactionType;
  final dynamic transactionSubtype;
  final Function(String, DateTime, PrefixType, String) onEditInvoice;
  final PrefixType prefixType;
  final String customPrefix;

  const InvoiceInfo({
    super.key,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.transactionType,
    required this.transactionSubtype,
    required this.onEditInvoice,
    this.prefixType = PrefixType.none,
    this.customPrefix = '',
  });

  String get _invoiceName {
    switch (transactionType) {
      case TransactionType.sale:
        return _getSalesInvoiceName();
      case TransactionType.purchase:
        return _getPurchaseInvoiceName();
    }
  }

  String _getSalesInvoiceName() {
    if (transactionSubtype is SalesType) {
      switch (transactionSubtype as SalesType) {
        case SalesType.sale:
          return 'Sales Invoice';
        case SalesType.salesReturn:
          return 'Sales Return';
        case SalesType.estimation:
          return 'Estimate';
        case SalesType.deliveryChallan:
          return 'Delivery Challan';
        case SalesType.proforma:
          return 'Proforma';
        case SalesType.salesOrder:
          return 'Sales Order';
      }
    }
    return 'Invoice';
  }

  String _getPurchaseInvoiceName() {
    if (transactionSubtype is PurchaseType) {
      switch (transactionSubtype as PurchaseType) {
        case PurchaseType.purchase:
          return 'Purchase Invoice';
        case PurchaseType.purchaseReturn:
          return 'Purchase Return';
        case PurchaseType.purchaseOrder:
          return 'Purchase Order';
      }
    }
    return 'Invoice';
  }

  String get formattedInvoiceNumber {
    switch (prefixType) {
      case PrefixType.none:
        return invoiceNumber;
      case PrefixType.inv:
        return 'INV$invoiceNumber';
      case PrefixType.custom:
        return customPrefix.isNotEmpty
            ? '$customPrefix$invoiceNumber'
            : invoiceNumber;
      case PrefixType.saved:
        return customPrefix.isNotEmpty
            ? '$customPrefix$invoiceNumber'
            : invoiceNumber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;

        if (isWideScreen) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$_invoiceName: $formattedInvoiceNumber',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(invoiceDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => onEditInvoice(
                        invoiceNumber, invoiceDate, prefixType, customPrefix),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Invoice'),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Card(
            child: ListTile(
              dense: true,
              title: Text('$_invoiceName: $formattedInvoiceNumber'),
              subtitle: Text(DateFormat('dd MMM y').format(invoiceDate)),
              trailing: TextButton(
                onPressed: () => onEditInvoice(
                    invoiceNumber, invoiceDate, prefixType, customPrefix),
                child: const Text('Edit'),
              ),
            ),
          );
        }
      },
    );
  }
}
