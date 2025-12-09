import 'dart:math';
import 'package:account_book/app/data/constants/colors.dart' show AppColor;
import 'package:account_book/app/data/helpers/color_helper.dart';
import 'package:account_book/app/data/helpers/icon_helper.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/yarima_wallet/charts/components/transaction.dart';
import 'package:account_book/app/services/calculation_manager.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:toggle_switch/toggle_switch.dart';

class ChartsScreen extends StatefulWidget {
  DateTime selectedMonth;
  ChartsScreen({super.key, required this.selectedMonth});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  int toggleIndex = 0;
  int graphTypeIndex = 0;
  bool isPayment = true;
  Box<TransactionModel> transactionBox =
      Hive.box<TransactionModel>('transactions');
  Box<AttendanceModel> attendacneBox =
      Hive.box<AttendanceModel>('attendanceBox');
  bool showPieChart = false;
  List<TransactionModel> chartData = [];
  String dropdownValue = 'Transactions';
  ColorHelper colorHelper = ColorHelper();
  @override
  void initState() {
    super.initState();
    _fetchGraphData();
    super.initState();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 900;
      final isTablet =
          constraints.maxWidth > 600 && constraints.maxWidth <= 900;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Charts'),
          actions: _buildAppBarActions(context),
        ),
        body: _buildResponsiveLayout(isDesktop, isTablet, constraints),
      );
    });
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => setState(() => graphTypeIndex = 0),
        icon: const Icon(Icons.bar_chart_rounded),
      ),
      IconButton(
        onPressed: () => setState(() => graphTypeIndex = 1),
        icon: const Icon(Icons.incomplete_circle_rounded),
      ),
      IconButton(
        onPressed: () => setState(() => graphTypeIndex = 2),
        icon: const Icon(Icons.show_chart),
      ),
    ];
  }

  Widget _buildResponsiveLayout(
      bool isDesktop, bool isTablet, BoxConstraints constraints) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;

    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildChartSection(constraints, currencySymbol),
          ),
          Expanded(
            flex: 1,
            child: _buildListSection(constraints, currencySymbol),
          ),
        ],
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildChartSection(constraints, currencySymbol),
            _buildListSection(constraints, currencySymbol),
          ],
        ),
      );
    }
  }

  Widget _buildChartSection(BoxConstraints constraints, String currencySymbol) {
    final chartHeight =
        constraints.maxHeight * (constraints.maxWidth > 900 ? 0.8 : 0.4);

    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 16,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDateSelector(),
              Text(
                '$currencySymbol${_fetchTotalAmount()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(
                height: chartHeight,
                child: _buildChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              widget.selectedMonth =
                  widget.selectedMonth.subtract(const Duration(days: 30));
            });
            _fetchGraphData();
          },
          icon: const Icon(Icons.arrow_left),
        ),
        TextButton(
          onPressed: () => selectMonthYear(context),
          child: Text(
            DateFormat('MMMM y').format(widget.selectedMonth),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              widget.selectedMonth =
                  widget.selectedMonth.add(const Duration(days: 30));
            });
            _fetchGraphData();
          },
          icon: const Icon(Icons.arrow_right),
        ),
      ],
    );
  }

  Widget _buildToggleSwitch(double width) {
    return ToggleSwitch(
      activeBgColor: [AppColor.kPurple],
      customWidths: [width * 0.25, width * 0.25],
      cornerRadius: 20,
      initialLabelIndex: toggleIndex,
      activeBgColors: [
        [AppColor.kGreen],
        [AppColor.kRed],
      ],
      labels: const ['Receipt', 'Payment'],
      onToggle: (index) {
        setState(() {
          toggleIndex = index!;
          isPayment = toggleIndex != 0;
          _fetchGraphData();
        });
      },
    );
  }

  Widget _buildListSection(BoxConstraints constraints, String currencySymbol) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20),
          _buildToggleSwitch(constraints.maxWidth),
          _buildDropdown(),
          Flexible(
            child: dropdownValue == 'Transactions'
                ? _buildTransactionsList(constraints.maxWidth)
                : _buildCategoriesList(constraints.maxWidth, currencySymbol),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButton<String>(
        isExpanded: true,
        value: dropdownValue,
        onChanged: (String? newValue) {
          setState(() => dropdownValue = newValue!);
        },
        items: ['Transactions', 'Category']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    switch (graphTypeIndex) {
      case 0:
        return _buildBarChart(chartData);
      case 1:
        return _buildPieChart(chartData);
      case 2:
        return _buildLineChart(chartData);
      default:
        return _buildBarChart(chartData);
    }
  }

  Widget _buildTransactionsList(double width) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: chartData.length,
      itemBuilder: (context, index) {
        return TransactionWidget(
          width: width,
          transaction: chartData[index],
        );
      },
    );
  }

  Widget _buildCategoriesList(double width, String currencySymbol) {
    final categories = _getDistinctCategories();
    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final transaction = chartData[index];
        return ListTile(
          leading: Image.asset(
            CustomIcons().getImagePathForCategory(
              transaction.generalCategory ?? transaction.categoryName ?? '',
            ),
            width: 30,
          ),
          title: Text(category),
          trailing: Text(
            '$currencySymbol${_calculateTotalCategoryAmount(category)}',
            style: TextStyle(
              color: isPayment ? AppColor.kRed : AppColor.kGreen,
            ),
          ),
        );
      },
    );
  }

  double _calculateTotalCategoryAmount(String category) {
    double totalAmount = 0.0;
    for (var transaction in chartData) {
      if (transaction.generalCategory == category ||
          transaction.categoryName == category) {
        totalAmount += transaction.amount;
      }
    }
    return totalAmount;
  }

  List<String> _getDistinctCategories() {
    Set<String> distinctCategories = {};
    for (var transaction in chartData) {
      if (transaction.generalCategory != null ||
          transaction.categoryName != null) {
        distinctCategories
            .add(transaction.generalCategory ?? transaction.categoryName ?? '');
      }
    }
    return distinctCategories.toList();
  }

  Future<void> _fetchGraphData() async {
    // Fetch data from Hive database based on selectedMonth and toggleIndex
    final transactionsBox =
        await Hive.openBox<TransactionModel>('transactions');
    setState(() {
      chartData = transactionsBox.values
          .where((transaction) =>
              transaction.date.month == widget.selectedMonth.month &&
              transaction.date.year == widget.selectedMonth.year &&
              (toggleIndex == 0
                  ? transaction.transactionType == TransactionType.receipt
                  : transaction.transactionType == TransactionType.payment))
          .toList();
    });
  }

  _fetchTotalAmount() {
    // Fetch data from Hive database based on selectedMonth and toggleIndex
    final totalAmount = toggleIndex == 0
        ? CalculationManager().calculateTotalReceiptAmountForMonth(
            widget.selectedMonth, transactionBox)
        : CalculationManager().calculateTotalPaymentAmountForMonth(
            widget.selectedMonth, transactionBox, attendacneBox);
    return totalAmount;
  }

  Widget _buildBarChart(List<TransactionModel> chartData) {
    if (chartData.isEmpty) {
      return _buildNoDataWidget();
    }

    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;

    // Calculate the maximum amount to set appropriate axis range
    double maxAmount = chartData.fold(
        0,
        (max, transaction) =>
            transaction.amount > max ? transaction.amount : max);

    // Calculate optimal interval based on max amount
    double interval = _calculateOptimalInterval(maxAmount);

    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(
        majorGridLines: MajorGridLines(width: 0),
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
        labelRotation: 45, // Rotate labels for better visibility
        maximumLabels: 31, // Ensure all days are shown
      ),
      primaryYAxis: NumericAxis(
        majorGridLines: const MajorGridLines(width: 0.5, dashArray: [5, 5]),
        labelFormat: '$currencySymbol{value}',
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        minimum: 0,
        maximum: maxAmount * 1.2, // Add 20% padding at the top
        interval: interval,
        numberFormat: NumberFormat
            .compact(), // Use compact number format for large numbers
      ),
      zoomPanBehavior: ZoomPanBehavior(
        // Add zoom and pan capability
        enablePanning: true,
        enablePinching: true,
        zoomMode: ZoomMode.x,
      ),
      title: const ChartTitle(
        text: 'Monthly Transactions',
        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      legend: const Legend(isVisible: false),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'Date: point.x\nAmount: $currencySymbol point.y',
      ),
      series: <CartesianSeries>[
        ColumnSeries<TransactionModel, String>(
          dataSource: chartData,
          xValueMapper: (TransactionModel transaction, _) =>
              DateFormat('d').format(transaction.date),
          yValueMapper: (TransactionModel transaction, _) => transaction.amount,
          name: 'Amount',
          borderRadius: BorderRadius.circular(4),
          width: 0.8, // Adjust bar width
          spacing: 0.2, // Add spacing between bars
          gradient: const LinearGradient(
            colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorHelper.whiteOrDark(context),
            ),
            labelPosition: ChartDataLabelPosition.outside,
            useSeriesColor: true,
          ),
        )
      ],
      plotAreaBorderWidth: 0,
    );
  }

  double _calculateOptimalInterval(double maxValue) {
    // Calculate a nice interval that will result in 5-7 grid lines
    double rawInterval = maxValue / 5;
    int magnitude = (log(rawInterval) / ln10).floor();
    double normalized = rawInterval / pow(10, magnitude);

    // Round to a nice number (1, 2, 2.5, 5, or 10)
    if (normalized < 1.5) return pow(10, magnitude).toDouble();
    if (normalized < 3) return 2 * pow(10, magnitude).toDouble();
    if (normalized < 7) return 5 * pow(10, magnitude).toDouble();
    return 10 * pow(10, magnitude).toDouble();
  }

  Widget _buildPieChart(List<TransactionModel> chartData) {
    if (chartData.isEmpty) {
      return _buildNoDataWidget();
    }

    Map<String, double> categoryAmounts = {};
    for (var transaction in chartData) {
      if (transaction.categoryName != null ||
          transaction.generalCategory != null) {
        var category =
            transaction.generalCategory ?? transaction.categoryName ?? '';
        categoryAmounts[category] =
            (categoryAmounts[category] ?? 0) + transaction.amount;
      }
    }

    List<Color> colorPalette = [
      const Color(0xFF5E35B1),
      const Color(0xFF3949AB),
      const Color(0xFF1E88E5),
      const Color(0xFF039BE5),
      const Color(0xFF00ACC1),
      const Color(0xFF00897B),
      const Color(0xFF43A047),
      const Color(0xFF7CB342),
    ];

    return SfCircularChart(
      title: const ChartTitle(
        text: 'Category Distribution',
        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
        position: LegendPosition.bottom,
      ),
      series: <CircularSeries>[
        DoughnutSeries<MapEntry<String, double>, String>(
          dataSource: categoryAmounts.entries.toList(),
          xValueMapper: (MapEntry<String, double> data, _) => data.key,
          yValueMapper: (MapEntry<String, double> data, _) => data.value,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            textStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: ColorHelper().darkorWhite(context)),
          ),
          pointColorMapper: (MapEntry<String, double> data, int index) =>
              colorPalette[index % colorPalette.length],
          innerRadius: '60%',
          explode: true,
          explodeIndex: 0,
        )
      ],
    );
  }

  Widget _buildLineChart(List<TransactionModel> chartData) {
    if (chartData.isEmpty) {
      return _buildNoDataWidget();
    }

    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        labelRotation: 45,
      ),
      primaryYAxis: NumericAxis(
        labelFormat: '$currencySymbol{value}',
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      series: <LineSeries<TransactionModel, String>>[
        LineSeries<TransactionModel, String>(
          dataSource: chartData,
          xValueMapper: (TransactionModel transaction, _) =>
              DateFormat('d').format(transaction.date),
          yValueMapper: (TransactionModel transaction, _) => transaction.amount,
          markerSettings: const MarkerSettings(isVisible: true),
          color: AppColor.kPurple,
        )
      ],
    );
  }

  Widget _buildNoDataWidget() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 100,
          color: Colors.grey,
        ),
        SizedBox(height: 20),
        Text(
          'No data found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> selectMonthYear(BuildContext context) async {
    showMonthPicker(
      context: context,
      initialDate: widget.selectedMonth,
      firstDate: DateTime(2000, 1),
      lastDate: DateTime(2101, 12),
    ).then((date) {
      if (date != null) {
        setState(() {
          widget.selectedMonth = date;
        });
        _fetchGraphData();
      }
    });
  }
}
