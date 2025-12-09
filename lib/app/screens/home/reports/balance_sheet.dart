import 'package:account_book/app/data/model/item_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:account_book/app/data/model/asset_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/data/model/party_model.dart';
import 'package:account_book/app/data/model/liability_model.dart';

class BalanceSheetScreen extends StatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  BalanceSheetScreenState createState() => BalanceSheetScreenState();
}

class BalanceSheetScreenState extends State<BalanceSheetScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  DateTime? _selectedDate;
  bool _isLoading = false;
  BalanceSheetData? _balanceSheetData;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadBalanceSheetData();
  }

  Future<void> _loadBalanceSheetData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _calculateBalanceSheet();
      setState(() {
        _balanceSheetData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading balance sheet: $e')),
      );
    }
  }

  Future<BalanceSheetData> _calculateBalanceSheet() async {
    final assetBox = Hive.box<AssetModel>('assets');
    final transactionBox = Hive.box<TransactionModel>('transactions');
    final partyBox = Hive.box<PartyModel>('partyBox');
    final liabilityBox = Hive.box<LiabilityModel>('liabilities');
    final itemBox = Hive.box<ItemModel>('itemBox');
    // Calculate assets
    final fixedAssets = assetBox.values
        .where((asset) => asset.category == 'Fixed' && asset.isActive)
        .fold<Map<String, double>>({}, (map, asset) {
      final currentValue = asset.currentValue ?? asset.purchaseValue;
      map[asset.name] = (map[asset.name] ?? 0) + currentValue;
      return map;
    });

    final currentAssets = {
      'Cash': _sumTransactionsByCategory(transactionBox, 'Cash'),
      'Bank': _sumTransactionsByCategory(transactionBox, 'Bank'),
      'Accounts Receivable': _sumPartyBalances(partyBox, isCustomer: true),
      'Inventory': _calculateInventoryValue(itemBox),
    };

    // Calculate liabilities from the liabilities box
    final currentLiabilitiesFromBox = liabilityBox.values
        .where((liability) => liability.category == 'Current')
        .fold<Map<String, double>>({}, (map, liability) {
      // Group by name if needed, or use a more descriptive grouping
      String key = liability.name;
      map[key] = (map[key] ?? 0) + liability.amount;
      return map;
    });

    final longTermLiabilitiesFromBox = liabilityBox.values
        .where((liability) => liability.category == 'Long-term')
        .fold<Map<String, double>>({}, (map, liability) {
      String key = liability.name;
      map[key] = (map[key] ?? 0) + liability.amount;
      return map;
    });

    // Add existing liability calculations
    final currentLiabilities = {
      'Accounts Payable': _sumPartyBalances(partyBox, isCustomer: false),
      'Short-term Loans':
          _sumTransactionsByCategory(transactionBox, 'Short-term Loan'),
      ...currentLiabilitiesFromBox,
    };

    final longTermLiabilities = {
      'Long-term Loans':
          _sumTransactionsByCategory(transactionBox, 'Long-term Loan'),
      ...longTermLiabilitiesFromBox,
    };

    // Calculate totals
    final totalAssets =
        fixedAssets.values.fold(0.0, (sum, value) => sum + value) +
            currentAssets.values.fold(0.0, (sum, value) => sum + value);

    final totalLiabilities =
        currentLiabilities.values.fold(0.0, (sum, value) => sum + value) +
            longTermLiabilities.values.fold(0.0, (sum, value) => sum + value);

    final netWorth = totalAssets - totalLiabilities;

    return BalanceSheetData(
      date: _selectedDate!,
      fixedAssets: fixedAssets,
      currentAssets: currentAssets,
      currentLiabilities: currentLiabilities,
      longTermLiabilities: longTermLiabilities,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      netWorth: netWorth,
    );
  }

  double _sumTransactionsByCategory(
      Box<TransactionModel> box, String category) {
    return box.values
        .where((t) => t.fromAccount == category)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _sumPartyBalances(Box<PartyModel> box, {required bool isCustomer}) {
    return box.values
        .where((party) => party.isCustomer == isCustomer)
        .fold(0.0, (sum, party) => sum + (party.openingBalance ?? 0));
  }

  double _calculateInventoryValue(Box<ItemModel> itemBox) {
    return itemBox.values.fold(0.0, (sum, item) {
      return sum + ((item.stockQuantity ?? 0) * (item.amount ?? 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Balance Sheet'),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _selectDate,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadBalanceSheetData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _balanceSheetData == null
              ? Center(child: Text('No data available'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildBalanceSheet(_balanceSheetData!),
                  ),
                ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadBalanceSheetData();
      });
    }
  }

  Widget _buildBalanceSheet(BalanceSheetData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(data.date),
        SizedBox(height: 20),
        _buildAssetsSection(data),
        SizedBox(height: 20),
        _buildLiabilitiesSection(data),
        SizedBox(height: 20),
        _buildNetWorthSection(data),
        // SizedBox(height: 20),
        // _buildBalanceCheck(data),
      ],
    );
  }

  Widget _buildHeader(DateTime date) {
    return Column(
      children: [
        Text(
          'BALANCE SHEET',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'As on ${DateFormat('dd MMMM yyyy').format(date)}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetsSection(BalanceSheetData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('ASSETS'),
            SizedBox(height: 8),
            _buildSubSectionTitle('Fixed Assets'),
            ..._buildAccountItems(data.fixedAssets),
            _buildSubTotal('Total Fixed Assets',
                data.fixedAssets.values.fold(0.0, (sum, value) => sum + value)),
            SizedBox(height: 12),
            _buildSubSectionTitle('Current Assets'),
            ..._buildAccountItems(data.currentAssets),
            _buildSubTotal(
                'Total Current Assets',
                data.currentAssets.values
                    .fold(0.0, (sum, value) => sum + value)),
            SizedBox(height: 8),
            _buildDivider(),
            _buildTotal('TOTAL ASSETS', data.totalAssets, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildLiabilitiesSection(BalanceSheetData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('LIABILITIES'),
            SizedBox(height: 8),
            _buildSubSectionTitle('Current Liabilities'),
            ..._buildAccountItems(data.currentLiabilities),
            _buildSubTotal(
                'Total Current Liabilities',
                data.currentLiabilities.values
                    .fold(0.0, (sum, value) => sum + value)),
            SizedBox(height: 12),
            _buildSubSectionTitle('Long-term Liabilities'),
            ..._buildAccountItems(data.longTermLiabilities),
            _buildSubTotal(
                'Total Long-term Liabilities',
                data.longTermLiabilities.values
                    .fold(0.0, (sum, value) => sum + value)),
            SizedBox(height: 8),
            _buildDivider(),
            _buildTotal('TOTAL LIABILITIES', data.totalLiabilities, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthSection(BalanceSheetData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('NET WORTH'),
            SizedBox(height: 8),
            _buildTotal('CAPITAL', data.netWorth,
                data.netWorth >= 0 ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildBalanceCheck(BalanceSheetData data) {
    final isBalanced =
        (data.totalAssets - data.totalLiabilities - data.netWorth).abs() < 0.01;
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBalanced ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isBalanced ? Icons.check_circle : Icons.error,
            color: isBalanced ? Colors.green : Colors.red,
          ),
          SizedBox(width: 8),
          Text(
            isBalanced
                ? 'Balance Sheet is Balanced'
                : 'Balance Sheet is Not Balanced',
            style: TextStyle(
              color: isBalanced ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAccountItems(Map<String, double> items) {
    return items.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                entry.key,
                style: TextStyle(fontSize: 14),
              ),
            ),
            Text(
              currencyFormat.format(entry.value),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildSubSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSubTotal(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotal(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(thickness: 1, height: 1);
  }
}

class BalanceSheetData {
  final DateTime date;
  final Map<String, double> fixedAssets;
  final Map<String, double> currentAssets;
  final Map<String, double> currentLiabilities;
  final Map<String, double> longTermLiabilities;
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;

  BalanceSheetData({
    required this.date,
    required this.fixedAssets,
    required this.currentAssets,
    required this.currentLiabilities,
    required this.longTermLiabilities,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
  });
}
