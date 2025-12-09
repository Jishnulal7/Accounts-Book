import 'package:account_book/app/providers/transaction_provider.dart';
import 'package:account_book/app/screens/home/exports.dart';
import 'package:intl/intl.dart';

class TransactionCard extends StatelessWidget {
  final SaleModel? sale;
  final PartyModel party;
  final PurchaseModel? purchaseModel;
  final VoidCallback onSaleDeleted;
  final VoidCallback onSaleUpdated;
  final VoidCallback onPurchaseUpdated;

  const TransactionCard({
    super.key,
    this.sale,
    this.purchaseModel,
    required this.onSaleDeleted,
    required this.party,
    required this.onSaleUpdated,
    required this.onPurchaseUpdated,
  }) : assert(sale != null || purchaseModel != null,
            'Either sale or purchaseModel must be provided');

  @override
  Widget build(BuildContext context) {
    final isSale = sale != null;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth >= 600;
    final isTableView = screenWidth >= 800;
    final partyProvider = Provider.of<PartyProvider>(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            isLargeScreen ? constraints.maxWidth * 0.95 : constraints.maxWidth;

        return Center(
          child: SizedBox(
            width: cardWidth,
            child: Card(
              elevation: 2,
              margin: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8.0 : 16.0,
                vertical: 8.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  if (isSale) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditSaleTransaction(
                          sale: sale!,
                          onSaleDeleted: onSaleDeleted,
                          onSaleUpdated: onSaleUpdated,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPurchaseTransactions(
                          onPurchaseUpdated: onSaleDeleted,
                          purchase: purchaseModel!,
                          onPurchaseDeleted: onSaleDeleted,
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12.0 : 16.0,
                    vertical: isSmallScreen ? 12.0 : 16.0,
                  ),
                  child: isTableView
                      ? _buildTableLayout(context, isSale, theme,
                          currencySymbol, isLargeScreen, partyProvider)
                      : _buildCardLayout(
                          context,
                          isSale,
                          theme,
                          currencySymbol,
                          isLargeScreen,
                          isSmallScreen,
                          screenWidth,
                          partyProvider,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableLayout(
    BuildContext context,
    bool isSale,
    ThemeData theme,
    String currencySymbol,
    bool isLargeScreen,
    PartyProvider partyProvider,
  ) {
    // Create a structured table-like layout for wide screens

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Party Name
              Expanded(
                flex: 3,
                child: Text(
                  'PARTY',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              // Invoice Number
              Expanded(
                flex: 2,
                child: Text(
                  'INVOICE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Transaction Type
              Expanded(
                flex: 2,
                child: Text(
                  'TYPE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Date
              Expanded(
                flex: 2,
                child: Text(
                  'DATE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Total Amount
              Expanded(
                flex: 2,
                child: Text(
                  'TOTAL',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              // Balance
              Expanded(
                flex: 2,
                child: Text(
                  'BALANCE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              // Actions
              Expanded(
                flex: 2,
                child: Text(
                  'ACTIONS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Data Row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Party Name
              Expanded(
                flex: 3,
                child: Text(
                  isSale ? sale!.partyName : purchaseModel!.partyName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: isLargeScreen ? 16 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Invoice Number
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.center,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${isSale ? sale!.invoiceNumber : purchaseModel!.invoiceNumber}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              // Transaction Type
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.center,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isSale ? Colors.green : Colors.blue)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSale ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: isSale ? Colors.green : Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: isSale
                              ? Helper().salesType(sale!)
                              : Helper().purchaseType(purchaseModel!),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Date
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('dd MMM y')
                      .format(isSale ? sale!.date : purchaseModel!.date),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              // Total Amount
              Expanded(
                flex: 2,
                child: Text(
                  '$currencySymbol ${isSale ? sale!.totalAmount.toStringAsFixed(2) : purchaseModel!.totalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              // Balance
              Expanded(
                flex: 2,
                child: Text(
                  '$currencySymbol ${isSale ? sale!.balanceAmount.toStringAsFixed(2) : purchaseModel!.balanceAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: (isSale
                                ? sale!.balanceAmount
                                : purchaseModel!.balanceAmount) >
                            0
                        ? Colors.red
                        : Colors.green,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              // Actions Column (PDF & Convert)
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Convert Button
                    _buildConvertButton(context, theme, isLargeScreen),
                    const SizedBox(width: 16),
                    // PDF Button
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => isSale
                                  ? SalePdf(sale: sale!, party: party)
                                  : PurchasePdf(
                                      purchase: purchaseModel!, party: party),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Tooltip(
                            message: "Generate PDF",
                            child: Icon(
                              Icons.picture_as_pdf,
                              size: 20,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardLayout(
    BuildContext context,
    bool isSale,
    ThemeData theme,
    String currencySymbol,
    bool isLargeScreen,
    bool isSmallScreen,
    double screenWidth,
    PartyProvider partyProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: isLargeScreen ? 2 : 1,
              child: Text(
                isSale ? sale!.partyName : purchaseModel!.partyName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isLargeScreen ? 18 : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 12 : 8,
                vertical: isLargeScreen ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${isSale ? sale!.invoiceNumber : purchaseModel!.invoiceNumber}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: isLargeScreen ? 14 : null,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isLargeScreen ? 16 : 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 16 : 12,
                vertical: isLargeScreen ? 8 : 6,
              ),
              decoration: BoxDecoration(
                color: (isSale ? Colors.green : Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSale ? Icons.arrow_upward : Icons.arrow_downward,
                    size: isLargeScreen ? 20 : 16,
                    color: isSale ? Colors.green : Colors.blue,
                  ),
                  SizedBox(width: isLargeScreen ? 8 : 4),
                  isSale
                      ? Helper().salesType(sale!)
                      : Helper().purchaseType(purchaseModel!),
                ],
              ),
            ),
            Text(
              DateFormat('dd MMM y')
                  .format(isSale ? sale!.date : purchaseModel!.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                fontSize: isLargeScreen ? 14 : null,
              ),
            ),
          ],
        ),
        SizedBox(height: isLargeScreen ? 24 : 16),
        Row(
          children: [
            Expanded(
              child: _buildAmountColumn(
                context,
                'Total Amount',
                '$currencySymbol ${isSale ? sale!.totalAmount : purchaseModel!.totalAmount}',
                isLargeScreen,
              ),
            ),
            Expanded(
              child: _buildAmountColumn(
                context,
                'Balance',
                '$currencySymbol ${isSale ? sale!.balanceAmount : purchaseModel!.balanceAmount}',
                isLargeScreen,
                textColor: (isSale
                            ? sale!.balanceAmount
                            : purchaseModel!.balanceAmount) >
                        0
                    ? Colors.red
                    : Colors.green,
              ),
            ),
            _buildConvertButton(context, theme, isLargeScreen),
            _buildPDFButton(context, theme, isSale, isLargeScreen, screenWidth),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountColumn(
    BuildContext context,
    String label,
    String amount,
    bool isLargeScreen, {
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            fontSize: isLargeScreen ? 14 : null,
          ),
        ),
        SizedBox(height: isLargeScreen ? 8 : 4),
        Text(
          amount,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: isLargeScreen ? 18 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPDFButton(
    BuildContext context,
    ThemeData theme,
    bool isSale,
    bool isLargeScreen,
    double screenWidth,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isSale
                  ? SalePdf(sale: sale!, party: party)
                  : PurchasePdf(purchase: purchaseModel!, party: party),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 12.0 : 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: isLargeScreen ? 24 : 20,
                color: theme.primaryColor,
              ),
              if (isLargeScreen || screenWidth > 400) ...[
                const SizedBox(width: 4),
                Text(
                  'PDF',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: isLargeScreen ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  } // Add this method to the TransactionCard class

  Widget _buildConvertButton(
      BuildContext context, ThemeData theme, bool isLargeScreen) {
    final isSale = sale != null;

    return PopupMenuButton<dynamic>(
      icon: Icon(
        Icons.swap_horiz,
        size: isLargeScreen ? 24 : 20,
        color: theme.primaryColor,
      ),
      tooltip: 'Convert to another type',
      onSelected: (dynamic newType) async {
        final provider =
            Provider.of<TransactionProvider>(context, listen: false);

        try {
          if (isSale) {
            final result =
                await provider.convertSaleType(sale!, newType as SalesType);
            if (result != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Successfully converted to ${_getTypeName(newType)}'),
                  duration: const Duration(seconds: 2),
                ),
              );
              onSaleUpdated();
            }
          } else {
            final result = await provider.convertPurchaseType(
                purchaseModel!, newType as PurchaseType);
            if (result != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Successfully converted to ${_getPurchaseTypeName(newType)}'),
                  duration: const Duration(seconds: 2),
                ),
              );
              onPurchaseUpdated();
            }
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Conversion failed: ${e.toString()}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) {
        if (isSale) {
          // Sale conversion options
          return <PopupMenuEntry<SalesType>>[
            if (sale!.type != SalesType.sale)
              PopupMenuItem<SalesType>(
                value: SalesType.sale,
                child: Text('Convert to Invoice/Sale'),
              ),
            if (sale!.type != SalesType.salesOrder)
              PopupMenuItem<SalesType>(
                value: SalesType.salesOrder,
                child: Text('Convert to Sales Order'),
              ),
            if (sale!.type != SalesType.salesReturn)
              PopupMenuItem<SalesType>(
                value: SalesType.salesReturn,
                child: Text('Convert to Sales Return'),
              ),
            if (sale!.type != SalesType.proforma)
              PopupMenuItem<SalesType>(
                value: SalesType.proforma,
                child: Text('Convert to Proforma'),
              ),
            if (sale!.type != SalesType.estimation)
              PopupMenuItem<SalesType>(
                value: SalesType.estimation,
                child: Text('Convert to Quotation'),
              ),
            if (sale!.type != SalesType.deliveryChallan)
              PopupMenuItem<SalesType>(
                value: SalesType.deliveryChallan,
                child: Text('Convert to Delivery Challan'),
              ),
          ];
        } else {
          // Purchase conversion options
          return <PopupMenuEntry<PurchaseType>>[
            if (purchaseModel!.type != PurchaseType.purchase)
              PopupMenuItem<PurchaseType>(
                value: PurchaseType.purchase,
                child: Text('Convert to Purchase'),
              ),
            if (purchaseModel!.type != PurchaseType.purchaseOrder)
              PopupMenuItem<PurchaseType>(
                value: PurchaseType.purchaseOrder,
                child: Text('Convert to Purchase Order'),
              ),
            if (purchaseModel!.type != PurchaseType.purchaseReturn)
              PopupMenuItem<PurchaseType>(
                value: PurchaseType.purchaseReturn,
                child: Text('Convert to Purchase Return'),
              ),
          ];
        }
      },
    );
  }

  String _getPurchaseTypeName(PurchaseType type) {
    switch (type) {
      case PurchaseType.purchase:
        return 'Purchase';
      case PurchaseType.purchaseOrder:
        return 'Purchase Order';
      case PurchaseType.purchaseReturn:
        return 'Purchase Return';
    }
  }

  String _getTypeName(SalesType type) {
    switch (type) {
      case SalesType.sale:
        return 'Invoice/Sale';
      case SalesType.salesOrder:
        return 'Sales Order';
      case SalesType.salesReturn:
        return 'Sales Return';
      case SalesType.proforma:
        return 'Proforma Invoice';
      case SalesType.estimation:
        return 'Quotation';
      case SalesType.deliveryChallan:
        return 'Delivery Challan';
    }
  }
}
