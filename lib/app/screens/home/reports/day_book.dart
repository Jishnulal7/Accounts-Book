import 'package:account_book/app/providers/day_book_provider.dart';
import 'package:account_book/app/screens/home/exports.dart';
import 'package:intl/intl.dart';

class DayBookScreen extends StatelessWidget {
  const DayBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DayBookProvider(),
      child: const DayBookView(),
    );
  }
}

class DayBookView extends StatefulWidget {
  const DayBookView({super.key});

  @override
  State<DayBookView> createState() => _DayBookViewState();
}

class _DayBookViewState extends State<DayBookView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DayBookProvider>(context);
    final transactions = provider.getDayTransactions();
    final totalIncome = provider.getTotalIncome();
    final totalExpense = provider.getTotalExpense();
    final netAmount = provider.getNetAmount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: provider.selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (picked != null && picked != provider.selectedDate) {
                provider.setSelectedDate(picked);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date and Summary Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy')
                      .format(provider.selectedDate),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SummaryCard(
                      title: 'Income',
                      amount: totalIncome,
                      icon: Icons.arrow_upward,
                      color: Colors.green,
                    ),
                    SummaryCard(
                      title: 'Expense',
                      amount: totalExpense,
                      icon: Icons.arrow_downward,
                      color: Colors.red,
                    ),
                    SummaryCard(
                      title: 'Net',
                      amount: netAmount,
                      icon: Icons.account_balance,
                      color: netAmount >= 0 ? Colors.blue : Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by party name or invoice number',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                provider.setSearchQuery(value);
              },
            ),
          ),

          // Transactions List
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Text(
                      'No transactions for this date',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return TransactionData(transaction: transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.currency(
                symbol: '$currencySymbol ',
                decimalDigits: 2,
              ).format(amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionData extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionData({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    final isIncome = transaction['type'] == 'Sale';
    final statusColor = transaction['isPaid'] ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          '${transaction['partyName']} - ${transaction['invoiceNumber']}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${transaction['type']} - ${transaction['subType']}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              DateFormat('h:mm a').format(transaction['date']),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (transaction['paymentType'] != null)
              Text(
                'Payment: ${transaction['paymentType']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormat.currency(
                symbol: '$currencySymbol ',
                decimalDigits: 2,
              ).format(transaction['amount']),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transaction['isPaid']
                    ? 'Paid'
                    : 'Balance: $currencySymbol ${transaction['balanceAmount']}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                    ),
              ),
            ),
          ],
        ),
        onTap: () {
          // Handle transaction tap - could show details dialog or navigate to detail screen
        },
      ),
    );
  }
}
