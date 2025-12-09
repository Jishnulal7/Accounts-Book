import 'dart:typed_data';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/components/save_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class CategoryPDFScreen extends StatelessWidget {
  const CategoryPDFScreen({
    super.key,
    required this.categoryName,
    required this.transactions,
    required this.startDate,
    required this.endDate,
  });
  final String categoryName;
  final List<TransactionModel> transactions;
  final DateTime startDate;
  final DateTime endDate;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SpeedDial(
            heroTag: 'download',
            onPress: () async {
              final pdfBytes = await _generatePdfBytes();
              await SavePDF()
                  .downloadPdf(context, pdfBytes, categoryName, 'Transactions');
            },
            child: const Icon(Icons.download),
          ),
          const SizedBox(width: 10),
          SpeedDial(
            heroTag: 'share',
            onPress: () async {
              final pdfBytes = await _generatePdfBytes();
              await SavePDF().sharePdf(pdfBytes, categoryName);
            },
            child: const Icon(Icons.share),
          ),
        ],
      ),
      appBar: AppBar(
        title: Text('$categoryName Transactions'),
      ),
      body: FutureBuilder<PdfDocument>(
        future: _generatePdf(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error generating PDF'));
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

    // Add stylish header
    _addStylishHeader(page);

    // Add transaction table with totals
    _addTransactionTable(page);

    return document;
  }

  void _addStylishHeader(PdfPage page) {
    final headerText = PdfTextElement(
      text: 'Transactions for $categoryName',
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

    // Add a horizontal line
    final graphics = page.graphics;
    graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0), width: 1),
      const Offset(0, 55),
      Offset(page.getClientSize().width, 55),
    );
  }

  void _addTransactionTable(PdfPage page) {
    final header = [
      'Date',
      'Account',
      'Description',
      'Amount',
    ];

    final filteredTransactions = transactions
        .where((transaction) =>
            transaction.categoryName == categoryName &&
            transaction.date
                .isAfter(startDate.subtract(const Duration(days: 1))) &&
            transaction.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

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

    double totalAmount = 0;

    for (var transaction in filteredTransactions) {
      final row = table.rows.add();
      row.cells[0].value = DateFormat('dd MMM yyyy').format(transaction.date);
      row.cells[1].value = _getAccountName(transaction);
      row.cells[2].value = transaction.description;

      double amount = transaction.amount;
      if (transaction.transactionType == TransactionType.transfer) {
        if (transaction.fromAccount == categoryName) {
          amount = -amount; // Outgoing transfer
        }
      } else if (transaction.transactionType == TransactionType.payment) {
        amount = -amount; // Payments are negative
      }

      row.cells[3].value = amount.toStringAsFixed(1);
      totalAmount += amount;
    }

    // Apply alternating row colors
    for (int i = 0; i < table.rows.count; i++) {
      final row = table.rows[i];
      final brush = i % 2 == 0
          ? PdfSolidBrush(PdfColor(242, 242, 242))
          : PdfSolidBrush(PdfColor(255, 255, 255));
      for (int j = 0; j < row.cells.count; j++) {
        row.cells[j].style.backgroundBrush = brush;
      }
    }

    // Add summary row
    final summaryRow = table.rows.add();
    summaryRow.cells[0].value = 'Total';
    summaryRow.cells[1].value = '';
    summaryRow.cells[2].value = '';
    summaryRow.cells[3].value = totalAmount.toStringAsFixed(1);

    // Style summary row
    for (int i = 0; i < summaryRow.cells.count; i++) {
      summaryRow.cells[i].style.backgroundBrush =
          PdfSolidBrush(PdfColor(200, 200, 200));
      summaryRow.cells[i].style.font = PdfStandardFont(
          PdfFontFamily.helvetica, 10,
          style: PdfFontStyle.bold);
    }

    // Draw the table
    table.draw(
      page: page,
      bounds: Rect.fromLTWH(
          0, 70, page.getClientSize().width, page.getClientSize().height - 70),
    );
  }

  String _getAccountName(TransactionModel transaction) {
    if (transaction.transactionType == TransactionType.transfer) {
      return transaction.fromAccount == categoryName
          ? '${transaction.fromAccount} → ${transaction.toAccount}'
          : '${transaction.toAccount} ← ${transaction.fromAccount}';
    } else {
      return transaction.fromAccount == categoryName
          ? transaction.toAccount
          : transaction.fromAccount;
    }
  }
}
