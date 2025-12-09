import 'package:account_book/app/screens/home/exports.dart';
import 'package:hive_ce/hive.dart';


class DayBookProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  late Box<PurchaseModel> _purchaseBox;
  late Box<SaleModel> _saleBox;
  String _searchQuery = '';
  
  DateTime get selectedDate => _selectedDate;
  String get searchQuery => _searchQuery;
  
  DayBookProvider() {
    _purchaseBox = Hive.box<PurchaseModel>('purchaseBox');
    _saleBox = Hive.box<SaleModel>('saleBox');
  }
  
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
  
  List<Map<String, dynamic>> getDayTransactions() {
    List<Map<String, dynamic>> transactions = [];

    // Add purchases
    for (var purchase in _purchaseBox.values) {
      if (isSameDay(purchase.date, _selectedDate)) {
        transactions.add({
          'type': 'Purchase',
          'subType': purchase.type.toString().split('.').last,
          'amount': purchase.totalAmount,
          'partyName': purchase.partyName,
          'invoiceNumber': purchase.invoiceNumber,
          'date': purchase.date,
          'paymentType': purchase.paymentType,
          'isPaid': purchase.isFullyPaid,
          'balanceAmount': purchase.balanceAmount,
        });
      }
    }

    // Add sales
    for (var sale in _saleBox.values) {
      if (isSameDay(sale.date, _selectedDate)) {
        transactions.add({
          'type': 'Sale',
          'subType': sale.type.toString().split('.').last,
          'amount': sale.totalAmount,
          'partyName': sale.partyName,
          'invoiceNumber': sale.invoiceNumber,
          'date': sale.date,
          'paymentType': sale.paymentType,
          'isPaid': sale.isFullyPaid,
          'balanceAmount': sale.balanceAmount,
        });
      }
    }

    // Filter based on search query
    if (_searchQuery.isNotEmpty) {
      transactions = transactions.where((transaction) {
        return transaction['partyName']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            transaction['invoiceNumber']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by date and time
    transactions.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return transactions;
  }
  
  double getTotalIncome() {
    return getDayTransactions()
        .where((t) => t['type'] == 'Sale')
        .fold(0.0, (sum, t) => sum + (t['amount'] as double));
  }

  double getTotalExpense() {
    return getDayTransactions()
        .where((t) => t['type'] == 'Purchase')
        .fold(0.0, (sum, t) => sum + (t['amount'] as double));
  }
  
  double getNetAmount() {
    return getTotalIncome() - getTotalExpense();
  }
}