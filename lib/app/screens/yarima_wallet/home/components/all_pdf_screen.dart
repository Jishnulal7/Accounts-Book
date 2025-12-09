import 'dart:io';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/components/save_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/daily/daily_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/daily/expense_and_transfer.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/daily/expense_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/daily/income_and_expense.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/daily/income_and_transfer.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/daily/income_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/daily/transfer_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/monthly/custom_date.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/monthly/description_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/monthly/expense_and_income_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/monthly/expense_and_transfers_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/monthly/expense_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/monthly/income_and_transfers_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/monthly/income_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/monthly/monthly_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/monthly/transfer_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/yearly/expense_and_income.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/yearly/expense_and_tranfer.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/yearly/expense_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/yearly/income_and_transfer.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/yearly/income_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/yearly/transfer_pdf.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/yearly/yearly_pdf.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AllPdfScreen extends StatefulWidget {
  AllPdfScreen({
    super.key,
    required this.selectDailyDate,
    required this.transactionsByMonth,
    required this.yearlyData,
    required this.transactionBox,
    required this.openingBalance,
    required this.attendanceBox,
  });
  final Map<String, List<TransactionModel>> transactionsByMonth;
  DateTime selectDailyDate;
  final Map<String, Map<String, double>> yearlyData;
  final Box<TransactionModel> transactionBox;
  final Box<AttendanceModel> attendanceBox;
  final double openingBalance;
  @override
  State<AllPdfScreen> createState() => _AllPdfScreenState();
}

