import 'package:intl/intl.dart';
import 'package:account_book/app/screens/home/exports.dart';

class PartyLedger extends StatefulWidget {
  final String partyId;

  const PartyLedger({
    super.key,
    required this.partyId,
  });

  @override
  State<PartyLedger> createState() => _PartyLedgerState();
}

class _PartyLedgerState extends State<PartyLedger> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PartyProvider>(context, listen: false);
      final party = provider.getPartyById(widget.partyId);
      if (party?.name != null) {
        provider.fetchPartyTransactions(party!.name!);
      }
    });
  }

  Widget _buildHeaderCard(BuildContext context, PartyModel party,
      PartyProvider provider, String currencySymbol) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              // Wide layout
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          party.name ?? 'Unknown Party',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (party.contactNumber != null)
                          Text('Contact: ${party.contactNumber}'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Opening Balance: ${NumberFormat.currency(locale: 'en_IN', symbol: '$currencySymbol ').format(party.openingBalance ?? 0)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Current Balance: ${NumberFormat.currency(locale: 'en_IN', symbol: '$currencySymbol ').format(provider.calculatePartyBalance(party.name ?? ''))}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Narrow layout
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    party.name ?? 'Unknown Party',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (party.contactNumber != null)
                    Text('Contact: ${party.contactNumber}'),
                  const SizedBox(height: 16),
                  Text(
                    'Opening Balance: ${NumberFormat.currency(locale: 'en_IN', symbol: '$currencySymbol ').format(party.openingBalance ?? 0)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Current Balance: ${NumberFormat.currency(locale: 'en_IN', symbol: '$currencySymbol ').format(provider.calculatePartyBalance(party.name ?? ''))}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions,
      double openingBalance, String currencySymbol) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;

        if (isWideScreen) {
          return _buildWideTransactionTable(
              transactions, openingBalance, currencySymbol);
        } else {
          return _buildNarrowTransactionList(
              transactions, openingBalance, currencySymbol);
        }
      },
    );
  }

  Widget _buildWideTransactionTable(List<Transaction> transactions,
      double openingBalance, String currencySymbol) {
    double runningBalance = openingBalance;

    return SingleChildScrollView(
      controller: _horizontalScrollController,
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Debit')),
            DataColumn(label: Text('Credit')),
            DataColumn(label: Text('Balance')),
          ],
          rows: transactions.map((transaction) {
            runningBalance += transaction.debit - transaction.credit;
            return DataRow(
              cells: [
                DataCell(
                    Text(DateFormat('dd/MM/yyyy').format(transaction.date))),
                DataCell(Text(transaction.description)),
                DataCell(Text(transaction.debit > 0
                    ? NumberFormat.currency(
                            locale: 'en_IN', symbol: '$currencySymbol ')
                        .format(transaction.debit)
                    : '')),
                DataCell(Text(transaction.credit > 0
                    ? NumberFormat.currency(
                            locale: 'en_IN', symbol: '$currencySymbol ')
                        .format(transaction.credit)
                    : '')),
                DataCell(Text(NumberFormat.currency(
                        locale: 'en_IN', symbol: '$currencySymbol ')
                    .format(runningBalance))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNarrowTransactionList(List<Transaction> transactions,
      double openingBalance, String currencySymbol) {
    double runningBalance = openingBalance;

    return ListView.builder(
      shrinkWrap: true,
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        runningBalance += transaction.debit - transaction.credit;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            title: Text(DateFormat('dd/MM/yyyy').format(transaction.date)),
            subtitle: Text(transaction.description),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (transaction.debit > 0)
                      _buildTransactionDetail(
                          'Debit', transaction.debit, currencySymbol),
                    if (transaction.credit > 0)
                      _buildTransactionDetail(
                          'Credit', transaction.credit, currencySymbol),
                    _buildTransactionDetail(
                        'Balance', runningBalance, currencySymbol),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionDetail(
      String label, double amount, String currencySymbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            NumberFormat.currency(locale: 'en_IN', symbol: '$currencySymbol ')
                .format(amount),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Consumer<PartyProvider>(
      builder: (context, provider, _) {
        final party = provider.getPartyById(widget.partyId);
        if (party == null) {
          return const Center(child: Text('Party not found'));
        }

        final transactions = _combineTransactions(provider.transactions);

        return Scaffold(
          appBar: AppBar(
            title: Text(party.name ?? 'Party Ledger'),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => _generateAndViewPdf(context, party, provider),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildHeaderCard(context, party, provider, currencySymbol),
              Expanded(
                child: _buildTransactionList(
                    transactions, party.openingBalance ?? 0, currencySymbol),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateAndViewPdf(
    BuildContext context,
    PartyModel party,
    PartyProvider provider,
  ) async {
    final transactions = _combineTransactions(provider.transactions);

    final pdfFile = await PdfStatementForParty.generatePartyStatement(
      party: party,
      transactions: transactions,
      openingBalance: party.openingBalance ?? 0,
      currentBalance: provider.calculatePartyBalance(party.name ?? ''),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(filePath: pdfFile.path),
      ),
    );
  }

  List<Transaction> _combineTransactions(List<dynamic> transactions) {
    return transactions.map((transaction) {
      if (transaction is SaleModel) {
        switch (transaction.type) {
          case SalesType.sale:
          case SalesType.estimation:
          case SalesType.deliveryChallan:
            return Transaction(
              date: transaction.date,
              description:
                  '${transaction.type.name.toUpperCase()} - ${transaction.invoiceNumber}',
              debit: transaction.totalAmount,
              credit: 0,
              type: transaction.type.name,
              receivedAmount: transaction.receivedAmount ?? 0,
            );
          case SalesType.salesReturn:
            return Transaction(
              date: transaction.date,
              description:
                  '${transaction.type.name.toUpperCase()} - ${transaction.invoiceNumber}',
              debit: 0,
              credit: transaction.totalAmount,
              type: transaction.type.name,
              receivedAmount: transaction.receivedAmount ?? 0,
            );
          case SalesType.proforma:
            return Transaction(
              date: transaction.date,
              description:
                  '${transaction.type.name.toUpperCase()} - ${transaction.invoiceNumber}',
              debit: 0,
              credit: transaction.totalAmount,
              type: transaction.type.name,
              receivedAmount: transaction.receivedAmount ?? 0,
            );
          case SalesType.salesOrder:
            return Transaction(
              date: transaction.date,
              description:
                  '${transaction.type.name.toUpperCase()} - ${transaction.invoiceNumber}',
              debit: 0,
              credit: transaction.totalAmount,
              type: transaction.type.name,
              receivedAmount: transaction.receivedAmount ?? 0,
            );
        }
      } else if (transaction is PurchaseModel) {
        switch (transaction.type) {
          case PurchaseType.purchase:
          case PurchaseType.purchaseOrder:
            return Transaction(
              date: transaction.date,
              description:
                  '${transaction.type.name.toUpperCase()} - ${transaction.invoiceNumber}',
              credit: transaction.totalAmount,
              debit: 0,
              type: transaction.type.name,
              receivedAmount: transaction.paidAmount ?? 0,
            );
          case PurchaseType.purchaseReturn:
            return Transaction(
              date: transaction.date,
              description:
                  '${transaction.type.name.toUpperCase()} - ${transaction.invoiceNumber}',
              credit: 0,
              debit: transaction.totalAmount,
              type: transaction.type.name,
              receivedAmount: transaction.paidAmount ?? 0,
            );
        }
      }
      throw Exception('Unknown transaction type');
    }).toList();
  }
}

class Transaction {
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final String type;
  final double receivedAmount;

  Transaction({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.type,
    required this.receivedAmount,
  });
}

class PdfViewerScreen extends StatelessWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Party Statement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePdf(context),
          ),
        ],
      ),
      body: SfPdfViewer.file(
        File(filePath),
        initialScrollOffset: Offset.zero,
        initialZoomLevel: 1.0,
      ),
    );
  }

  void _sharePdf(BuildContext context) {
    // Implement your share functionality here
  }
}
