import 'dart:typed_data';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/components/save_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AccountPDFScreen extends StatelessWidget {
  final String accountName;
  final List<TransactionModel> transactions;
  final List<AttendanceModel> attendanceRecords;
  final DateTime startDate;
  final DateTime endDate;

  const AccountPDFScreen({
    super.key,
    required this.accountName,
    required this.transactions,
    required this.attendanceRecords,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$accountName Transactions'),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SpeedDial(
            heroTag: 'download',
            onPress: () async {
              final pdfBytes = await _generatePdfBytes();
              await SavePDF()
                  .downloadPdf(context, pdfBytes, accountName, 'Transactions');
            },
            child: const Icon(Icons.download),
          ),
          const SizedBox(width: 10),
          SpeedDial(
            heroTag: 'share',
            onPress: () async {
              final pdfBytes = await _generatePdfBytes();
              await SavePDF().sharePdf(pdfBytes, accountName);
            },
            child: const Icon(Icons.share),
          ),
        ],
      ),
      body: FutureBuilder<PdfDocument>(
        future: _generatePdf(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error generating PDF: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No PDF data available'));
          }
          final Uint8List pdfBytes =
              Uint8List.fromList(snapshot.data!.saveSync());
          return SfPdfViewer.memory(pdfBytes, key: UniqueKey());
        },
      ),
    );
  }

  Future<Uint8List> _generatePdfBytes() async {
    final document = await _generatePdf();
    return Uint8List.fromList(document.saveSync());
  }

  Future<PdfDocument> _generatePdf() async {
    final document = PdfDocument();
    final page = document.pages.add();

    _addStylishHeader(page);
    _addTransactionTable(page);

    return document;
  }

  void _addStylishHeader(PdfPage page) {
    final headerText = PdfTextElement(
      text: 'Transactions for $accountName',
      font: PdfStandardFont(PdfFontFamily.helvetica, 24,
          style: PdfFontStyle.bold),
    );
    headerText.draw(page: page, bounds: const Rect.fromLTWH(0, 0, 0, 0));

    final dateRangeText = PdfTextElement(
      text:
          'From ${DateFormat('dd MMM yyyy').format(startDate)} to ${DateFormat('dd MMM yyyy').format(endDate)}',
      font: PdfStandardFont(PdfFontFamily.helvetica, 14),
    );
    dateRangeText.draw(page: page, bounds: const Rect.fromLTWH(0, 30, 0, 0));

    final graphics = page.graphics;
    graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0), width: 1),
      const Offset(0, 55),
      Offset(page.getClientSize().width, 55),
    );
  }

  PdfLayoutResult _addTransactionTable(PdfPage page) {
    final header = [
      'Date',
      'Category',
      'SubName',
      'Description',
      'Receipt',
      'Payment',
      'Balance'
    ];

    final table = PdfGrid();
    table.columns.add(count: header.length);
    table.headers.add(1);
    final headerRow = table.headers[0];
    for (int i = 0; i < header.length; i++) {
      headerRow.cells[i].value = header[i];
      headerRow.cells[i].style.backgroundBrush =
          PdfSolidBrush(PdfColor(66, 133, 244));
      headerRow.cells[i].style.textBrush = PdfBrushes.white;
      headerRow.cells[i].style.font = PdfStandardFont(
          PdfFontFamily.helvetica, 12,
          style: PdfFontStyle.bold);
    }

    double runningBalance = 0;
    double totalReceipts = 0;
    double totalPayments = 0;

    final filteredTransactions = transactions
        .where((t) =>
            (t.fromAccount == accountName || t.toAccount == accountName) &&
            t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            t.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final filteredAttendanceRecords = attendanceRecords
        .where((a) =>
            a.account == accountName &&
            a.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            a.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final combinedEntries = [
      ...filteredTransactions.map((t) => {'type': 'transaction', 'data': t}),
      ...filteredAttendanceRecords.map((a) => {'type': 'attendance', 'data': a})
    ];

    combinedEntries.sort((a, b) {
      final dateA = a['type'] == 'transaction'
          ? (a['data'] as TransactionModel).date
          : (a['data'] as AttendanceModel).date;
      final dateB = b['type'] == 'transaction'
          ? (b['data'] as TransactionModel).date
          : (b['data'] as AttendanceModel).date;
      return dateA.compareTo(dateB);
    });

    for (var entry in combinedEntries) {
      if (entry['type'] == 'transaction') {
        final transaction = entry['data'] as TransactionModel;
        final row = table.rows.add();
        row.cells[0].value = DateFormat('dd MMM yyyy').format(transaction.date);
        row.cells[1].value = transaction.categoryName ?? '';
        row.cells[2].value = transaction.subCategory ?? 'N/A';
        row.cells[3].value = transaction.description;

        final isReceipt =
            transaction.transactionType == TransactionType.receipt ||
                (transaction.transactionType == TransactionType.transfer &&
                    transaction.toAccount == accountName);
        final isPayment =
            transaction.transactionType == TransactionType.payment ||
                (transaction.transactionType == TransactionType.transfer &&
                    transaction.fromAccount == accountName);

        final amount = transaction.amount.abs().toStringAsFixed(1);
        if (isReceipt) {
          row.cells[4].value = amount;
          row.cells[5].value = '';
          totalReceipts += transaction.amount;
          runningBalance += transaction.amount;
        } else if (isPayment) {
          row.cells[4].value = '';
          row.cells[5].value = amount;
          totalPayments += transaction.amount;
          runningBalance -= transaction.amount;
        }
        row.cells[6].value = runningBalance.toStringAsFixed(1);
      } else {
        final attendance = entry['data'] as AttendanceModel;
        final row = table.rows.add();
        row.cells[0].value = DateFormat('dd MMM yyyy').format(attendance.date);
        row.cells[1].value = attendance.categoryName;
        row.cells[2].value = attendance.subName;
        row.cells[3].value = attendance.description;
        row.cells[4].value = '';
        row.cells[5].value = attendance.payment.toStringAsFixed(1);
        totalPayments += attendance.payment;
        runningBalance -= attendance.payment;
        row.cells[6].value = runningBalance.toStringAsFixed(1);
      }
    }
    for (int i = 0; i < table.rows.count; i++) {
      final row = table.rows[i];
      final brush = i % 2 == 0
          ? PdfSolidBrush(PdfColor(242, 242, 242))
          : PdfSolidBrush(PdfColor(255, 255, 255));
      for (int j = 0; j < row.cells.count; j++) {
        row.cells[j].style.backgroundBrush = brush;
      }
    }

    final summaryRow = table.rows.add();
    summaryRow.cells[0].value = 'Total';
    summaryRow.cells[1].value = '';
    summaryRow.cells[2].value = '';
    summaryRow.cells[3].value = '';
    summaryRow.cells[4].value = totalReceipts.toStringAsFixed(1);
    summaryRow.cells[5].value = totalPayments.toStringAsFixed(1);
    summaryRow.cells[6].value = runningBalance.toStringAsFixed(1);

    for (int i = 0; i < summaryRow.cells.count; i++) {
      summaryRow.cells[i].style.backgroundBrush =
          PdfSolidBrush(PdfColor(200, 200, 200));
      summaryRow.cells[i].style.font = PdfStandardFont(
          PdfFontFamily.helvetica, 10,
          style: PdfFontStyle.bold);
    }

    return table.draw(
      page: page,
      bounds: Rect.fromLTWH(
          0, 70, page.getClientSize().width, page.getClientSize().height - 70),
    )!;
  }
}