class _AllPdfScreenState extends State<AllPdfScreen> {
  String? selectedTimeframe;
  Set<String> selectedCategories = {};
  String? pdfPath;
  bool isLoading = false;
  final Set<String> allCategories = {'Payment', 'Receipt', 'Transfers'};
  PdfViewerController? _pdfViewerController;
  TextEditingController filterController = TextEditingController();
  final SavePDF _savePDF = SavePDF();

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController?.dispose();
    filterController.dispose();
    super.dispose();
  }

  Future<String?> createDailyPdf() async {
    var pdfPath = await DailyPdfGenerator(
      selectedDate: widget.selectDailyDate,
      context: context,
      openingBalance: widget.openingBalance,
      transactionBox: widget.transactionBox,
      attendanceBox: widget.attendanceBox,
    ).generateDailyPdfReport();
    return pdfPath;
  }

  Future<String?> createDailyPaymentPdf() async {
    var pdfPath = await DailyxpensePdfGenerator(
      attendanceBox: widget.attendanceBox,
      selectedDate: widget.selectDailyDate,
      transactionBox: widget.transactionBox,
    ).generatePaymentPdfReport();
    return pdfPath;
  }

  Future<String?> createDailyReceiptPdf() async {
    var pdfPath = await DailyReceiptPDF(
      selectedDate: widget.selectDailyDate,
      transactionBox: widget.transactionBox,
    ).generateReceiptPdfReport();
    return pdfPath;
  }

  Future<String?> createDailyTransferPdf() async {
    var pdfPath = await DailyTransferPdfGenerator(
      selectedDate: widget.selectDailyDate,
      transactionBox: widget.transactionBox,
    ).generateTransferPdfReport();
    return pdfPath;
  }

  Future<String?> createDailyPaymentAndTransferPdf() async {
    var pdfPath = await DailyPaymentTransferPdfGenerator(
      selectedDate: widget.selectDailyDate,
      transactionBox: widget.transactionBox,
    ).generatePaymentTransferPdfReport();
    return pdfPath;
  }

  Future<String?> createDailyReceiptAndTransferPdf() async {
    var pdfPath = await DailyReceiptTransferPdfGenerator(
      selectedDate: widget.selectDailyDate,
      transactionBox: widget.transactionBox,
    ).generateReceiptTransferPdfReport();
    return pdfPath;
  }

  Future<String?> createDailyReceiptAndPaymentPdf() async {
    var pdfPath = await DailyReceiptPaymentPdfGenerator(
      selectedDate: widget.selectDailyDate,
      transactionBox: widget.transactionBox,
    ).generateReceiptPaymentPdfReport();
    return pdfPath;
  }

  Future<String?> createYearlyPdf() async {
    String pdfPath = await YearlyPDFGenerator().generateYearlyPDF(
      widget.transactionBox,
      widget.attendanceBox,
      widget.selectDailyDate,
      widget.yearlyData,
      widget.openingBalance,
    );
    return pdfPath;
  }

  Future<String?> createYearlyPaymentPdf() async {
    String pdfPath = await YearlyPaymentPDF().generateYearlyPaymentPDF(
      widget.transactionBox,
      widget.attendanceBox,
      widget.selectDailyDate,
      widget.yearlyData,
      widget.openingBalance,
    );
    return pdfPath;
  }

  Future<String?> createYearlyReceiptPdf() async {
    String pdfPath = await YearlyReceiptPDF().generateYearlyReceiptsPDF(
      widget.transactionBox,
      widget.selectDailyDate,
      widget.yearlyData,
      widget.openingBalance,
    );
    return pdfPath;
  }

  Future<String?> createYearlyTransfersPdf() async {
    String pdfPath = await YearlyTransferPDF().generateYearlyTransfersPDF(
      widget.transactionBox,
      widget.selectDailyDate,
      widget.yearlyData,
      widget.openingBalance,
    );
    return pdfPath;
  }

  Future<String?> createYearlyPaymentAndReceiptPdf() async {
    String pdfPath =
        await YearlyPaymentAndReceipt().generateYearlyPaymentAndReceiptPDF(
      widget.transactionBox,
      widget.selectDailyDate,
      widget.yearlyData,
    );
    return pdfPath;
  }

  Future<String?> createYearlyTransfersAndReceiptPdf() async {
    String pdfPath =
        await YearlyReceiptAndTransfers().generateYearlyReceiptAndTransfersPDF(
      widget.transactionBox,
      widget.selectDailyDate,
      widget.yearlyData,
    );
    return pdfPath;
  }

  Future<String?> createYearlyTransfersAndPaymentPdf() async {
    String pdfPath = await YearlyPaymentAndTransfersReport().generateReport(
      widget.transactionBox,
      widget.selectDailyDate,
      widget.yearlyData,
    );
    return pdfPath;
  }

  Future<void> changeMonth(BuildContext context, int change) async {
    try {
      final newDate = widget.selectDailyDate.add(Duration(days: 30 * change));
      setState(() {
        widget.selectDailyDate = newDate;
      });
      await createMonthlyPdf();
    } catch (e) {
      debugPrint("Error changing month: $e");
    }
  }

  Future<String?> createMonthlyPdf() async {
    String pdfPath = await PdfGenerator().generateMonthlyPdfReport(
      widget.selectDailyDate,
      widget.openingBalance,
      widget.transactionsByMonth,
      widget.attendanceBox,
      context,
    );

    return pdfPath;
  }

  Future<String?> monthlyPayment() async {
    String pdfPath = await MonthlyPaymentPDF().generateMonthlyPaymentsPdfReport(
      widget.selectDailyDate,
      widget.transactionsByMonth,
      widget.attendanceBox,
      context,
    );

    return pdfPath;
  }

  Future<String?> monthlyReceipt() async {
    String pdfPath = await MonthlyReceiptPDF().generateMonthlyReceiptsPdfReport(
      widget.selectDailyDate,
      widget.transactionsByMonth,
      widget.attendanceBox,
      context,
    );

    return pdfPath;
  }

  Future<String?> monthlyTransfers() async {
    String pdfPath =
        await MonthlyTransfersPDF().generateMonthlyTransfersPdfReport(
      widget.selectDailyDate,
      widget.transactionsByMonth,
      context,
    );

    return pdfPath;
  }

  Future<String?> monthlyReceiptAndPayment() async {
    String pdfPath =
        await MonthlyPaymentAndReceiptPDF().monthlyReceiptAndPaymentPdfReport(
      widget.selectDailyDate,
      widget.transactionsByMonth,
      widget.attendanceBox,
      context,
    );

    return pdfPath;
  }

  Future<String?> monthlyTransfersAndPayment() async {
    String pdfPath = await MonthlyPaymentAndTransfersPDF()
        .monthlyPaymentAndTransferPdfReport(
      widget.selectDailyDate,
      widget.transactionsByMonth,
      context,
    );

    return pdfPath;
  }

  Future<String?> monthlyTransfersAndReceipt() async {
    String pdfPath = await MonthlyTransfersAndReceiptPDF()
        .monthlyReceiptPaymentAndTransferPdfReport(
      widget.selectDailyDate,
      widget.transactionsByMonth,
      context,
    );

    return pdfPath;
  }

  Future<String?> createFilteredPdf(BuildContext context, String filter) async {
    final filePath = await DescriptionPdf().generateFilteredPdfReport(
      widget.selectDailyDate,
      widget.transactionBox,
      widget.attendanceBox,
      filter,
      context,
    );
    setState(() {
      selectedTimeframe = 'Description';
    });
    return filePath;
  }

  Future<void> pickDate() async {
    try {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );

      if (picked != null) {
        setState(() {
          isLoading = true;
        });

        final filePath =
            await CustomDateRangeMonthlyPDF().generateCustomDateRangePDF(
          widget.transactionBox,
          picked.start,
          picked.end,
          widget.transactionsByMonth,
          widget.openingBalance,
        );

        setState(() {
          pdfPath = filePath;
          selectedTimeframe = 'Custom';
          selectedCategories = {'All'};
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildFloatingActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'save',
          onPressed: () {
            _savePDFFile();
          },
          child: const Icon(Icons.save),
        ),
        const SizedBox(width: 16),
        FloatingActionButton(
          heroTag: 'share',
          onPressed: () {
            _sharePDFFile();
          },
          child: const Icon(Icons.share),
        ),
      ],
    );
  }

  void _savePDFFile() async {
    if (pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF generated yet.')),
      );
      return;
    }

    int tabIndex = selectedTimeframe == 'Yearly'
        ? 0
        : (selectedTimeframe == 'Monthly' ? 1 : 2);
    int subIndex = _getSubIndex();

    await _savePDF.savePdf(
      context,
      pdfPath!,
      widget.selectDailyDate,
      tabIndex,
      subIndex,
    );
  }

  void _sharePDFFile() async {
    if (pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF generated yet.')),
      );
      return;
    }

    await _savePDF.sharePDF(pdfPath!);
  }

  int _getSubIndex() {
    if (selectedCategories.contains('All')) return 0;
    if (selectedCategories.contains('Payment')) return 1;
    if (selectedCategories.contains('Receipt')) return 2;
    if (selectedCategories.contains('Transfers')) return 3;
    return 0;
  }

  Widget _buildButton(String text, VoidCallback onPressed, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        spacing: 5,
        children: [
          Row(
            children: [
              _buildButton(
                'Daily',
                () {
                  setState(() {
                    selectedTimeframe =
                        (selectedTimeframe == 'Daily') ? null : 'Daily';
                    selectedCategories.clear();
                    pdfPath = null;
                  });
                },
                selectedTimeframe == 'Daily',
              ),
              _buildButton(
                'Monthly',
                () {
                  setState(() {
                    selectedTimeframe =
                        (selectedTimeframe == 'Monthly') ? null : 'Monthly';
                    selectedCategories.clear();
                    pdfPath = null;
                  });
                },
                selectedTimeframe == 'Monthly',
              ),
              _buildButton(
                'Yearly',
                () {
                  setState(() {
                    selectedTimeframe =
                        (selectedTimeframe == 'Yearly') ? null : 'Yearly';
                    selectedCategories.clear();
                    pdfPath = null;
                  });
                },
                selectedTimeframe == 'Yearly',
              ),
            ],
          ),
          if (selectedTimeframe != null) ...[
            Row(
              children: [
                _buildButton('All', () async {
                  if (selectedTimeframe == 'Daily') {
                    _loadPdf(createDailyPdf, {'All'});
                  } else if (selectedTimeframe == 'Monthly') {
                    _loadPdf(createMonthlyPdf, {'All'});
                  } else if (selectedTimeframe == 'Yearly') {
                    _loadPdf(createYearlyPdf, {'All'});
                  }
                }, selectedCategories.contains('All')),
                _buildButton('Payment', () {
                  _toggleCategory('Payment');
                }, selectedCategories.contains('Payment')),
                _buildButton('Receipt', () {
                  _toggleCategory('Receipt');
                }, selectedCategories.contains('Receipt')),
                _buildButton('Transfers', () {
                  _toggleCategory('Transfers');
                }, selectedCategories.contains('Transfers')),
              ],
            ),
            Row(
              children: [
                _buildButton('Description', () {
                  _showTextfield(context);
                }, selectedTimeframe == 'Description'),
                _buildButton('Pick a Date', () {
                  pickDate();
                }, selectedTimeframe == 'Custom'),
                if (selectedTimeframe == 'Monthly') ...[
                  _buildMonthSelector(context),
                ] else if (selectedTimeframe == 'Yearly') ...[
                  _buildYearSelector(context),
                ] else if (selectedTimeframe == 'Daily') ...[
                  _buildDaySelector(context),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDaySelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _changeDay(context, -1),
            child: const Icon(Icons.arrow_left),
          ),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Text(
              DateFormat('dd MMM yyyy').format(widget.selectDailyDate),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _changeDay(context, 1),
            child: const Icon(Icons.arrow_right),
          ),
        ],
      ),
    );
  }

  Future<void> _changeDay(BuildContext context, int change) async {
    try {
      final newDate = widget.selectDailyDate.add(Duration(days: change));
      setState(() {
        widget.selectDailyDate = newDate;
        isLoading = true;
      });

      // Generate and display the daily PDF for the new date
      await _generateAndDisplayAppropriateDailyPdf();
    } catch (e) {
      debugPrint("Error changing day: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectDailyDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != widget.selectDailyDate) {
      setState(() {
        widget.selectDailyDate = picked;
        isLoading = true;
      });
      await _generateAndDisplayAppropriateDailyPdf();
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _generateAndDisplayAppropriateDailyPdf() async {
    try {
      String? newPdfPath = await _generateDailyPdf();
      if (newPdfPath != null) {
        setState(() {
          pdfPath = newPdfPath;
          selectedTimeframe = 'Daily';
        });
      } else {
        throw Exception('Unable to generate PDF');
      }
    } catch (e) {
      debugPrint("Error generating daily PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating daily PDF: $e')),
      );
    }
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _changeMonth(context, -1),
            child: const Icon(Icons.arrow_left),
          ),
          GestureDetector(
            onTap: () => _selectMonthYear(context),
            child: Text(
              DateFormat('MMMM y').format(widget.selectDailyDate),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _changeMonth(context, 1),
            child: const Icon(Icons.arrow_right),
          ),
        ],
      ),
    );
  }

  Future<void> _changeMonth(BuildContext context, int change) async {
    try {
      final newDate = widget.selectDailyDate.add(Duration(days: 30 * change));
      setState(() {
        widget.selectDailyDate = newDate;
        isLoading = true;
      });

      // Generate and display the monthly PDF for the new date
      await _generateAndDisplayAppropriateMonthlyPdf();
    } catch (e) {
      debugPrint("Error changing month: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectMonthYear(BuildContext context) async {
    try {
      showMonthPicker(
        context: context,
        initialDate: widget.selectDailyDate,
        firstDate: DateTime(2000, 1),
        lastDate: DateTime(2101, 12),
      ).then((date) async {
        if (date != null) {
          setState(() {
            widget.selectDailyDate = date;
          });
        }
        await _generateAndDisplayAppropriateMonthlyPdf();
      });
    } catch (e) {
      debugPrint("Error selecting month/year: $e");
    }
  }

  Future<void> _generateAndDisplayAppropriateMonthlyPdf() async {
    try {
      String? newPdfPath;

      if (selectedCategories.containsAll(['Payment', 'Receipt', 'Transfers']) ||
          selectedCategories.contains('All') ||
          selectedCategories.isEmpty) {
        newPdfPath = await createMonthlyPdf();
        selectedCategories = {'All'};
      } else if (selectedCategories.containsAll(['Payment', 'Receipt'])) {
        newPdfPath = await monthlyReceiptAndPayment();
      } else if (selectedCategories.containsAll(['Transfers', 'Payment'])) {
        newPdfPath = await monthlyTransfersAndPayment();
      } else if (selectedCategories.containsAll(['Transfers', 'Receipt'])) {
        newPdfPath = await monthlyTransfersAndReceipt();
      } else if (selectedCategories.contains('Payment')) {
        newPdfPath = await monthlyPayment();
      } else if (selectedCategories.contains('Receipt')) {
        newPdfPath = await monthlyReceipt();
      } else if (selectedCategories.contains('Transfers')) {
        newPdfPath = await monthlyTransfers();
      }

      if (newPdfPath != null) {
        setState(() {
          pdfPath = newPdfPath;
          selectedTimeframe = 'Monthly';
        });
      } else {
        throw Exception('Unable to generate PDF');
      }
    } catch (e) {
      debugPrint("Error generating monthly PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating monthly PDF: $e')),
      );
    }
  }

  Widget _buildYearSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              try {
                await _changeYear(context, -1);
              } catch (e) {
                debugPrint("Error changing year: $e");
              }
            },
            child: const Icon(Icons.arrow_left_outlined),
          ),
          SizedBox(
            child: Text(
              DateFormat('y').format(widget.selectDailyDate),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              try {
                await _changeYear(context, 1);
              } catch (e) {
                debugPrint("Error changing year: $e");
              }
            },
            child: const Icon(Icons.arrow_right_outlined),
          ),
        ],
      ),
    );
  }

  Future<void> _changeYear(BuildContext context, int change) async {
    setState(() {
      isLoading = true;
    });

    try {
      final newDate = DateTime(
        widget.selectDailyDate.year + change,
        widget.selectDailyDate.month,
        widget.selectDailyDate.day,
      );

      setState(() {
        widget.selectDailyDate = newDate;
      });

      // Generate and display the appropriate yearly PDF
      String? newPdfPath = await _generateYearlyPdf();

      if (newPdfPath != null) {
        setState(() {
          pdfPath = newPdfPath;
        });
      } else {
        throw Exception('Unable to generate yearly PDF');
      }
    } catch (e) {
      debugPrint("Error changing year: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating yearly PDF: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _toggleCategory(String category) async {
    setState(() {
      isLoading = true;
    });

    if (category == 'All') {
      selectedCategories = {'All'};
    } else {
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
      } else {
        selectedCategories.add(category);
      }
      selectedCategories.remove('All');
    }

    String? newPdfPath;
    if (selectedTimeframe == 'Daily') {
      newPdfPath = await _generateDailyPdf();
    } else if (selectedTimeframe == 'Monthly') {
      newPdfPath = await _generateMonthlyPdf();
    } else if (selectedTimeframe == 'Yearly') {
      newPdfPath = await _generateYearlyPdf();
    }

    setState(() {
      pdfPath = newPdfPath;
      isLoading = false;
    });
  }

  Future<String?> _generateDailyPdf() async {
    if (selectedCategories.contains('All') ||
        selectedCategories.containsAll(['Payment', 'Receipt', 'Transfers']) ||
        selectedCategories.isEmpty) {
      return await createDailyPdf();
    } else if (selectedCategories.containsAll(['Payment', 'Receipt'])) {
      return await createDailyReceiptAndPaymentPdf();
    } else if (selectedCategories.containsAll(['Transfers', 'Payment'])) {
      return await createDailyPaymentAndTransferPdf();
    } else if (selectedCategories.containsAll(['Transfers', 'Receipt'])) {
      return await createDailyReceiptAndTransferPdf();
    } else if (selectedCategories.contains('Payment')) {
      return await createDailyPaymentPdf();
    } else if (selectedCategories.contains('Receipt')) {
      return await createDailyReceiptPdf();
    } else if (selectedCategories.contains('Transfers')) {
      return await createDailyTransferPdf();
    }
    return null;
  }

  Future<String?> _generateMonthlyPdf() async {
    if (selectedCategories.containsAll(['Payment', 'Receipt', 'Transfers']) ||
        selectedCategories.isEmpty) {
      return await createMonthlyPdf();
    } else if (selectedCategories.containsAll(['Payment', 'Receipt'])) {
      return await monthlyReceiptAndPayment();
    } else if (selectedCategories.containsAll(['Transfers', 'Payment'])) {
      return await monthlyTransfersAndPayment();
    } else if (selectedCategories.containsAll(['Transfers', 'Receipt'])) {
      return await monthlyTransfersAndReceipt();
    } else if (selectedCategories.contains('Payment')) {
      return await monthlyPayment();
    } else if (selectedCategories.contains('Receipt')) {
      return await monthlyReceipt();
    } else if (selectedCategories.contains('Transfers')) {
      return await monthlyTransfers();
    }
    return null;
  }

  Future<String?> _generateYearlyPdf() async {
    if (selectedCategories.containsAll(['Payment', 'Receipt', 'Transfers']) ||
        selectedCategories.isEmpty) {
      return await createYearlyPdf();
    } else if (selectedCategories.containsAll(['Payment', 'Receipt'])) {
      return await createYearlyPaymentAndReceiptPdf();
    } else if (selectedCategories.containsAll(['Transfers', 'Payment'])) {
      return await createYearlyTransfersAndPaymentPdf();
    } else if (selectedCategories.containsAll(['Transfers', 'Receipt'])) {
      return await createYearlyTransfersAndReceiptPdf();
    } else if (selectedCategories.contains('Payment')) {
      return await createYearlyPaymentPdf();
    } else if (selectedCategories.contains('Receipt')) {
      return await createYearlyReceiptPdf();
    } else if (selectedCategories.contains('Transfers')) {
      return await createYearlyTransfersPdf();
    }
    return null;
  }

  void _loadPdf(
      Future<String?> Function() pdfFunction, Set<String> categories) async {
    setState(() {
      isLoading = true;
    });

    final path = await pdfFunction();

    setState(() {
      pdfPath = path;
      selectedCategories = categories;
      isLoading = false;
    });
  }

  void _showTextfield(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter'),
        content: TextField(
          controller: filterController,
          decoration: const InputDecoration(
            hintText: 'Enter description to filter',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() {
                isLoading = true;
              });
              String? newPdfPath;
              if (selectedTimeframe == 'Yearly') {
                newPdfPath =
                    await createFilteredPdf(context, filterController.text);
              } else {
                newPdfPath =
                    await createFilteredPdf(context, filterController.text);
              }
              setState(() {
                pdfPath = newPdfPath;
                isLoading = false;
              });
            },
            child: const Text('Filter'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: selectedTimeframe == null
            ? const Size.fromHeight(130.0)
            : const Size.fromHeight(225),
        child: AppBar(
          title: const Text('PDF Report'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80.0),
            child: _buildButtons(context),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pdfPath != null
              ? SfPdfViewer.file(
                  File(pdfPath!),
                  controller: _pdfViewerController,
                )
              : const Center(child: Text('No PDF selected')),
      floatingActionButton:
          pdfPath != null ? _buildFloatingActionButtons() : null,
    );
  }
}

extension ToggleSet<T> on Set<T> {
  void toggle(T element) {
    if (contains(element)) {
      remove(element);
    } else {
      add(element);
    }
  }
}
