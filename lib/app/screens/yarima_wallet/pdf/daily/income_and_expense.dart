import 'dart:io';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DailyReceiptPaymentPdfGenerator {
  final DateTime selectedDate;
  final Box<TransactionModel> transactionBox;

  DailyReceiptPaymentPdfGenerator({
    required this.selectedDate,
    required this.transactionBox,
  });

  Future<String> generateReceiptPaymentPdfReport() async {
    final receiptTransactions = transactionBox.values.where((transaction) {
      return transaction.date.year == selectedDate.year &&
          transaction.date.month == selectedDate.month &&
          transaction.date.day == selectedDate.day &&
          transaction.transactionType == TransactionType.receipt;
    }).toList();

    final paymentTransactions = transactionBox.values.where((transaction) {
      return transaction.date.year == selectedDate.year &&
          transaction.date.month == selectedDate.month &&
          transaction.date.day == selectedDate.day &&
          transaction.transactionType == TransactionType.payment;
    }).toList();

    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    // Add title to the page
    page.graphics.drawString(
      'Daily Receipt & Payment Report - ${DateFormat('dd MMMM yyyy').format(selectedDate)}',
      PdfStandardFont(PdfFontFamily.helvetica, 20),
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );

    final PdfGrid receiptGrid = createTransactionGrid(
      'Receipt',
      receiptTransactions,
      PdfColor(0, 255, 0),
      PdfColor(200, 255, 200),
    );

    final PdfLayoutResult receiptResult = receiptGrid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 60, page.getClientSize().width, 0),
    )!;

    final PdfGrid paymentGrid = createTransactionGrid(
      'Payment',
      paymentTransactions,
      PdfColor(255, 0, 0),
      PdfColor(255, 200, 200),
    );

    final PdfLayoutResult paymentResult = paymentGrid.draw(
      page: page,
      bounds: Rect.fromLTWH(
          0, receiptResult.bounds.bottom + 20, page.getClientSize().width, 0),
    )!;

    // Add summary
    final double totalReceipt =
        receiptTransactions.fold(0, (sum, item) => sum + item.amount);
    final double totalPayment =
        paymentTransactions.fold(0, (sum, item) => sum + item.amount);
    final double netAmount = totalReceipt - totalPayment;

    final PdfGrid summaryGrid = PdfGrid();
    summaryGrid.columns.add(count: 2);
    summaryGrid.headers.add(1);

    PdfGridRow header = summaryGrid.headers[0];
    header.cells[0].value = 'Summary';
    header.cells[1].value = 'Amount';

    header.style.backgroundBrush = PdfSolidBrush(PdfColor(100, 100, 100));
    header.style.textBrush = PdfBrushes.white;
    header.style.font =
        PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);

    addSummaryRow(
        summaryGrid, 'Total Receipt', totalReceipt, PdfColor(200, 255, 200));
    addSummaryRow(
        summaryGrid, 'Total Payment', totalPayment, PdfColor(255, 200, 200));
    addSummaryRow(
        summaryGrid, 'Net Amount', netAmount, PdfColor(200, 200, 255));

    summaryGrid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, paymentResult.bounds.bottom + 20,
          page.getClientSize().width / 2, 0),
    );

    List<int> bytes = await document.save();
    Uint8List uint8List = Uint8List.fromList(bytes);
    final fileName =
        'Daily_Receipt_Payment_Report_${DateFormat('dd_MM_yyyy').format(selectedDate)}.pdf';
    document.dispose();

    if (kIsWeb) {
      // Web platform: Use HTML download
      return FileSaver.instance.saveFile(
        name: fileName,
        bytes: uint8List,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
    } else {
      // Mobile/Desktop platforms
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    }
  }

  PdfGrid createTransactionGrid(
      String title,
      List<TransactionModel> transactions,
      PdfColor headerColor,
      PdfColor totalColor) {
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 6);
    grid.headers.add(1);

    PdfGridRow header = grid.headers[0];
    header.cells[0].value = title;
    header.cells[0].columnSpan = 6;

    header.style.backgroundBrush = PdfSolidBrush(headerColor);
    header.style.textBrush = PdfBrushes.white;
    header.style.font =
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);

    PdfGridRow subHeader = grid.rows.add();
    subHeader.cells[0].value = 'Time';
    subHeader.cells[3].value = 'Description';
    subHeader.cells[1].value = 'Category';
    subHeader.cells[2].value = 'Sub-Category';
    subHeader.cells[4].value = 'Amount';
    subHeader.cells[5].value = 'Account';

    subHeader.style.backgroundBrush = PdfSolidBrush(PdfColor(200, 200, 200));
    subHeader.style.textBrush = PdfBrushes.black;
    subHeader.style.font =
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

    double total = 0;

    for (var transaction in transactions) {
      PdfGridRow row = grid.rows.add();
      row.cells[0].value = DateFormat('HH:mm').format(transaction.date);
      row.cells[3].value = transaction.description;
      row.cells[1].value = transaction.categoryName ?? '';
      row.cells[2].value =
          transaction.subCategory ?? transaction.generalSubCategory ?? '';
      row.cells[4].value = transaction.amount.toStringAsFixed(1);
      row.cells[5].value = transaction.fromAccount;

      total += transaction.amount;
    }

    // Add total row
    PdfGridRow totalRow = grid.rows.add();
    totalRow.cells[2].value = 'Total $title';
    totalRow.cells[4].value = total.toStringAsFixed(1);

    PdfGridCellStyle totalStyle = PdfGridCellStyle();
    totalStyle.backgroundBrush = PdfSolidBrush(totalColor);
    totalStyle.font =
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    totalRow.cells[2].style = totalStyle;
    totalRow.cells[4].style = totalStyle;

    grid.style.cellPadding = PdfPaddings(left: 5, right: 5, top: 3, bottom: 3);

    return grid;
  }

  void addSummaryRow(
      PdfGrid grid, String label, double amount, PdfColor color) {
    PdfGridRow row = grid.rows.add();
    row.cells[0].value = label;
    row.cells[1].value = amount.toStringAsFixed(1);

    PdfGridCellStyle style = PdfGridCellStyle();
    style.backgroundBrush = PdfSolidBrush(color);
    style.font =
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    row.cells[0].style = style;
    row.cells[1].style = style;
  }
}
