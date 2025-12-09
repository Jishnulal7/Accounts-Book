import 'package:account_book/app/providers/currency_provider.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:account_book/app/screens/items/exports.dart';

class ItemTransactions extends StatefulWidget {
  final String itemId;
  final String itemName;

  const ItemTransactions({
    super.key,
    required this.itemId,
    required this.itemName,
  });

  @override 
  State<ItemTransactions> createState() => _ItemTransactionsState();
}

class _ItemTransactionsState extends State<ItemTransactions> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final provider = Provider.of<ItemProvider>(context, listen: false);

      // Make sure boxes are opened before trying to get transactions
      if (!Hive.isBoxOpen('purchaseBox')) {
        await Hive.openBox<PurchaseModel>('purchaseBox');
      }
      if (!Hive.isBoxOpen('saleBox')) {
        await Hive.openBox<SaleModel>('saleBox');
      }

      final transactions = await provider.getItemTransactions(widget.itemId);

      debugPrint('Item ID: ${widget.itemId}');
      debugPrint('Item Name: ${widget.itemName}');
      debugPrint('Fetched ${transactions.length} transactions');

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Consumer<ItemProvider>(
      builder: (context, provider, _) {
        final item = provider.item;
        final openingStock = provider.openingStocks[widget.itemId] ?? 0;

        if (_isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }

        if (_transactions.isEmpty) {
          return _buildEmptyState();
        }

        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildOpeningStockCard(item, openingStock),
                const SizedBox(height: 16),
                _buildTransactionsList(item, _transactions, currencySymbol),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Transactions Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction history will appear here',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningStockCard(dynamic item, num openingStock) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(8),
          title: Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'Opening Stock',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          subtitle: item.date != null
              ? Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(item.date!),
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ],
                )
              : const Text('No Date'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              '$openingStock ${item.unit ?? ''}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(dynamic item,
      List<Map<String, dynamic>> transactions, String currencySymbol) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isPurchase =
            transaction['transactionType'] == PurchaseType.purchase;
        final transactionColor = isPurchase ? Colors.green : Colors.red;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPurchase
                                ? Icons.arrow_circle_down_outlined
                                : Icons.arrow_circle_up_outlined,
                            color: transactionColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isPurchase
                                  ? '${transaction['type'].toString().toDisplayText()} from ${transaction['partyName']}'
                                  : '${transaction['type'].toString().toDisplayText()} to ${transaction['partyName']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy')
                                .format(transaction['date']),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: transactionColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${isPurchase ? '+' : '-'}${transaction['quantity']} ${item.unit ?? ''}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: transactionColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$currencySymbol ${transaction['rate'].toStringAsFixed(2)}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension TransactionTypeFormatter on String {
  String toDisplayText() {
    // Handle special cases first
    if (this == 'purchaseReturn') return 'Purchase Return';
    if (this == 'saleReturn') return 'Sale Return';
    if (this == 'purchase') return 'Purchase';
    if (this == 'sale') return 'Sale';
    if (this == 'purchaseReturn') return 'Purchase Return';
    if (this == 'purchaseOrder') return 'Purchase Order';
    if (this == 'debitNote') return 'Debit Note';
    if (this == 'creditNote') return 'Credit Note';
    if (this == 'estimation') return 'Estimate';
    if (this == 'deliveryChallan') return 'Delivery Challan';

    // For any other cases, split by camel case and capitalize first letter
    final words = replaceAllMapped(
        RegExp(r'(?<=[a-z])[A-Z]'), (match) => ' ${match.group(0)}');
    return words[0].toUpperCase() + words.substring(1);
  }
}
