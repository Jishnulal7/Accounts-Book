import 'package:account_book/app/data/helpers/enums/transaction_view.dart';
import 'package:account_book/app/screens/home/exports.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:intl/intl.dart';

class CashbookScreen extends StatefulWidget {
  const CashbookScreen({super.key});

  @override
  State<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  TransactionView _currentView = TransactionView.daily;
  DateTime _selectedDate = DateTime.now();
  final _purchaseBox = Hive.box<PurchaseModel>('purchaseBox');
  final _salesBox = Hive.box<SaleModel>('saleBox');

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Transactions'),
        actions: [
          PopupMenuButton<TransactionView>(
            initialValue: _currentView,
            onSelected: (TransactionView view) {
              setState(() {
                _currentView = view;
              });
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<TransactionView>>[
              const PopupMenuItem<TransactionView>(
                value: TransactionView.daily,
                child: Text('Daily View'),
              ),
              const PopupMenuItem<TransactionView>(
                value: TransactionView.monthly,
                child: Text('Monthly View'),
              ),
              const PopupMenuItem<TransactionView>(
                value: TransactionView.yearly,
                child: Text('Yearly View'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: _buildTransactionList(currencySymbol),
          ),
          _buildSummaryCard(currencySymbol),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    String dateFormat;
    switch (_currentView) {
      case TransactionView.daily:
        dateFormat = 'dd MMM yyyy';
        break;
      case TransactionView.monthly:
        dateFormat = 'MMMM yyyy';
        break;
      case TransactionView.yearly:
        dateFormat = 'yyyy';
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeDate(-1),
          ),
          TextButton(
            onPressed: () => _selectDate(),
            child: Text(
              DateFormat(dateFormat).format(_selectedDate),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(String currencySymbol) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<PurchaseModel>('purchaseBox').listenable(),
      builder: (context, Box<PurchaseModel> purchaseBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box<SaleModel>('saleBox').listenable(),
          builder: (context, Box<SaleModel> salesBox, _) {
            final transactions = _getFilteredTransactions();

            if (transactions.isEmpty) {
              return const Center(
                child: Text('No cash transactions found for this period'),
              );
            }

            return ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final bool isSale = transaction is SaleModel;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSale ? Colors.green : Colors.red,
                      child: Icon(
                        isSale ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(transaction.partyName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            DateFormat('dd MMM yyyy').format(transaction.date)),
                        Text(
                          'Invoice: ${transaction.invoiceNumber}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$currencySymbol ${transaction.totalAmount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          isSale ? 'Cash Sale' : 'Cash Purchase',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(String currencySymbol) {
    final transactions = _getFilteredTransactions();
    double totalSales = 0;
    double totalPurchases = 0;

    for (final transaction in transactions) {
      if (transaction is SaleModel) {
        totalSales += transaction.totalAmount;
      } else if (transaction is PurchaseModel) {
        totalPurchases += transaction.totalAmount;
      }
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Cash Transactions Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                    'Cash Sales', totalSales, Colors.green, currencySymbol),
                _buildSummaryItem('Cash Purchases', totalPurchases, Colors.red,
                    currencySymbol),
                _buildSummaryItem(
                    'Net Cash Flow',
                    totalSales - totalPurchases,
                    (totalSales - totalPurchases) >= 0
                        ? Colors.green
                        : Colors.red,
                    currencySymbol),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, double amount, Color color, String currencySymbol) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '$currencySymbol ${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  List<dynamic> _getFilteredTransactions() {
    List<dynamic> transactions = [];

    void addTransactions(DateTime startDate, DateTime endDate) {
      // Filter purchases for cash transactions only
      transactions.addAll(_purchaseBox.values.where((purchase) =>
          purchase.date
              .isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          purchase.date.isBefore(endDate.add(const Duration(seconds: 1))) &&
          purchase.paymentType?.toLowerCase() == 'cash'));

      // Filter sales for cash transactions only
      transactions.addAll(_salesBox.values.where((sale) =>
          sale.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          sale.date.isBefore(endDate.add(const Duration(seconds: 1))) &&
          sale.paymentType?.toLowerCase() == 'cash'));
    }

    switch (_currentView) {
      case TransactionView.daily:
        final startDate = DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day);
        final endDate = startDate.add(const Duration(days: 1));
        addTransactions(startDate, endDate);
        break;

      case TransactionView.monthly:
        final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final endDate =
            DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
        addTransactions(startDate, endDate);
        break;

      case TransactionView.yearly:
        final startDate = DateTime(_selectedDate.year, 1, 1);
        final endDate = DateTime(_selectedDate.year, 12, 31);
        addTransactions(startDate, endDate);
        break;
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  void _changeDate(int difference) {
    setState(() {
      switch (_currentView) {
        case TransactionView.daily:
          _selectedDate = _selectedDate.add(Duration(days: difference));
          break;
        case TransactionView.monthly:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + difference,
            _selectedDate.day,
          );
          break;
        case TransactionView.yearly:
          _selectedDate = DateTime(
            _selectedDate.year + difference,
            _selectedDate.month,
            _selectedDate.day,
          );
          break;
      }
    });
  }

  Future<void> _selectDate() async {
    switch (_currentView) {
      case TransactionView.daily:
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
        break;

      case TransactionView.monthly:
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialDatePickerMode: DatePickerMode.year,
        );
        if (picked != null) {
          setState(() => _selectedDate = DateTime(picked.year, picked.month));
        }
        break;

      case TransactionView.yearly:
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialDatePickerMode: DatePickerMode.year,
        );
        if (picked != null) {
          setState(() => _selectedDate = DateTime(picked.year));
        }
        break;
    }
  }
}
