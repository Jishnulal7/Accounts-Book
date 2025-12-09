import 'dart:io';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart';

class DailyPaymentTransferPdfGenerator {
  final DateTime selectedDate;
  final Box<TransactionModel> transactionBox;

  DailyPaymentTransferPdfGenerator({
    required this.selectedDate,
    required this.transactionBox,
  });

  Future<String> generatePaymentTransferPdfReport() async {
    final paymentTransactions = transactionBox.values.where((transaction) {
      return transaction.date.year == selectedDate.year &&
          transaction.date.month == selectedDate.month &&
          transaction.date.day == selectedDate.day &&
          transaction.transactionType == TransactionType.payment;
    }).toList();

    final transferTransactions = transactionBox.values.where((transaction) {
      return transaction.date.year == selectedDate.year &&
          transaction.date.month == selectedDate.month &&
          transaction.date.day == selectedDate.day &&
          transaction.transactionType == TransactionType.transfer;
    }).toList();

    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    // Add title to the page
    page.graphics.drawString(
      'Daily Payment & Transfer Report - ${DateFormat('dd MMMM yyyy').format(selectedDate)}',
      PdfStandardFont(PdfFontFamily.helvetica, 20),
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );

    // Create and draw Payment grid
    final PdfGrid paymentGrid = createPaymentGrid(paymentTransactions);

    final PdfLayoutResult paymentResult = paymentGrid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 60, page.getClientSize().width, 0),
    )!;

    // Create and draw transfer grid
    final PdfGrid transferGrid = createTransferGrid(transferTransactions);

    final PdfLayoutResult transferResult = transferGrid.draw(
      page: page,
      bounds: Rect.fromLTWH(
          0, paymentResult.bounds.bottom + 20, page.getClientSize().width, 0),
    )!;

    // Add summary
    final double totalPayment =
        paymentTransactions.fold(0, (sum, item) => sum + item.amount);
    final double totalTransfer =
        transferTransactions.fold(0, (sum, item) => sum + item.amount);
    final double totalOutflow = totalPayment + totalTransfer;

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
        summaryGrid, 'Total Payment', totalPayment, PdfColor(255, 200, 200));
    addSummaryRow(
        summaryGrid, 'Total Transfer', totalTransfer, PdfColor(200, 200, 255));
    addSummaryRow(
        summaryGrid, 'Total Outflow', totalOutflow, PdfColor(255, 200, 255));

    summaryGrid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, transferResult.bounds.bottom + 20,
          page.getClientSize().width / 2, 0),
    );

    final fileName =
        'Daily_Payment_Transfer_Report_${DateFormat('dd_MM_yyyy').format(selectedDate)}.pdf';
    List<int> bytes = await document.save();
    Uint8List uint8List = Uint8List.fromList(bytes);

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

  PdfGrid createPaymentGrid(List<TransactionModel> transactions) {
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 6);
    grid.headers.add(1);

    PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Payments';
    header.cells[0].columnSpan = 6;

    header.style.backgroundBrush = PdfSolidBrush(PdfColor(255, 0, 0));
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
    totalRow.cells[3].value = 'Total Payments';
    totalRow.cells[4].value = total.toStringAsFixed(1);

    PdfGridCellStyle totalStyle = PdfGridCellStyle();
    totalStyle.backgroundBrush = PdfSolidBrush(PdfColor(255, 200, 200));
    totalStyle.font =
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    totalRow.cells[3].style = totalStyle;
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

  PdfGrid createTransferGrid(List<TransactionModel> transactions) {
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 5);
    grid.headers.add(1);

    PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Transfers';
    header.cells[0].columnSpan = 5;

    header.style.backgroundBrush = PdfSolidBrush(PdfColor(0, 0, 255));
    header.style.textBrush = PdfBrushes.white;
    header.style.font =
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);

    PdfGridRow subHeader = grid.rows.add();
    subHeader.cells[0].value = 'Time';
    subHeader.cells[1].value = 'Description';
    subHeader.cells[2].value = 'From Account';
    subHeader.cells[3].value = 'To Account';
    subHeader.cells[4].value = 'Amount';

    subHeader.style.backgroundBrush = PdfSolidBrush(PdfColor(200, 200, 200));
    subHeader.style.textBrush = PdfBrushes.black;
    subHeader.style.font =
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

    double total = 0;

    for (var transaction in transactions) {
      PdfGridRow row = grid.rows.add();
      row.cells[0].value = DateFormat('HH:mm').format(transaction.date);
      row.cells[1].value = transaction.description;
      row.cells[2].value = transaction.fromAccount;
      row.cells[3].value = transaction.toAccount;
      row.cells[4].value = transaction.amount.toStringAsFixed(1);

      total += transaction.amount;
    }

    // Add total row
    PdfGridRow totalRow = grid.rows.add();
    totalRow.cells[3].value = 'Total Transfers';
    totalRow.cells[4].value = total.toStringAsFixed(1);

    PdfGridCellStyle totalStyle = PdfGridCellStyle();
    totalStyle.backgroundBrush = PdfSolidBrush(PdfColor(200, 200, 255));
    totalStyle.font =
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    totalRow.cells[3].style = totalStyle;
    totalRow.cells[4].style = totalStyle;

    grid.style.cellPadding = PdfPaddings(left: 5, right: 5, top: 3, bottom: 3);

    return grid;
  }
}
