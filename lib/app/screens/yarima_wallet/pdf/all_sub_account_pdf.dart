import 'dart:typed_data';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/components/save_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AllSubAccountPdf extends StatelessWidget {
  const AllSubAccountPdf({
    super.key,
    required this.accountName,
    required this.subcAccountTransactions,
    required this.startDate,
    required this.endDate,
  });
  final String accountName;
  final Map<String, List<TransactionModel>> subcAccountTransactions;
  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$accountName Sub Accounts'),
      ),
      body: FutureBuilder<Uint8List>(
        future: _generatePdfBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No PDF data available'));
          }
          return SfPdfViewer.memory(snapshot.data!, key: UniqueKey());
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SpeedDial(
            heroTag: 'download',
            onPress: () async {
              final pdfBytes = await _generatePdfBytes();
              await SavePDF()
                  .downloadPdf(context, pdfBytes, accountName, 'Sub Accounts');
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
    );
  }

  Future<Uint8List> _generatePdfBytes() async {
    final generator = AllSubAccountPDFGenerator(
      accountName: accountName,
      subAccountTransactions: subcAccountTransactions,
      startDate: startDate,
      endDate: endDate,
    );
    return generator.generatePdfBytes();
  }
}

class AllSubAccountPDFGenerator {
  final String accountName;
  final Map<String, List<TransactionModel>> subAccountTransactions;
  final DateTime startDate;
  final DateTime endDate;

  AllSubAccountPDFGenerator({
    required this.accountName,
    required this.subAccountTransactions,
    required this.startDate,
    required this.endDate,
  });
  Future<Uint8List> generatePdfBytes() async {
    final document = await _generatePdf();
    return Uint8List.fromList(document.saveSync());
  }

  Future<PdfDocument> _generatePdf() async {
    final document = PdfDocument();

    for (var entry in subAccountTransactions.entries) {
      final page = document.pages.add();
      _addStylishHeader(page, entry.key);
      _addTransactionTable(page, entry.value);
    }

    return document;
  }

  void _addStylishHeader(PdfPage page, String subAccountName) {
    final headerText = PdfTextElement(
      text: '$accountName - $subAccountName',
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

  void _addTransactionTable(PdfPage page, List<TransactionModel> transactions) {
    final header = [
      'Date',
      'Category',
      'Description',
      'Payment',
      'Receipt',
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
    for (var transaction in transactions) {
      final row = table.rows.add();
      row.cells[0].value = DateFormat('dd MMM yyyy').format(transaction.date);
      row.cells[1].value = transaction.fromAccount;
      row.cells[2].value = transaction.description;
      if (transaction.transactionType == TransactionType.payment) {
        row.cells[3].value = transaction.amount.toStringAsFixed(2);
        row.cells[4].value = '';
        runningBalance -= transaction.amount;
      } else if (transaction.transactionType == TransactionType.receipt) {
        row.cells[3].value = '';
        row.cells[4].value = transaction.amount.toStringAsFixed(2);
        runningBalance += transaction.amount;
      } else {
        row.cells[3].value = transaction.amount.toStringAsFixed(2);
        row.cells[4].value = transaction.amount.toStringAsFixed(2);
        runningBalance += 0;
      }
      row.cells[5].value = runningBalance.toStringAsFixed(2);
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

    table.draw(
      page: page,
      bounds: Rect.fromLTWH(
          0, 70, page.getClientSize().width, page.getClientSize().height - 70),
    );
  }
}
