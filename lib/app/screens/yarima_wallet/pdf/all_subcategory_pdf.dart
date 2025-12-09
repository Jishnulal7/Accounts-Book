import 'dart:typed_data';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/components/save_pdf.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';


class AllSubcategoriesPDFScreen extends StatelessWidget {
  final String categoryName;
  final Map<String, List<TransactionModel>> subcategoryTransactions;
  final DateTime startDate;
  final DateTime endDate;

  const AllSubcategoriesPDFScreen({
    super.key,
    required this.categoryName,
    required this.subcategoryTransactions,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$categoryName Subcategories'),
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
              await SavePDF().downloadPdf(
                  context, pdfBytes, categoryName, 'Subcategories');
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
    );
  }

  Future<Uint8List> _generatePdfBytes() async {
    final generator = AllSubcategoriesPDFGenerator(
      categoryName: categoryName,
      subcategoryTransactions: subcategoryTransactions,
      startDate: startDate,
      endDate: endDate,
    );
    return generator.generatePdfBytes();
  }
}

class AllSubcategoriesPDFGenerator {
  final String categoryName;
  final Map<String, List<TransactionModel>> subcategoryTransactions;
  final DateTime startDate;
  final DateTime endDate;

  AllSubcategoriesPDFGenerator({
    required this.categoryName,
    required this.subcategoryTransactions,
    required this.startDate,
    required this.endDate,
  });

  Future<Uint8List> generatePdfBytes() async {
    final document = await _generatePdf();
    return Uint8List.fromList(document.saveSync());
  }

  Future<PdfDocument> _generatePdf() async {
    final document = PdfDocument();

    for (var entry in subcategoryTransactions.entries) {
      final page = document.pages.add();
      _addStylishHeader(page, entry.key);
      _addTransactionTable(page, entry.value);
    }

    return document;
  }

  void _addStylishHeader(PdfPage page, String subcategoryName) {
    final headerText = PdfTextElement(
      text: '$categoryName - $subcategoryName',
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
    final header = ['Date', 'Account', 'Description', 'Amount'];

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

    for (var transaction in transactions) {
      final row = table.rows.add();
      row.cells[0].value = DateFormat('dd MMM yyyy').format(transaction.date);
      row.cells[1].value = transaction.fromAccount;
      row.cells[2].value = transaction.description;
      row.cells[3].value = transaction.amount.toStringAsFixed(1);
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
