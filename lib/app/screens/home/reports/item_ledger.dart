import 'package:account_book/app/screens/home/reports/item_ledger_pdf.dart';
import 'package:account_book/app/screens/home/exports.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';

class ItemLedgerScreen extends StatefulWidget {
  final String? itemId;

  const ItemLedgerScreen({super.key, this.itemId});

  @override
  State<ItemLedgerScreen> createState() => _ItemLedgerScreenState();
}

class _ItemLedgerScreenState extends State<ItemLedgerScreen> {
  final TextEditingController _searchController = TextEditingController();
  ItemModel? selectedItem;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  double openingBalance = 0;
  double closingBalance = 0;
  bool isCompactView = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      loadItemData(widget.itemId!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update compact view mode based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      isCompactView = screenWidth < 700;
    });
  }

  Future<void> loadItemData(String itemId) async {
    final itemBox = Hive.box<ItemModel>('itemBox');
    final saleBox = Hive.box<SaleModel>('saleBox');
    final purchaseBox = Hive.box<PurchaseModel>('purchaseBox');

    // Get the selected item
    final item = itemBox.values.firstWhere((item) => item.id == itemId);
    setState(() => selectedItem = item);

    // Process sales transactions
    final salesTransactions = saleBox.values.where((sale) {
      return sale.item.any((item) => item.id == itemId);
    }).expand((sale) {
      return sale.item.where((item) => item.id == itemId).map((item) => {
            'date': sale.date,
            'type': 'Sale',
            'quantity': item.quantity,
            'rate': item.rate,
            'amount': item.totalAmount,
            'partyName': sale.partyName,
            'invoiceNumber': sale.invoiceNumber,
          });
    }).toList();

    // Process purchase transactions
    final purchaseTransactions = purchaseBox.values.where((purchase) {
      return purchase.item.any((item) => item.id == itemId);
    }).expand((purchase) {
      return purchase.item.where((item) => item.id == itemId).map((item) => {
            'date': purchase.date,
            'type': 'Purchase',
            'quantity': item.quantity,
            'rate': item.rate,
            'amount': item.totalAmount,
            'partyName': purchase.partyName,
            'invoiceNumber': purchase.invoiceNumber,
          });
    }).toList();

    // Combine and sort all transactions
    final allTransactions = [...salesTransactions, ...purchaseTransactions];
    allTransactions.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // Calculate running balance
    double balance = selectedItem?.stockQuantity?.toDouble() ?? 0;
    for (var transaction in allTransactions) {
      if (transaction['type'] == 'Sale') {
        balance += transaction['quantity'] as num;
      } else {
        balance -= transaction['quantity'] as num;
      }
      transaction['balance'] = balance;
    }

    setState(() {
      transactions = allTransactions;
      filteredTransactions = allTransactions;
      closingBalance = balance;
      openingBalance = selectedItem?.stockQuantity?.toDouble() ?? 0;
    });
  }

  void filterTransactions(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredTransactions = transactions;
      });
      return;
    }

    setState(() {
      filteredTransactions = transactions.where((transaction) {
        final partyName = transaction['partyName'].toString().toLowerCase();
        final invoiceNumber =
            transaction['invoiceNumber'].toString().toLowerCase();
        final type = transaction['type'].toString().toLowerCase();

        return partyName.contains(query.toLowerCase()) ||
            invoiceNumber.contains(query.toLowerCase()) ||
            type.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _generateAndViewPdf(BuildContext context) async {
    if (selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an item first')),
      );
      return;
    }

    final pdfFile = await ItemPdfStatementService.generateItemStatement(
      item: selectedItem!,
      transactions: transactions,
      openingBalance: openingBalance,
      closingBalance: closingBalance,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemLedgerPdf(filePath: pdfFile.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item Ledger'),
        actions: [
          IconButton(
            icon: Icon(isCompactView ? Icons.table_chart : Icons.view_list),
            tooltip: isCompactView
                ? 'Switch to detailed view'
                : 'Switch to compact view',
            onPressed: () {
              setState(() {
                isCompactView = !isCompactView;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () {
              _generateAndViewPdf(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildItemDetailsCard(),
          _buildSearchBar(),
          Expanded(
            child: isCompactView ? _buildCompactView() : _buildDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailsCard() {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedItem?.itemName ?? 'Select Item',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailColumn('Opening Stock', openingBalance.toString()),
                _buildDetailColumn('Closing Stock', closingBalance.toString()),
                _buildDetailColumn('Unit', selectedItem?.unit ?? '-'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          filterTransactions(value);
        },
      ),
    );
  }

  Widget _buildDataTable() {
    // Use adaptive column sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 900 && screenWidth <= 1200;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 70,
          ),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            border: TableBorder.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
            // Adjust column spacing based on screen width
            columnSpacing: isWideScreen ? 24.0 : (isMediumScreen ? 16.0 : 12.0),
            // Add horizontal padding based on screen width
            horizontalMargin:
                isWideScreen ? 24.0 : (isMediumScreen ? 16.0 : 8.0),
            columns: [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Party')),
              if (isWideScreen) DataColumn(label: Text('Invoice')),
              DataColumn(label: Text('In'), numeric: true),
              DataColumn(label: Text('Out'), numeric: true),
              if (isWideScreen || isMediumScreen)
                DataColumn(label: Text('Rate'), numeric: true),
              DataColumn(label: Text('Amount'), numeric: true),
              DataColumn(label: Text('Balance'), numeric: true),
            ],
            rows: filteredTransactions.map((transaction) {
              final isStockIn = transaction['type'] == 'Purchase';
              final quantity = transaction['quantity'] as num;

              return DataRow(
                cells: [
                  DataCell(Text(DateFormat('dd/MM/yyyy')
                      .format(transaction['date'] as DateTime))),
                  DataCell(
                    Text(
                      transaction['type'],
                      style: TextStyle(
                        color: transaction['type'] == 'Sale'
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(Text(transaction['partyName'])),
                  if (isWideScreen)
                    DataCell(Text(transaction['invoiceNumber'].toString())),
                  DataCell(Text(
                    isStockIn ? quantity.toString() : '-',
                    style: TextStyle(color: Colors.green),
                  )),
                  DataCell(Text(
                    !isStockIn ? quantity.toString() : '-',
                    style: TextStyle(color: Colors.red),
                  )),
                  if (isWideScreen || isMediumScreen)
                    DataCell(Text(
                      NumberFormat('###,##0.00').format(transaction['rate']),
                      textAlign: TextAlign.right,
                    )),
                  DataCell(Text(
                    NumberFormat('###,##0.00').format(transaction['amount']),
                    textAlign: TextAlign.right,
                  )),
                  DataCell(Text(
                    transaction['balance'].toString(),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactView() {
    return ListView.builder(
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        final isStockIn = transaction['type'] == 'Purchase';
        final quantity = transaction['quantity'] as num;

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  color:
                      transaction['type'] == 'Sale' ? Colors.red : Colors.green,
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy')
                          .format(transaction['date'] as DateTime),
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      transaction['type'],
                      style: TextStyle(
                        color: transaction['type'] == 'Sale'
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Amount: ${NumberFormat('###,##0.00').format(transaction['amount'])}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Balance: ${NumberFormat('###,##0.00').format(transaction['balance'])}',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCompactDetailRow('Party', transaction['partyName']),
                    _buildCompactDetailRow(
                        'Invoice', transaction['invoiceNumber'].toString()),
                    _buildCompactDetailRow(
                      'Quantity',
                      isStockIn
                          ? 'In: ${quantity.toString()}'
                          : 'Out: ${quantity.toString()}',
                      valueColor: isStockIn ? Colors.green : Colors.red,
                    ),
                    _buildCompactDetailRow('Rate',
                        NumberFormat('###,##0.00').format(transaction['rate'])),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactDetailRow(String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
