import 'dart:io';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/yearlytab.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class YearlyTransferPDF {
  Future<String> generateYearlyTransfersPDF(
    Box<TransactionModel> yearlyTransactionBox,
    DateTime selectedYear,
    Map<String, Map<String, dynamic>> yearlyData,
    double closingBalance,
  ) async {
    final PdfDocument document = PdfDocument();
    document.pageSettings.margins.all = 20;

    for (final month in YearlyTab.orderedMonths) {
      final monthYear = '$month ${selectedYear.year}';
      final data = yearlyData[monthYear];
      if (data != null) {
        PdfPage page = document.pages.add();
        double yOffset = 20;

        final PdfFont monthFont = PdfStandardFont(PdfFontFamily.helvetica, 16,
            style: PdfFontStyle.bold);
        final Size monthSize = monthFont.measureString(monthYear);
        page.graphics.drawString(monthYear, monthFont,
            brush: PdfSolidBrush(PdfColor(0, 0, 0)),
            bounds: Rect.fromLTWH(
                0, yOffset, page.getClientSize().width, monthSize.height),
            format: PdfStringFormat(alignment: PdfTextAlignment.center));
        yOffset += monthSize.height + 20;

        final PdfGrid monthlyGrid = PdfGrid();
        monthlyGrid.columns.add(count: 5);
        monthlyGrid.headers.add(1);

        final PdfGridRow monthlyHeader = monthlyGrid.headers[0];
        monthlyHeader.cells[0].value = 'Date';
        monthlyHeader.cells[1].value = 'Description';
        monthlyHeader.cells[2].value = 'From Account';
        monthlyHeader.cells[3].value = 'To Account';
        monthlyHeader.cells[4].value = 'Amount';

        final monthIndex = YearlyTab.monthIndexMapping[month]!;
        final monthStart = DateTime(selectedYear.year, monthIndex, 1);
        final monthEnd = DateTime(selectedYear.year, monthIndex + 1, 0);

        final List<TransactionModel> transactions = yearlyTransactionBox.values
            .where((transaction) =>
                transaction.date
                    .isAfter(monthStart.subtract(const Duration(days: 1))) &&
                transaction.date
                    .isBefore(monthEnd.add(const Duration(days: 1))) &&
                transaction.transactionType == TransactionType.transfer)
            .toList();

        transactions.sort((a, b) => a.date.compareTo(b.date));

        double totalReceipts = 0;

        for (final transaction in transactions) {
          final PdfGridRow row = monthlyGrid.rows.add();
          row.cells[0].value =
              DateFormat('dd/MM/yyyy').format(transaction.date);
          row.cells[1].value = transaction.description;
          row.cells[2].value = transaction.fromAccount;
          row.cells[3].value = transaction.toAccount;
          row.cells[4].value = transaction.amount.toStringAsFixed(1);

          totalReceipts += transaction.amount;
        }

        // Add summary row
        final PdfGridRow summaryRow = monthlyGrid.rows.add();
        summaryRow.cells[0].value = 'Monthly Total';
        summaryRow.cells[1].value = '';
        summaryRow.cells[2].value = '';
        summaryRow.cells[3].value = '';
        summaryRow.cells[4].value = totalReceipts.toStringAsFixed(1);

        // Style the summary row
        for (int i = 0; i < summaryRow.cells.count; i++) {
          summaryRow.cells[i].style.backgroundBrush =
              PdfSolidBrush(PdfColor(220, 220, 220));
          summaryRow.cells[i].style.font = PdfStandardFont(
              PdfFontFamily.helvetica, 10,
              style: PdfFontStyle.bold);
        }

        monthlyGrid.style.cellPadding =
            PdfPaddings(left: 5, right: 5, top: 5, bottom: 5);
        for (int i = 0; i < monthlyHeader.cells.count; i++) {
          monthlyHeader.cells[i].style.backgroundBrush =
              PdfSolidBrush(PdfColor(179, 220, 255));
          monthlyHeader.cells[i].style.font = PdfStandardFont(
              PdfFontFamily.helvetica, 10,
              style: PdfFontStyle.bold);
        }

        monthlyGrid.draw(
          page: page,
          bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 0),
        );
      }
    }

    List<int> bytes = await document.save();
    document.dispose();
    String filePath;
    if (kIsWeb) {
      // For web, use file_saver to download
      await FileSaver.instance.saveFile(
        name: 'yearly_Receipt_report_${selectedYear.year}.pdf',
        bytes: Uint8List.fromList(bytes),
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      filePath = 'downloaded/yearly_Receipt_report_${selectedYear.year}.pdf';
    } else {
      // For mobile/desktop, use path_provider
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;

      filePath = '$appDocPath/yearly_Receipt_report_${selectedYear.year}.pdf';

      final File file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
    }

    return filePath;
  }
}
