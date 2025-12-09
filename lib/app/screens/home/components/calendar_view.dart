import 'package:account_book/app/screens/home/exports.dart';
import 'package:intl/intl.dart';

class CalendarTransactionView extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final DateFormat dateFormat;

  const CalendarTransactionView({
    super.key,
    required this.transactions,
    required this.dateFormat,
  });

  Map<DateTime, List<Map<String, dynamic>>> _groupTransactionsByDate() {
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};

    for (var transaction in transactions) {
      final DateTime date = DateTime(
        transaction['date'].year,
        transaction['date'].month,
        transaction['date'].day,
      );

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }

      grouped[date]!.add(transaction);
    }

    return grouped;
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Sale':
        return Colors.green.shade700;
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
      case 'proforma':
        return Colors.deepOrange;
      case 'Purchase Order':
        return Colors.brown;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = _groupTransactionsByDate();
    final dates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // Get screen width to determine responsive behavior
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return ListView.builder(
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final dateTransactions = groupedTransactions[date]!;
        final dayTotal = dateTransactions.fold(
            0.0, (sum, transaction) => sum + (transaction['amount'] as double));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16, vertical: 8),
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      dateFormat.format(date),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$currencySymbol ${dayTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ],
              ),
            ),
            ...dateTransactions.map((transaction) {
              return _buildTransactionTile(
                context,
                transaction,
                isSmallScreen,
                currencySymbol,
              );
            }),
            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    Map<String, dynamic> transaction,
    bool isSmallScreen,
    String currencySymbol,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 16,
        vertical: 4,
      ),
      elevation: 1,
      child: InkWell(
        onTap: () =>
            _showTransactionDetails(context, transaction, currencySymbol),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading avatar
              CircleAvatar(
                radius: isSmallScreen ? 16 : 20,
                backgroundColor: _getTypeColor(transaction['type']),
                child: Text(
                  transaction['type'].substring(0, 1),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),

              // Middle content (title and subtitle)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${transaction['invoiceNumber']} - ${transaction['partyName']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 13 : 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 4),
                    Text(
                      transaction['type'],
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing content (amount and payment status)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currencySymbol ${transaction['amount'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: transaction['isFullyPaid']
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction['isFullyPaid'] ? 'Paid' : 'Due',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: transaction['isFullyPaid']
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context,
      Map<String, dynamic> transaction, String currencySymbol) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '#${transaction['invoiceNumber']}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            CircleAvatar(
              backgroundColor: _getTypeColor(transaction['type']),
              radius: isSmallScreen ? 14 : 16,
              child: Text(
                transaction['type'].substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24, vertical: 12),
        content: SizedBox(
          width: screenWidth > 600 ? 500 : double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Type', transaction['type']),
                _buildDetailRow('Party', transaction['partyName']),
                _buildDetailRow('Date', dateFormat.format(transaction['date'])),
                _buildDetailRow('Amount',
                    '$currencySymbol ${transaction['amount'].toStringAsFixed(2)}'),
                _buildDetailRow(
                    'Payment', transaction['paymentType'] ?? 'Not specified'),
                _buildDetailRow('Balance',
                    '$currencySymbol ${transaction['balanceAmount'].toStringAsFixed(2)}'),
                const Divider(height: 24),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...transaction['items'].map<Widget>((item) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.itemName,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.quantity} ${item.unit ?? ''}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '$currencySymbol ${(item.rate ?? 0).toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
