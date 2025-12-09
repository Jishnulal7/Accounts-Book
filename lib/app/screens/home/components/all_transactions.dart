import 'package:account_book/app/providers/item_provider.dart';
import 'package:account_book/app/screens/home/exports.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import '../../../data/helpers/enums/transaction_type.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _allTransactions = [];
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  String _searchQuery = '';
  String _filterType = 'All';
  final List<String> _filterOptions = [
    'All',
    'Sale',
    'Sale Orders',
    'Purchase',
    'Sales Return',
    'Purchase Return',
    'Estimation',
    'Delivery Challan',
    'Proforma',
    'Purchase Order'
  ];
  String _sortBy = 'Date (Newest)';
  final List<String> _sortOptions = [
    'Date (Newest)',
    'Date (Oldest)',
    'Amount (Highest)',
    'Amount (Lowest)',
    'Party Name (A-Z)',
    'Party Name (Z-A)'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    // Make sure all boxes are open
    if (!Hive.isBoxOpen('saleBox')) await Hive.openBox<SaleModel>('saleBox');
    if (!Hive.isBoxOpen('purchaseBox')) {
      await Hive.openBox<PurchaseModel>('purchaseBox');
    }
    if (!Hive.isBoxOpen('partyBox')) await Hive.openBox<PartyModel>('partyBox');
    if (!Hive.isBoxOpen('itemBox')) await Hive.openBox<ItemModel>('itemBox');

    // Get references to all boxes
    final saleBox = Hive.box<SaleModel>('saleBox');
    final purchaseBox = Hive.box<PurchaseModel>('purchaseBox');
    final partyBox = Hive.box<PartyModel>('partyBox');

    // Clear existing transactions
    _allTransactions.clear();

    // Load sale transactions
    for (int i = 0; i < saleBox.length; i++) {
      final sale = saleBox.getAt(i);
      if (sale != null) {
        PartyModel? party;
        if (sale.partyId != null) {
          for (int j = 0; j < partyBox.length; j++) {
            final p = partyBox.getAt(j);
            if (p != null && p.id == sale.partyId) {
              party = p;
              break;
            }
          }
        }

        _allTransactions.add({
          'type': sale.type == SalesType.salesReturn
              ? 'Sales Return'
              : sale.type == SalesType.estimation
                  ? 'Estimation'
                  : sale.type == SalesType.deliveryChallan
                      ? 'Delivery Challan'
                      : sale.type == SalesType.proforma
                          ? 'Proforma'
                          : sale.type == SalesType.salesOrder
                              ? 'Sales Order'
                              : 'Sale',
          'id': sale.id ?? '',
          'invoiceNumber': sale.invoiceNumber,
          'partyName': sale.partyName,
          'partyId': sale.partyId,
          'partyInfo': party,
          'date': sale.date,
          'amount': sale.totalAmount,
          'receivedAmount': sale.receivedAmount,
          'balanceAmount': sale.balanceAmount,
          'paymentType': sale.paymentType,
          'isFullyPaid': sale.isFullyPaid,
          'items': sale.item,
          'isReceivable': true,
          'originalObject': sale,
        });
      }
    }

    // Load purchase transactions
    for (int i = 0; i < purchaseBox.length; i++) {
      final purchase = purchaseBox.getAt(i);
      if (purchase != null) {
        PartyModel? party;
        if (purchase.partyId != null) {
          for (int j = 0; j < partyBox.length; j++) {
            final p = partyBox.getAt(j);
            if (p != null && p.id == purchase.partyId) {
              party = p;
              break;
            }
          }
        }

        _allTransactions.add({
          'type': purchase.type == PurchaseType.purchaseReturn
              ? 'Purchase Return'
              : purchase.type == PurchaseType.purchaseOrder
                  ? 'Purchase Order'
                  : 'Purchase',
          'id': purchase.id ?? '',
          'invoiceNumber': purchase.invoiceNumber,
          'partyName': purchase.partyName,
          'partyId': purchase.partyId,
          'partyInfo': party,
          'date': purchase.date,
          'amount': purchase.totalAmount,
          'receivedAmount': purchase.paidAmount,
          'balanceAmount': purchase.balanceAmount,
          'paymentType': purchase.paymentType,
          'isFullyPaid': purchase.isFullyPaid,
          'items': purchase.item,
          'isReceivable': false,
          'originalObject': purchase,
        });
      }
    }

    // Apply initial sorting
    _sortTransactions();

    setState(() {});
  }

  void _sortTransactions() {
    switch (_sortBy) {
      case 'Date (Newest)':
        _allTransactions.sort(
            (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
        break;
      case 'Date (Oldest)':
        _allTransactions.sort(
            (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        break;
      case 'Amount (Highest)':
        _allTransactions.sort(
            (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
        break;
      case 'Amount (Lowest)':
        _allTransactions.sort(
            (a, b) => (a['amount'] as double).compareTo(b['amount'] as double));
        break;
      case 'Party Name (A-Z)':
        _allTransactions.sort((a, b) =>
            (a['partyName'] as String).compareTo(b['partyName'] as String));
        break;
      case 'Party Name (Z-A)':
        _allTransactions.sort((a, b) =>
            (b['partyName'] as String).compareTo(a['partyName'] as String));
        break;
    }
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    return _allTransactions.where((transaction) {
      // Apply filter type
      if (_filterType != 'All' && transaction['type'] != _filterType) {
        return false;
      }

      // Apply search query
      if (_searchQuery.isNotEmpty) {
        final String query = _searchQuery.toLowerCase();
        return transaction['invoiceNumber']
                .toString()
                .toLowerCase()
                .contains(query) ||
            transaction['partyName'].toLowerCase().contains(query) ||
            (transaction['paymentType'] != null &&
                transaction['paymentType'].toLowerCase().contains(query));
      }

      return true;
    }).toList();
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Sale':
        return Colors.green.shade700;
      case 'Sale Order':
        return const Color.fromARGB(255, 83, 211, 89);
      case 'Purchase':
        return Colors.blue.shade700;
      case 'Sales Return':
        return Colors.orange;
      case 'Purchase Return':
        return Colors.purple;
      case 'Estimation':
        return Colors.teal;
      case 'Delivery Challan':
        return Colors.indigo;
      case 'Proforma':
        return Colors.deepOrange;
      case 'Purchase Order':
        return Colors.brown;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _getFilteredTransactions();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'List View'),
              Tab(text: 'Calendar View'),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Refresh Transactions',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by invoice number, party name...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: isSmallScreen
                  ? Column(
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Filter by Type',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          value: _filterType,
                          items: _filterOptions.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _filterType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Sort by',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          value: _sortBy,
                          items: _sortOptions.map((option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                              _sortTransactions();
                            });
                          },
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Filter by Type',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            value: _filterType,
                            items: _filterOptions.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _filterType = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Sort by',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            value: _sortBy,
                            items: _sortOptions.map((option) {
                              return DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _sortBy = value!;
                                _sortTransactions();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // List View
                  filteredTransactions.isEmpty
                      ? const Center(child: Text('No transactions found'))
                      : ListView.builder(
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = filteredTransactions[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              elevation: 2,
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _getTypeColor(transaction['type']),
                                  child: Text(
                                    transaction['type'].substring(0, 1),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  '#${transaction['invoiceNumber']} - ${transaction['partyName']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _dateFormat.format(transaction['date']),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              _getTypeColor(transaction['type'])
                                                  .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          transaction['type'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _getTypeColor(
                                                transaction['type']),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: SizedBox(
                                  width: isSmallScreen ? 80 : 100,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '$currencySymbol ${transaction['amount'].toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          transaction['isFullyPaid']
                                              ? 'Paid'
                                              : 'Due: $currencySymbol ${transaction['balanceAmount'].toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: transaction['isFullyPaid']
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        isSmallScreen
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      'Party: ${transaction['partyName']}'),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                      'Payment: ${transaction['paymentType'] ?? 'Not specified'}'),
                                                ],
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      'Party: ${transaction['partyName']}',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      'Payment: ${transaction['paymentType'] ?? 'Not specified'}',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        const Divider(),
                                        const Text(
                                          'Items:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 5),
                                        ...transaction['items']
                                            .map<Widget>((item) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 5),
                                            child: isSmallScreen
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item.itemName ??
                                                            'Unknown Item',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                              '${item.quantity} ${item.unit ?? ''}'),
                                                          Text(
                                                              '$currencySymbol${(item.rate ?? 0).toStringAsFixed(2)}'),
                                                        ],
                                                      ),
                                                      const Divider(
                                                        height: 10,
                                                      ),
                                                    ],
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        flex: 5,
                                                        child: Text(
                                                            item.itemName ??
                                                                'Unknown Item'),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                            '${item.quantity} ${item.unit ?? ''}'),
                                                      ),
                                                      Expanded(
                                                        flex: 3,
                                                        child: Text(
                                                            '$currencySymbol ${(item.rate ?? 0).toStringAsFixed(2)}',
                                                            textAlign: TextAlign
                                                                .right),
                                                      ),
                                                    ],
                                                  ),
                                          );
                                        }).toList(),
                                        const Divider(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Amount Details:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '$currencySymbol ${transaction['amount'].toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(transaction['isReceivable']
                                                ? 'Received:'
                                                : 'Paid:'),
                                            Text(
                                                '$currencySymbol ${(transaction['receivedAmount'] ?? 0).toStringAsFixed(2)}'),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Balance:'),
                                            Text(
                                              '$currencySymbol ${transaction['balanceAmount'].toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: transaction[
                                                            'balanceAmount'] >
                                                        0
                                                    ? Colors.red
                                                    : Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        isSmallScreen
                                            ? Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                alignment:
                                                    WrapAlignment.spaceEvenly,
                                                children: [
                                                  ElevatedButton.icon(
                                                    icon:
                                                        const Icon(Icons.edit),
                                                    label: const Text('Edit'),
                                                    onPressed: () {
                                                      _onEditPressed(
                                                          context, transaction);
                                                    },
                                                  ),
                                                  ElevatedButton.icon(
                                                    icon:
                                                        const Icon(Icons.print),
                                                    label: const Text('Print'),
                                                    onPressed: () async {},
                                                  ),
                                                  ElevatedButton.icon(
                                                    icon: const Icon(
                                                        Icons.delete),
                                                    label: const Text('Delete'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                    onPressed: () async {
                                                      _onDeletePressed(
                                                          context, transaction);
                                                    },
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  ElevatedButton.icon(
                                                    icon:
                                                        const Icon(Icons.edit),
                                                    label: const Text('Edit'),
                                                    onPressed: () {
                                                      _onEditPressed(
                                                          context, transaction);
                                                    },
                                                  ),
                                                  ElevatedButton.icon(
                                                    icon:
                                                        const Icon(Icons.print),
                                                    label: const Text('Print'),
                                                    onPressed: () {
                                                      // Print functionality
                                                    },
                                                  ),
                                                  ElevatedButton.icon(
                                                    icon: const Icon(
                                                        Icons.delete),
                                                    label: const Text('Delete'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                    onPressed: () {
                                                      _onDeletePressed(
                                                          context, transaction);
                                                    },
                                                  ),
                                                ],
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                  // Calendar View
                  CalendarTransactionView(
                    transactions: filteredTransactions,
                    dateFormat: _dateFormat,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: isSmallScreen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Total: ${filteredTransactions.length} transactions'),
                        const SizedBox(height: 4),
                        Text(
                          'Amount: $currencySymbol ${filteredTransactions.fold(0.0, (sum, transaction) => sum + (transaction['amount'] as double)).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Total: ${filteredTransactions.length} transactions'),
                        Text(
                          'Amount: $currencySymbol ${filteredTransactions.fold(0.0, (sum, transaction) => sum + (transaction['amount'] as double)).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _onEditPressed(BuildContext context, Map<String, dynamic> transaction) {
    if (transaction['type'] == 'Purchase' ||
        transaction['type'] == 'Purchase Return' ||
        transaction['type'] == 'Purchase Order') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPurchaseTransactions(
            purchase: transaction['originalObject'],
            onPurchaseDeleted: () {
              // Reload transactions after deletion
              _loadTransactions();
            },
            onPurchaseUpdated: () {
              // Reload transactions after update
              _loadTransactions();
            },
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditSaleTransaction(
            sale: transaction['originalObject'],
            onSaleDeleted: () {
              // Reload transactions after deletion
              _loadTransactions();
            },
            onSaleUpdated: () {
              // Reload transactions after update
              _loadTransactions();
            },
          ),
        ),
      );
    }
  }

  void _onDeletePressed(
      BuildContext context, Map<String, dynamic> transaction) async {
    // Show confirmation dialog for deletion
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              const Text('Are you sure you want to delete this transaction?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Delete the transaction using EditTransactionProvider
      final provider = EditTransactionProvider(
        transaction['originalObject'],
        transaction['type'] == 'Purchase' ||
                transaction['type'] == 'Purchase Return' ||
                transaction['type'] == 'Purchase Order'
            ? TransactionType.purchase
            : TransactionType.sale,
      );

      await provider.onDelete(context, () {
        // Reload transactions after deletion
        _loadTransactions();
      }, itemProvider);
    }
  }
}
