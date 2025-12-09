import 'package:account_book/app/data/model/asset_model.dart';
import 'package:account_book/app/data/model/item_model.dart';
import 'package:account_book/app/data/model/liability_model.dart';
import 'package:account_book/app/data/model/purchase_model.dart';
import 'package:account_book/app/data/model/sale_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:account_book/app/data/model/transaction_model.dart';

class TrialBalanceScreen extends StatefulWidget {
  const TrialBalanceScreen({super.key});

  @override
  TrialBalanceScreenState createState() => TrialBalanceScreenState();
}

class TrialBalanceScreenState extends State<TrialBalanceScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  DateTime? _selectedDate;
  bool _isLoading = false;
  List<TrialBalanceItem> _assets = [];
  List<TrialBalanceItem> _liabilities = [];
  List<TrialBalanceItem> _income = [];
  List<TrialBalanceItem> _expenses = [];
  double _totalDebit = 0;
  double _totalCredit = 0;
  double _inventoryValue = 0;
  double _totalSales = 0;
  double _totalPurchases = 0;

  // Define account classifications (you can expand this)
  final Map<String, String> _accountTypes = {
    'Cash': 'Asset',
    'Bank': 'Asset',
    'Accounts Receivable': 'Asset',
    'Inventory': 'Asset',
    'Fixed Assets': 'Asset',
    'Accounts Payable': 'Liability',
    'Loans Payable': 'Liability',
    'Sales': 'Income',
    'Purchase': 'Expense',
    'Salary': 'Expense',
    'Rent': 'Expense',
    'Utilities': 'Expense',
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadTrialBalance();
  }

  Future<void> _loadTrialBalance() async {
    setState(() => _isLoading = true);

    try {
      final transactionBox = Hive.box<TransactionModel>('transactions');
      final saleBox = Hive.box<SaleModel>('saleBox');
      final purchaseBox = Hive.box<PurchaseModel>('purchaseBox');
      final itemBox = Hive.box<ItemModel>('itemBox');
      final liabilityBox = Hive.box<LiabilityModel>('liabilities');
      final assetBox = Hive.box<AssetModel>('assets'); // Add this line

      // 1. Calculate inventory value
      _inventoryValue = itemBox.values.fold(0.0, (sum, item) {
        return sum + ((item.stockQuantity ?? 0) * (item.amount ?? 0));
      });

      // 2. Calculate total sales and purchases for the period
      _totalSales = saleBox.values
          .where((s) => s.date.isBefore(_selectedDate!.add(Duration(days: 1))))
          .fold(0.0, (sum, sale) => sum + sale.totalAmount);

      _totalPurchases = purchaseBox.values
          .where((p) => p.date.isBefore(_selectedDate!.add(Duration(days: 1))))
          .fold(0.0, (sum, purchase) => sum + purchase.totalAmount);

      // 3. Process regular transactions
      final transactions = transactionBox.values
          .where((t) => t.date.isBefore(_selectedDate!.add(Duration(days: 1))))
          .toList();

      final accountBalances = <String, TrialBalanceItem>{};

      // Add inventory account
      accountBalances['Inventory'] = TrialBalanceItem(
        accountName: 'Inventory',
        accountType: 'Asset',
        debit: _inventoryValue,
        credit: 0,
      );

      // Add Fixed Assets account from AssetModel
      final fixedAssets = assetBox.values
          .where((asset) => asset.isActive && asset.category == 'Fixed')
          .fold(
              0.0,
              (sum, asset) =>
                  sum + (asset.currentValue ?? asset.purchaseValue));

      accountBalances['Fixed Assets'] = TrialBalanceItem(
        accountName: 'Fixed Assets',
        accountType: 'Asset',
        debit: fixedAssets,
        credit: 0,
      );

      // Add Current Assets account from AssetModel
      final currentAssets = assetBox.values
          .where((asset) => asset.isActive && asset.category == 'Current')
          .fold(
              0.0,
              (sum, asset) =>
                  sum + (asset.currentValue ?? asset.purchaseValue));

      accountBalances['Current Assets'] = TrialBalanceItem(
        accountName: 'Current Assets',
        accountType: 'Asset',
        debit: currentAssets,
        credit: 0,
      );

      // Add Accumulated Depreciation account
      final accumulatedDepreciation = assetBox.values
          .where((asset) => asset.isActive && asset.depreciationRate != null)
          .fold(0.0, (sum, asset) {
        final currentValue = asset.currentValue ?? asset.purchaseValue;
        return sum + (asset.purchaseValue - currentValue);
      });

      accountBalances['Accumulated Depreciation'] = TrialBalanceItem(
        accountName: 'Accumulated Depreciation',
        accountType: 'Asset',
        debit: 0,
        credit: accumulatedDepreciation,
      );

      // Add sales account
      accountBalances['Sales'] = TrialBalanceItem(
        accountName: 'Sales',
        accountType: 'Income',
        debit: 0,
        credit: _totalSales,
      );

      // Add purchases account
      accountBalances['Purchases'] = TrialBalanceItem(
        accountName: 'Purchases',
        accountType: 'Expense',
        debit: _totalPurchases,
        credit: 0,
      );

      // Process liabilities
      final liabilities = liabilityBox.values
          .where((l) => l.date.isBefore(_selectedDate!.add(Duration(days: 1))))
          .toList();

      // Group liabilities by category
      final Map<String, double> liabilityTotals = {
        'Current Liabilities': 0.0,
        'Long-term Liabilities': 0.0,
      };

      for (final liability in liabilities) {
        final accountName = liability.category == 'Current'
            ? 'Current Liabilities'
            : 'Long-term Liabilities';
        liabilityTotals[accountName] =
            (liabilityTotals[accountName] ?? 0) + liability.amount;
      }

      // Add liability accounts to the trial balance
      liabilityTotals.forEach((accountName, amount) {
        accountBalances[accountName] = TrialBalanceItem(
          accountName: accountName,
          accountType: 'Liability',
          debit: 0,
          credit: amount,
        );
      });

      // Process regular transactions
      for (final t in transactions) {
        final fromType = _accountTypes[t.fromAccount] ?? 'Expense';
        final toType = _accountTypes[t.toAccount] ?? 'Income';

        accountBalances.putIfAbsent(
            t.fromAccount,
            () => TrialBalanceItem(
                  accountName: t.fromAccount,
                  accountType: fromType,
                  debit: 0,
                  credit: 0,
                ));

        accountBalances.putIfAbsent(
            t.toAccount,
            () => TrialBalanceItem(
                  accountName: t.toAccount,
                  accountType: toType,
                  debit: 0,
                  credit: 0,
                ));

        if (t.transactionType == TransactionType.payment) {
          accountBalances[t.fromAccount]!.debit += t.amount;
          accountBalances[t.toAccount]!.credit += t.amount;
        } else if (t.transactionType == TransactionType.receipt) {
          accountBalances[t.fromAccount]!.debit += t.amount;
          accountBalances[t.toAccount]!.credit += t.amount;
        } else if (t.transactionType == TransactionType.transfer) {
          accountBalances[t.fromAccount]!.credit += t.amount;
          accountBalances[t.toAccount]!.debit += t.amount;
        }
      }

      // Categorize accounts
      _assets = [];
      _liabilities = [];
      _income = [];
      _expenses = [];
      _totalDebit = 0;
      _totalCredit = 0;

      accountBalances.forEach((name, item) {
        if (item.debit > 0 || item.credit > 0) {
          switch (item.accountType) {
            case 'Asset':
              _assets.add(item);
              _totalDebit += item.debit;
              _totalCredit += item.credit;
              break;
            case 'Liability':
              _liabilities.add(item);
              _totalDebit += item.debit;
              _totalCredit += item.credit;
              break;
            case 'Income':
              _income.add(item);
              _totalDebit += item.debit;
              _totalCredit += item.credit;
              break;
            case 'Expense':
              _expenses.add(item);
              _totalDebit += item.debit;
              _totalCredit += item.credit;
              break;
          }
        }
      });

      // Sort each category
      _assets.sort((a, b) => a.accountName.compareTo(b.accountName));
      _liabilities.sort((a, b) => a.accountName.compareTo(b.accountName));
      _income.sort((a, b) => a.accountName.compareTo(b.accountName));
      _expenses.sort((a, b) => a.accountName.compareTo(b.accountName));

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trial balance: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trial Balance'),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _selectDate,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTrialBalance,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildHeader(),
                    SizedBox(height: 20),
                    _buildInventorySummary(),
                    SizedBox(height: 20),
                    _buildSalesPurchaseSummary(),
                    SizedBox(height: 20),
                    _buildCategorySection('Assets', _assets),
                    SizedBox(height: 20),
                    _buildCategorySection('Liabilities', _liabilities),
                    SizedBox(height: 20),
                    _buildCategorySection('Income', _income),
                    SizedBox(height: 20),
                    _buildCategorySection('Expenses', _expenses),
                    SizedBox(height: 20),
                    _buildTotalsSection(),
                    // SizedBox(height: 20),
                    // _buildBalanceCheck(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'TRIAL BALANCE',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'As on ${DateFormat('dd-MM-yyyy').format(_selectedDate!)}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String title, List<TrialBalanceItem> items) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'No $title accounts',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  columns: [
                    DataColumn(label: Text('Account')),
                    DataColumn(
                      label: Text('Debit (₹)'),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('Credit (₹)'),
                      numeric: true,
                    ),
                  ],
                  rows: items
                      .map((item) => DataRow(
                            cells: [
                              DataCell(Text(item.accountName)),
                              DataCell(Text(
                                item.debit > 0
                                    ? currencyFormat.format(item.debit)
                                    : '-',
                                style: TextStyle(color: Colors.red),
                              )),
                              DataCell(Text(
                                item.credit > 0
                                    ? currencyFormat.format(item.credit)
                                    : '-',
                                style: TextStyle(color: Colors.green),
                              )),
                            ],
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'INVENTORY SUMMARY',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Closing Stock Value:'),
                Text(
                  currencyFormat.format(_inventoryValue),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesPurchaseSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'SALES & PURCHASES',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Sales:'),
                Text(
                  currencyFormat.format(_totalSales),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Purchases:'),
                Text(
                  currencyFormat.format(_totalPurchases),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Card(
      elevation: 2,
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: DataTable(
          columnSpacing: 24,
          columns: [
            DataColumn(
                label: Text('Total',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black))),
            DataColumn(
              label: Text('Debit (₹)', style: TextStyle(color: Colors.black)),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Credit (₹),',
                style: TextStyle(color: Colors.black),
              ),
              numeric: true,
            ),
          ],
          rows: [
            DataRow(
              cells: [
                DataCell(SizedBox()),
                DataCell(Text(
                  currencyFormat.format(_totalDebit),
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                DataCell(Text(
                  currencyFormat.format(_totalCredit),
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildBalanceCheck() {
    final isBalanced = (_totalDebit - _totalCredit).abs() < 0.01;
    return Container(
      padding: EdgeInsets.all(16),
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
                ? 'Trial Balance is Matched'
                : 'Trial Balance Does Not Match',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isBalanced ? Colors.green : Colors.red,
            ),
          ),
          if (!isBalanced)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                'Difference: ${currencyFormat.format((_totalDebit - _totalCredit).abs())}',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate!,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadTrialBalance();
      });
    }
  }
}

class TrialBalanceItem {
  final String accountName;
  final String accountType;
  double debit;
  double credit;

  TrialBalanceItem({
    required this.accountName,
    required this.accountType,
    required this.debit,
    required this.credit,
  });
}
