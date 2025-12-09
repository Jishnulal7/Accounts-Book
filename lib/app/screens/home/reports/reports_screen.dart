import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:account_book/app/screens/home/reports/reports_model.dart';
import 'package:account_book/app/screens/home/exports.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  ReportsScreenState createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportsService _reportsService = ReportsService();
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final TooltipBehavior _tooltipBehavior = TooltipBehavior(enable: true);
  // Add unique keys for each FutureBuilder
  Key _financialReportKey = UniqueKey();
  Key _salesReportKey = UniqueKey();
  Key _purchaseReportKey = UniqueKey();
  Key _inventoryReportKey = UniqueKey();
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Default to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: theme.colorScheme.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.assessment), text: 'Financial'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Sales'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Purchase'),
            Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Select date range',
            onPressed: _showDateRangePicker,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateRangeHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFinancialReport(currencySymbol),
                _buildSalesReport(currencySymbol),
                _buildPurchaseReport(currencySymbol),
                _buildInventoryReport(currencySymbol),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Date Range:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          TextButton(
            onPressed: _showDateRangePicker,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Row(
              children: [
                Text(
                  '${_dateFormat.format(_startDate!)} - ${_dateFormat.format(_endDate!)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.edit,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;

        // Forcing rebuilds by creating new unique keys for the FutureBuilder widgets
        _financialReportKey = UniqueKey();
        _salesReportKey = UniqueKey();
        _purchaseReportKey = UniqueKey();
        _inventoryReportKey = UniqueKey();
      });
    }
  }

  Widget _buildFinancialReport(String currencySymbol) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportsService.getFinancialSummary(
        startDate: _startDate,
        endDate: _endDate,
      ),
      key: _financialReportKey, // Use the unique key here
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No financial data available'));
        }

        final data = snapshot.data!;

        // Safely handle financialTrend data which might be null
        final financialTrendData = data['financialTrend'];
        List<FinancialData> financialTrend = [];

        if (financialTrendData != null &&
            financialTrendData is Map<DateTime, double>) {
          financialTrend = financialTrendData.entries
              .map((e) => FinancialData(e.key, e.value))
              .toList();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryCard(
                title: 'Financial Overview',
                icon: Icons.pie_chart,
                items: [
                  ReportItem(
                    'Total Revenue',
                    data['totalRevenue'] ?? 0,
                    isPositive: true,
                  ),
                  ReportItem(
                    'Total Expenses',
                    data['totalExpenses'] ?? 0,
                    isPositive: false,
                  ),
                  ReportItem(
                    'Gross Profit',
                    data['grossProfit'] ?? 0,
                    isPositive: (data['grossProfit'] ?? 0) >= 0,
                  ),
                ],
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                title: 'Receivables & Payables',
                icon: Icons.credit_card,
                items: [
                  ReportItem(
                    'Pending Receivables',
                    data['pendingReceivables'] ?? 0,
                  ),
                  ReportItem(
                    'Pending Payables',
                    data['pendingPayables'] ?? 0,
                  ),
                  ReportItem(
                    'Customer Credit',
                    data['totalCustomerCredit'] ?? 0,
                  ),
                ],
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: 16),
              if (financialTrend.isNotEmpty)
                _buildFinancialTrendChart(
                  title: 'Financial Trend',
                  data: financialTrend,
                  currencySymbol: currencySymbol,
                )
              else
                _buildNoDataPlaceholder('No trend data available'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoDataPlaceholder(String message) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesReport(String currencySymbol) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportsService.getSalesAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      ),
      key: _salesReportKey, // Use the unique key here
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No sales data available'));
        }

        final data = snapshot.data!;

        // Initialize with empty lists if data is null
        final salesByDateData = data['salesByDate'] ?? {};
        final topProductsData = data['topProducts'] ?? [];

        // Properly handle the salesByDate data
        final salesByDate = (salesByDateData as Map<DateTime, List<SaleModel>>)
            .entries
            .map((e) {
          // Calculate total amount for each date
          final totalAmount =
              e.value.fold<double>(0, (sum, sale) => sum + (sale.totalAmount));
          return SalesData(e.key, totalAmount);
        }).toList();

        // Handle top products data
        final topProducts = (topProductsData as List<dynamic>)
            .map((e) => ProductData(
                  e['name'] ?? 'Unknown',
                  e['quantity'] ?? 0,
                  e['amount'] ?? 0.0,
                ))
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryCard(
                title: 'Sales Overview',
                icon: Icons.trending_up,
                items: [
                  ReportItem('Total Sales', data['totalSales'] ?? 0,
                      isAmount: false),
                  ReportItem('Total Amount', data['totalAmount'] ?? 0,
                      isPositive: true),
                  ReportItem('Received Amount', data['receivedAmount'] ?? 0,
                      isPositive: true),
                  ReportItem('Pending Amount', data['pendingAmount'] ?? 0),
                ],
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: 16),
              if (salesByDate.isNotEmpty)
                _buildSalesBarChart(
                  title: 'Sales by Date',
                  data: salesByDate,
                  currencySymbol: currencySymbol,
                )
              else
                _buildNoDataPlaceholder(
                    'No sales data available for the selected period'),
              const SizedBox(height: 16),
              if (topProducts.isNotEmpty)
                _buildTopProductsChart(
                  title: 'Top Selling Products',
                  data: topProducts,
                  currencySymbol: currencySymbol,
                )
              else
                _buildNoDataPlaceholder('No top products data available'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPurchaseReport(String currencySymbol) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportsService.getPurchaseAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      ),
      key: _purchaseReportKey, // Use the unique key here
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No purchase data available'));
        }

        final data = snapshot.data!;

        // Initialize with empty maps/lists if data is null
        final purchasesByDateData = data['purchasesByDate'] ?? {};
        final topSuppliersData = data['topSuppliers'] ?? [];

        // Process purchase data - assuming purchasesByDateData is Map<DateTime, List<PurchaseModel>>
        final purchasesByDate = (purchasesByDateData as Map<dynamic, dynamic>)
            .entries
            .where((entry) => entry.key is DateTime) // Filter valid dates
            .map((e) {
          // Calculate total amount for all purchases on this date
          final purchases = e.value is List<PurchaseModel>
              ? e.value as List<PurchaseModel>
              : <PurchaseModel>[];

          final totalAmount = purchases.fold<double>(
              0, (sum, purchase) => sum + (purchase.totalAmount));

          return PurchaseData(e.key as DateTime, totalAmount);
        }).toList()
          ..sort((a, b) => a.date.compareTo(b.date)); // Sort by date

        // Handle top suppliers data
        final topSuppliers = (topSuppliersData as List<dynamic>)
            .map((e) => SupplierData(
                  e['name'] ?? 'Unknown Supplier',
                  (e['count'] as num?)?.toInt() ?? 0,
                  (e['amount'] as num?)?.toDouble() ?? 0.0,
                ))
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryCard(
                title: 'Purchase Overview',
                icon: Icons.trending_down,
                items: [
                  ReportItem('Total Purchases', data['totalPurchases'] ?? 0,
                      isAmount: false),
                  ReportItem('Total Amount', data['totalAmount'] ?? 0,
                      isPositive: false),
                  ReportItem('Paid Amount', data['paidAmount'] ?? 0,
                      isPositive: true),
                  ReportItem('Pending Amount', data['pendingAmount'] ?? 0),
                ],
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: 16),
              if (purchasesByDate.isNotEmpty)
                _buildPurchaseBarChart(
                  title: 'Purchases by Date',
                  data: purchasesByDate,
                  currencySymbol: currencySymbol,
                )
              else
                _buildNoDataPlaceholder(
                    'No purchase data available for the selected period'),
              const SizedBox(height: 16),
              if (topSuppliers.isNotEmpty)
                _buildTopSuppliersChart(
                  title: 'Top Suppliers',
                  data: topSuppliers,
                  currencySymbol: currencySymbol,
                )
              else
                _buildNoDataPlaceholder('No supplier data available'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryReport(String currencySymbol) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportsService.getInventoryAnalytics(),
      key: _inventoryReportKey, // Use the unique key here
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        final lowStockItems = data['lowStockItems'] as List<dynamic>;
        final itemsByCategory = (data['itemsByCategory']
                as Map<String, List<dynamic>>)
            .entries
            .map((e) => CategoryData(
                  e.key,
                  e.value.fold<double>(
                    0,
                    (sum, item) =>
                        sum + ((item.amount ?? 0) * (item.stockQuantity ?? 0)),
                  ),
                  e.value.length,
                ))
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryCard(
                title: 'Inventory Overview',
                icon: Icons.warehouse,
                items: [
                  ReportItem('Total Items', data['totalItems'],
                      isAmount: false),
                  ReportItem('Total Stock Value', data['totalStockValue']),
                  ReportItem('Low Stock Items', lowStockItems.length,
                      isAmount: false),
                ],
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: 16),
              if (lowStockItems.isNotEmpty)
                _buildAlertCard(
                  title: 'Low Stock Alert',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange,
                  items: lowStockItems,
                ),
              const SizedBox(height: 16),
              _buildInventoryPieChart(
                title: 'Category Breakdown',
                data: itemsByCategory,
                currencySymbol: currencySymbol,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required List<ReportItem> items,
    required String currencySymbol,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        item.isAmount
                            ? '${item.isPositive == true ? '+' : item.isPositive == false ? '-' : ''} $currencySymbol ${NumberFormat('#,##,###.##').format(item.value)}'
                            : '${item.value}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: item.isPositive != null
                                  ? item.isPositive!
                                      ? Colors.green
                                      : Colors.red
                                  : null,
                            ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<dynamic> items,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName ?? 'Unknown Item',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Current: ${item.stockQuantity} • Min: ${item.lowStockQuantity}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text('Restock'),
                      backgroundColor: color.withOpacity(0.2),
                      labelStyle: TextStyle(color: color),
                      side: BorderSide.none,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialTrendChart({
    required String title,
    required List<FinancialData> data,
    required String currencySymbol,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                tooltipBehavior: _tooltipBehavior,
                primaryXAxis: DateTimeAxis(
                  dateFormat: _dateFormat,
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                  intervalType: DateTimeIntervalType.days,
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.currency(symbol: currencySymbol),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                ),
                series: <CartesianSeries>[
                  SplineAreaSeries<FinancialData, DateTime>(
                    dataSource: data,
                    xValueMapper: (FinancialData sales, _) => sales.date,
                    yValueMapper: (FinancialData sales, _) => sales.amount,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        Theme.of(context).colorScheme.primary.withOpacity(0.01),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderColor: Theme.of(context).colorScheme.primary,
                    borderWidth: 2,
                    markerSettings: const MarkerSettings(isVisible: true),
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.auto,
                      textStyle: Theme.of(context).textTheme.labelSmall!,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesBarChart({
    required String title,
    required List<SalesData> data,
    required String currencySymbol,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                tooltipBehavior: _tooltipBehavior,
                primaryXAxis: DateTimeAxis(
                  dateFormat: _dateFormat,
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                  intervalType: DateTimeIntervalType.days,
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.currency(symbol: currencySymbol),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                ),
                series: <CartesianSeries>[
                  ColumnSeries<SalesData, DateTime>(
                    dataSource: data,
                    xValueMapper: (SalesData sales, _) => sales.date,
                    yValueMapper: (SalesData sales, _) => sales.amount,
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                    width: 0.6,
                    spacing: 0.2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseBarChart({
    required String title,
    required List<PurchaseData> data,
    required String currencySymbol,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                tooltipBehavior: _tooltipBehavior,
                primaryXAxis: DateTimeAxis(
                  dateFormat: _dateFormat,
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                  intervalType: DateTimeIntervalType.days,
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.currency(symbol: currencySymbol),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                ),
                series: <CartesianSeries>[
                  ColumnSeries<PurchaseData, DateTime>(
                    dataSource: data,
                    xValueMapper: (PurchaseData purchase, _) => purchase.date,
                    yValueMapper: (PurchaseData purchase, _) => purchase.amount,
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(4),
                    width: 0.6,
                    spacing: 0.2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsChart({
    required String title,
    required List<ProductData> data,
    required String currencySymbol,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                tooltipBehavior: _tooltipBehavior,
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.currency(symbol: currencySymbol),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                ),
                series: <CartesianSeries>[
                  BarSeries<ProductData, String>(
                    dataSource: data,
                    xValueMapper: (ProductData product, _) => product.name,
                    yValueMapper: (ProductData product, _) => product.amount,
                    color: Theme.of(context).colorScheme.primary,
                    width: 0.6,
                    spacing: 0.2,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.auto,
                      textStyle: Theme.of(context).textTheme.labelSmall!,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSuppliersChart({
    required String title,
    required List<SupplierData> data,
    required String currencySymbol,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                tooltipBehavior: _tooltipBehavior,
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.currency(symbol: currencySymbol),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                ),
                series: <CartesianSeries>[
                  BarSeries<SupplierData, String>(
                    dataSource: data,
                    xValueMapper: (SupplierData supplier, _) => supplier.name,
                    yValueMapper: (SupplierData supplier, _) => supplier.amount,
                    color: Theme.of(context).colorScheme.secondary,
                    width: 0.6,
                    spacing: 0.2,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.auto,
                      textStyle: Theme.of(context).textTheme.labelSmall!,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryPieChart({
    required String title,
    required List<CategoryData> data,
    required String currencySymbol,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                tooltipBehavior: _tooltipBehavior,
                legend: Legend(
                  isVisible: true,
                  overflowMode: LegendItemOverflowMode.wrap,
                  position: LegendPosition.bottom,
                ),
                series: <CircularSeries>[
                  PieSeries<CategoryData, String>(
                    dataSource: data,
                    xValueMapper: (CategoryData category, _) => category.name,
                    yValueMapper: (CategoryData category, _) => category.value,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: Theme.of(context).textTheme.labelSmall!,
                      connectorLineSettings: const ConnectorLineSettings(
                        length: '20%',
                        type: ConnectorType.curve,
                      ),
                    ),
                    pointColorMapper: (CategoryData category, _) =>
                        Colors.primaries[
                            data.indexOf(category) % Colors.primaries.length],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...data.map((category) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.primaries[
                              data.indexOf(category) % Colors.primaries.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '$currencySymbol${NumberFormat('#,##,###.##').format(category.value)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class FinancialData {
  final DateTime date;
  final double amount;

  FinancialData(this.date, this.amount);
}

class SalesData {
  final DateTime date;
  final double amount;

  SalesData(this.date, this.amount);
}

class PurchaseData {
  final DateTime date;
  final double amount;

  PurchaseData(this.date, this.amount);
}

class ProductData {
  final String name;
  final int quantity;
  final double amount;

  ProductData(this.name, this.quantity, this.amount);
}

class SupplierData {
  final String name;
  final int count;
  final double amount;

  SupplierData(this.name, this.count, this.amount);
}

class CategoryData {
  final String name;
  final double value;
  final int itemCount;

  CategoryData(this.name, this.value, this.itemCount);
}

class ReportItem {
  final String label;
  final dynamic value;
  final bool isAmount;
  final bool? isPositive;

  ReportItem(this.label, this.value, {this.isAmount = true, this.isPositive});
}
