import 'dart:io';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class MonthlyPaymentAndTransfersPDF {
  Future<String> monthlyPaymentAndTransferPdfReport(
    DateTime selectedMonth,
    Map<String, List<TransactionModel>> transactionsByMonth,
    BuildContext context,
  ) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    page.graphics.drawString(
      'Monthly Payment & Transfer Report - ${DateFormat('MMMM yyyy').format(selectedMonth)}',
      PdfStandardFont(PdfFontFamily.helvetica, 20),
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 8);
    grid.headers.add(1);

    PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Date';
    header.cells[1].value = 'Category';
    header.cells[2].value = 'Sub-Category';
    header.cells[3].value = 'Description';
    header.cells[4].value = 'From Account';
    header.cells[5].value = 'To Account';
    header.cells[6].value = 'Payment';
    header.cells[7].value = 'Transfer';

    header.style.backgroundBrush = PdfSolidBrush(PdfColor(179, 220, 255));
    header.style.textBrush = PdfBrushes.black;
    header.style.font = PdfStandardFont(PdfFontFamily.helvetica, 10);

    final selectedMonthKey = DateFormat('yyyy-MM').format(selectedMonth);
    double totalPayments = 0;
    double totalTransfers = 0;

    transactionsByMonth.forEach((date, transactions) {
      if (date.startsWith(selectedMonthKey)) {
        for (var transaction in transactions.reversed) {
          if (transaction.transactionType == TransactionType.payment ||
              transaction.transactionType == TransactionType.transfer) {
            PdfGridRow row = grid.rows.add();
            row.cells[0].value =
                DateFormat('dd/MM/yyyy').format(transaction.date);
            row.cells[1].value = transaction.categoryName ?? '';
            row.cells[2].value =
                transaction.subCategory ?? transaction.generalSubCategory ?? '';
            row.cells[3].value = transaction.description;
            row.cells[4].value = transaction.fromAccount;

            switch (transaction.transactionType) {
              case TransactionType.payment:
                row.cells[5].value = ''; // To Account is empty for Payments
                row.cells[6].value = transaction.amount.toStringAsFixed(1);
                row.cells[7].value = '';
                totalPayments += transaction.amount;
                break;
              case TransactionType.transfer:
                row.cells[5].value = transaction.toAccount;
                row.cells[6].value = '';
                row.cells[7].value = transaction.amount.toStringAsFixed(1);
                totalTransfers += transaction.amount;
                break;
              default:
                // This case should not occur as we've filtered out receipts
                break;
            }
          }
        }
      }
    });

    // Add total row
    PdfGridRow totalRow = grid.rows.add();
    totalRow.cells[0].value = 'Totals';
    totalRow.cells[5].value = totalPayments.toStringAsFixed(1);
    totalRow.cells[6].value = totalTransfers.toStringAsFixed(1);

    // Style the total row
    PdfGridCellStyle totalRowStyle = PdfGridCellStyle();
    totalRowStyle.backgroundBrush = PdfSolidBrush(PdfColor(200, 200, 200));
    totalRowStyle.font =
        PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);

    for (int i = 0; i < totalRow.cells.count; i++) {
      totalRow.cells[i].style = totalRowStyle;
    }

    grid.style.cellPadding = PdfPaddings(left: 5, right: 5, top: 3, bottom: 3);

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(
          0, 50, page.getClientSize().width, page.getClientSize().height - 50),
    );

    List<int> bytes = await document.save();
    Uint8List uint8List = Uint8List.fromList(bytes);
    final fileName =
        'Monthly_Payment_Transfer_Report_${DateFormat('MMM_yyyy').format(selectedMonth)}.pdf';
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
}
