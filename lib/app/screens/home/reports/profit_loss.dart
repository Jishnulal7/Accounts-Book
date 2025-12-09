import 'package:account_book/app/screens/home/exports.dart';
import 'package:account_book/app/screens/home/reports/pl_pdf.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:share_plus/share_plus.dart';

class ProfitAndLossScreen extends StatefulWidget {
  const ProfitAndLossScreen({super.key});

  @override
  ProfitAndLossScreenState createState() => ProfitAndLossScreenState();
}

class ProfitAndLossScreenState extends State<ProfitAndLossScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  DateTimeRange? _selectedDateRange;
  bool _isLoading = true;
  ProfitLossData? _profitLossData;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _fetchProfitLossData();
      setState(() {
        _profitLossData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<ProfitLossData> _fetchProfitLossData() async {
    final transactionBox = Hive.box<TransactionModel>('transactions');
    final saleBox = Hive.box<SaleModel>('saleBox');
    final purchaseBox = Hive.box<PurchaseModel>('purchaseBox');

    final startDate = _selectedDateRange!.start;
    final endDate = _selectedDateRange!.end;

    // Filter transactions by date range
    final transactions = transactionBox.values
        .where((t) =>
            t.date.isAfter(startDate.subtract(Duration(days: 1))) &&
            t.date.isBefore(endDate.add(Duration(days: 1))))
        .toList();

    // Filter sales and purchases by date range
    final sales = saleBox.values
        .where((s) =>
            s.date.isAfter(startDate.subtract(Duration(days: 1))) &&
            s.date.isBefore(endDate.add(Duration(days: 1))))
        .toList();

    final purchases = purchaseBox.values
        .where((p) =>
            p.date.isAfter(startDate.subtract(Duration(days: 1))) &&
            p.date.isBefore(endDate.add(Duration(days: 1))))
        .toList();

    // Calculate opening and closing stock (you'll need to implement these)
    final openingStock = await _calculateOpeningStock(startDate);
    final closingStock = await _calculateClosingStock(endDate);

    // Trading Account Calculations
    final netSales = sales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final netPurchases = purchases.fold(0.0, (sum, p) => sum + p.totalAmount);

    final directExpenses = transactions
        .where((t) =>
            t.transactionType == TransactionType.payment &&
            t.categoryName == 'Direct Expenses')
        .fold(0.0, (sum, t) => sum + t.amount);

    final costOfGoodsSold =
        netPurchases + openingStock - closingStock + directExpenses;
    final grossProfit = netSales - costOfGoodsSold;

    // Profit & Loss Account Calculations
    final indirectIncomes = transactions
        .where((t) =>
            t.transactionType == TransactionType.receipt &&
            t.categoryName == 'Indirect Incomes')
        .fold(0.0, (sum, t) => sum + t.amount);

    final indirectExpenses = transactions
        .where((t) =>
            t.transactionType == TransactionType.payment &&
            t.categoryName == 'Indirect Expenses')
        .fold(0.0, (sum, t) => sum + t.amount);

    final netProfitBeforeTax = grossProfit + indirectIncomes - indirectExpenses;

    return ProfitLossData(
      netSales: netSales,
      netPurchases: netPurchases,
      openingStock: openingStock,
      closingStock: closingStock,
      directExpenses: directExpenses,
      indirectIncomes: indirectIncomes,
      indirectExpenses: indirectExpenses,
      grossProfit: grossProfit,
      netProfitBeforeTax: netProfitBeforeTax,
    );
  }

  Future<double> _calculateOpeningStock(DateTime date) async {
    // Implement your opening stock calculation logic
    return 0.0;
  }

  Future<double> _calculateClosingStock(DateTime date) async {
    // Implement your closing stock calculation logic
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profit & Loss Statement'),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _profitLossData == null
              ? Center(child: Text('No data available'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildDateHeader(),
                        SizedBox(height: 20),
                        _buildTradingAccountSection(),
                        SizedBox(height: 20),
                        _buildProfitAndLossAccountSection(),
                        SizedBox(height: 20),
                        _buildNetProfitSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDateHeader() {
    return Column(
      children: [
        Text(
          'PROFIT & LOSS STATEMENT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'From ${DateFormat('dd-MM-yyyy').format(_selectedDateRange!.start)} '
          'to ${DateFormat('dd-MM-yyyy').format(_selectedDateRange!.end)}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTradingAccountSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('TRADING ACCOUNT'),
            SizedBox(height: 16),

            // Debit Side (Expenses)
            _buildSubSectionHeader('Debit Side'),
            _buildAccountRow(
                'Opening Stock', _profitLossData!.openingStock, false),
            _buildAccountRow('Purchases', _profitLossData!.netPurchases, false),
            _buildAccountRow(
                'Direct Expenses', _profitLossData!.directExpenses, false),
            _buildDivider(),
            _buildTotalRow(
                'Total',
                _profitLossData!.openingStock +
                    _profitLossData!.netPurchases +
                    _profitLossData!.directExpenses,
                false),
            SizedBox(height: 16),

            // Credit Side (Incomes)
            _buildSubSectionHeader('Credit Side'),
            _buildAccountRow('Sales', _profitLossData!.netSales, true),
            _buildAccountRow(
                'Closing Stock', _profitLossData!.closingStock, true),
            _buildDivider(),
            _buildTotalRow(
                'Total',
                _profitLossData!.netSales + _profitLossData!.closingStock,
                true),
            SizedBox(height: 16),

            // Gross Profit/Loss
            _buildGrossProfitRow(_profitLossData!.grossProfit),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitAndLossAccountSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('PROFIT & LOSS ACCOUNT'),
            SizedBox(height: 16),

            // Debit Side (Expenses)
            _buildSubSectionHeader('Debit Side'),
            _buildAccountRow(
                'Indirect Expenses', _profitLossData!.indirectExpenses, false),
            _buildDivider(),
            _buildTotalRow('Total', _profitLossData!.indirectExpenses, false),
            SizedBox(height: 16),

            // Credit Side (Incomes)
            _buildSubSectionHeader('Credit Side'),
            _buildAccountRow(
                'Gross Profit b/d',
                _profitLossData!.grossProfit > 0
                    ? _profitLossData!.grossProfit
                    : 0,
                true),
            _buildAccountRow(
                'Indirect Incomes', _profitLossData!.indirectIncomes, true),
            _buildDivider(),
            _buildTotalRow(
                'Total',
                (_profitLossData!.grossProfit > 0
                        ? _profitLossData!.grossProfit
                        : 0) +
                    _profitLossData!.indirectIncomes,
                true),
          ],
        ),
      ),
    );
  }

  Widget _buildNetProfitSection() {
    return Card(
      elevation: 3,
      color: _profitLossData!.netProfitBeforeTax >= 0
          ? Colors.green[50]
          : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _profitLossData!.netProfitBeforeTax >= 0
                  ? 'NET PROFIT FOR THE PERIOD'
                  : 'NET LOSS FOR THE PERIOD',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              currencyFormat.format(_profitLossData!.netProfitBeforeTax.abs()),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _profitLossData!.netProfitBeforeTax >= 0
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAccountRow(String label, double amount, bool isCredit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              color: isCredit ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, bool isCredit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCredit ? Colors.green : Colors.red,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrossProfitRow(double amount) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            amount >= 0 ? 'GROSS PROFIT' : 'GROSS LOSS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            currencyFormat.format(amount.abs()),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: amount >= 0 ? Colors.green : Colors.red,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(thickness: 1, height: 1);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        _loadData();
      });
    }
  }

  // Update the _exportToPdf method in your ProfitAndLossScreenState class
  Future<void> _exportToPdf() async {
    if (_profitLossData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to export')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...')),
    );

    // try {
    final pdfService = ProfitLossPdfService();
    final pdfPath = await pdfService.generatePdf(
      title: 'Profit & Loss Statement',
      startDate: _selectedDateRange!.start,
      endDate: _selectedDateRange!.end,
      data: _profitLossData!,
    );

    if (!mounted) return;

    // Navigate to PDF viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfitLossPdfViewer(pdfPath: pdfPath),
      ),
    );
    // } catch (e) {
    if (!mounted) return;

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Error generating PDF: $e')),
    // );
    // }
  }
}

class ProfitLossPdfViewer extends StatelessWidget {
  final String pdfPath;
  final PdfViewerController _pdfViewerController = PdfViewerController();

  ProfitLossPdfViewer({
    super.key,
    required this.pdfPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit & Loss Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePdf(),
          ),
        ],
      ),
      body: SfPdfViewer.file(
        File(pdfPath),
        controller: _pdfViewerController,
      ),
    );
  }

  void _sharePdf() async {
    await Share.shareXFiles(
      [XFile(pdfPath)],
      text: 'Profit & Loss Report',
      subject: 'Profit & Loss Report',
    );
  }
}
