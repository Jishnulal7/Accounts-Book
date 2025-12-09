import 'dart:io';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class MonthlyTransfersPDF {
  Future<String> generateMonthlyTransfersPdfReport(
    DateTime selectedMonth,
    Map<String, List<TransactionModel>> transactionsByMonth,
    BuildContext context,
  ) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    // Add title to the page
    page.graphics.drawString(
      'Monthly Transfers Report - ${DateFormat('MMMM yyyy').format(selectedMonth)}',
      PdfStandardFont(PdfFontFamily.helvetica, 20),
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 5);
    grid.headers.add(1);

    PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Date';
    header.cells[1].value = 'Description';
    header.cells[2].value = 'From Account';
    header.cells[3].value = 'To Account';
    header.cells[4].value = 'Amount';

    header.style.backgroundBrush = PdfSolidBrush(PdfColor(179, 220, 255));
    header.style.textBrush = PdfBrushes.black;
    header.style.font = PdfStandardFont(PdfFontFamily.helvetica, 11);

    final selectedMonthKey = DateFormat('yyyy-MM').format(selectedMonth);
    double totalAmount = 0;

    transactionsByMonth.forEach((date, transactions) {
      if (date.startsWith(selectedMonthKey)) {
        for (var transaction in transactions) {
          if (transaction.transactionType == TransactionType.transfer) {
            PdfGridRow row = grid.rows.add();
            row.cells[0].value =
                DateFormat('dd/MM/yyyy').format(transaction.date);
            row.cells[1].value = transaction.description;
            row.cells[2].value = transaction.fromAccount;
            row.cells[3].value = transaction.toAccount;
            row.cells[4].value = transaction.amount.toStringAsFixed(1);
            totalAmount += transaction.amount;
          }
        }
      }
    });

    // Add total row
    PdfGridRow totalRow = grid.rows.add();
    totalRow.cells[3].value = 'Total Transfers:';
    totalRow.cells[4].value = totalAmount.toStringAsFixed(1);
    totalRow.style.backgroundBrush = PdfSolidBrush(PdfColor(200, 200, 200));
    totalRow.style.font =
        PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);

    grid.style.cellPadding = PdfPaddings(left: 5, right: 5, top: 3, bottom: 3);

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(
          0, 50, page.getClientSize().width, page.getClientSize().height - 50),
    );
    final fileName =
        'Monthly_Transfers_${DateFormat('MMM_yyyy').format(selectedMonth)}.pdf';

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
}
