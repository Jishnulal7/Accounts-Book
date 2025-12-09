import 'dart:typed_data';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/components/save_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';


class AllGeneralSubCatgoryPDf extends StatelessWidget {
  final String categoryName;
  final Map<String, List<TransactionModel>> subcategoryTransactions;
  final DateTime startDate;
  final DateTime endDate;

  const AllGeneralSubCatgoryPDf({
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
        title: Text('$categoryName Report'),
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
                  context, pdfBytes, categoryName, 'Report');
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
    final generator = CombinedPDFGenerator(
      categoryName: categoryName,
      subcategoryTransactions: subcategoryTransactions,
      startDate: startDate,
      endDate: endDate,
    );
    return generator.generatePdfBytes();
  }
}

class CombinedPDFGenerator {
  final String categoryName;
  final Map<String, List<TransactionModel>> subcategoryTransactions;
  final DateTime startDate;
  final DateTime endDate;

  CombinedPDFGenerator({
    required this.categoryName,
    required this.subcategoryTransactions,
    required this.startDate,
    required this.endDate,
  });

  Future<Uint8List> generatePdfBytes() async {
    final document = PdfDocument();
    final page = document.pages.add();
    
    double yOffset = 0;
    
    // Add main header
    yOffset = _addMainHeader(page, yOffset);
    
    // Add summary section
    yOffset = _addSummarySection(page, yOffset);
    
    // Add all transactions
    _addAllTransactions(page, yOffset);

    return Uint8List.fromList(document.saveSync());
  }

  double _addMainHeader(PdfPage page, double yOffset) {
    final headerText = PdfTextElement(
      text: '$categoryName Report',
      font: PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold),
    );
    headerText.draw(page: page, bounds: Rect.fromLTWH(0, yOffset, 0, 0));

    yOffset += 30;

    final dateRangeText = PdfTextElement(
      text: 'From ${DateFormat('dd MMM yyyy').format(startDate)} to ${DateFormat('dd MMM yyyy').format(endDate)}',
      font: PdfStandardFont(PdfFontFamily.helvetica, 14),
    );
    dateRangeText.draw(page: page, bounds: Rect.fromLTWH(0, yOffset, 0, 0));

    yOffset += 25;

    final graphics = page.graphics;
    graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0), width: 1),
      Offset(0, yOffset),
      Offset(page.getClientSize().width, yOffset),
    );

    return yOffset + 20;
  }

  double _addSummarySection(PdfPage page, double yOffset) {
    double totalPayments = 0;
    double totalReceipts = 0;

    // Calculate totals for all subcategories
    for (var transactions in subcategoryTransactions.values) {
      for (var transaction in transactions) {
        if (transaction.transactionType == TransactionType.payment) {
          totalPayments += transaction.amount;
        } else if (transaction.transactionType == TransactionType.receipt) {
          totalReceipts += transaction.amount;
        } else if (transaction.transactionType == TransactionType.transfer) {
          if (transaction.fromAccount == categoryName) {
            totalPayments += transaction.amount;
          } else {
            totalReceipts += transaction.amount;
          }
        }
      }
    }

    final summaryText = PdfTextElement(
      text: 'Summary',
      font: PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
    );
    summaryText.draw(page: page, bounds: Rect.fromLTWH(0, yOffset, 0, 0));

    yOffset += 25;

    final summaryGrid = PdfGrid();
    summaryGrid.columns.add(count: 2);
    
    // Add summary rows
    final rows = [
      ['Total Payments:', totalPayments.toStringAsFixed(1)],
      ['Total Receipts:', totalReceipts.toStringAsFixed(1)],
      ['Net Total:', (totalReceipts - totalPayments).toStringAsFixed(1)],
    ];

    for (var row in rows) {
      final gridRow = summaryGrid.rows.add();
      gridRow.cells[0].value = row[0];
      gridRow.cells[1].value = row[1];
    }

    // Style summary grid
    for (int i = 0; i < summaryGrid.rows.count; i++) {
      final row = summaryGrid.rows[i];
      for (int j = 0; j < row.cells.count; j++) {
        row.cells[j].style.font = PdfStandardFont(
          PdfFontFamily.helvetica, 12,
          style: i == summaryGrid.rows.count - 1 ? PdfFontStyle.bold : PdfFontStyle.regular,
        );
      }
    }

    summaryGrid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width / 2, 0),
    );

    return yOffset + 80;
  }

  void _addAllTransactions(PdfPage page, double yOffset) {
    final header = [
      'Date',
      'Subcategory',
      'Account',
      'Description',
      'Payment',
      'Receipt',
    ];

    final table = PdfGrid();
    table.columns.add(count: header.length);
    table.headers.add(1);
    final headerRow = table.headers[0];

    // Style header row
    for (int i = 0; i < header.length; i++) {
      headerRow.cells[i].value = header[i];
      headerRow.cells[i].style.backgroundBrush = PdfSolidBrush(PdfColor(66, 133, 244));
      headerRow.cells[i].style.textBrush = PdfBrushes.white;
      headerRow.cells[i].style.font = PdfStandardFont(
        PdfFontFamily.helvetica, 12,
        style: PdfFontStyle.bold,
      );
    }

    // Add all transactions sorted by date
    List<TransactionData> allTransactions = [];
    
    for (var entry in subcategoryTransactions.entries) {
      final subcategoryName = entry.key;
      for (var transaction in entry.value) {
        allTransactions.add(TransactionData(
          subcategoryName: subcategoryName,
          transaction: transaction,
        ));
      }
    }

    // Sort all transactions by date
    allTransactions.sort((a, b) => a.transaction.date.compareTo(b.transaction.date));

    // Add rows for all transactions
    for (var transactionData in allTransactions) {
      final row = table.rows.add();
      final transaction = transactionData.transaction;
      
      row.cells[0].value = DateFormat('dd MMM yyyy').format(transaction.date);
      row.cells[1].value = transactionData.subcategoryName;
      row.cells[2].value = _getAccountName(transaction);
      row.cells[3].value = transaction.description;

      if (transaction.transactionType == TransactionType.payment) {
        row.cells[4].value = transaction.amount.toStringAsFixed(1);
        row.cells[5].value = '';
      } else if (transaction.transactionType == TransactionType.receipt) {
        row.cells[4].value = '';
        row.cells[5].value = transaction.amount.toStringAsFixed(1);
      } else if (transaction.transactionType == TransactionType.transfer) {
        if (transaction.fromAccount == categoryName) {
          row.cells[4].value = transaction.amount.toStringAsFixed(1);
          row.cells[5].value = '';
        } else {
          row.cells[4].value = '';
          row.cells[5].value = transaction.amount.toStringAsFixed(1);
        }
      }
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

    // Draw the table
    table.draw(
      page: page,
      bounds: Rect.fromLTWH(
        0,
        yOffset,
        page.getClientSize().width,
        page.getClientSize().height - yOffset,
      ),
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

class TransactionData {
  final String subcategoryName;
  final TransactionModel transaction;

  TransactionData({
    required this.subcategoryName,
    required this.transaction,
  });
}