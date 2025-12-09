import 'dart:io';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';


class MonthlyReceiptPDF {
  Future<String> generateMonthlyReceiptsPdfReport(
    DateTime selectedMonth,
    Map<String, List<TransactionModel>> transactionsByMonth,
    Box<AttendanceModel> attendanceBox,
    BuildContext context,
  ) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    // Add title to the page
    page.graphics.drawString(
      'Monthly Receipts Report - ${DateFormat('MMMM yyyy').format(selectedMonth)}',
      PdfStandardFont(PdfFontFamily.helvetica, 20),
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 6); // Added one column for Type
    grid.headers.add(1);

    PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Date';
    header.cells[1].value = 'Category';
    header.cells[2].value = 'Sub-Category';
    header.cells[3].value = 'Description';
    header.cells[4].value = 'Account';
    header.cells[5].value = 'Amount';

    header.style.backgroundBrush = PdfSolidBrush(PdfColor(179, 220, 255));
    header.style.textBrush = PdfBrushes.black;
    header.style.font = PdfStandardFont(PdfFontFamily.helvetica, 11);

    final selectedMonthKey = DateFormat('yyyy-MM').format(selectedMonth);
    double totalTransactionAmount = 0;
    double totalAttendanceAmount = 0;

    // Process regular transactions
    transactionsByMonth.forEach((date, transactions) {
      if (date.startsWith(selectedMonthKey)) {
        for (var transaction in transactions) {
          if (transaction.transactionType == TransactionType.receipt) {
            PdfGridRow row = grid.rows.add();
            row.cells[0].value =
                DateFormat('dd/MM/yyyy').format(transaction.date);
            row.cells[1].value = transaction.categoryName ?? '';
            row.cells[2].value =
                transaction.subCategory ?? transaction.generalSubCategory ?? '';
            row.cells[3].value = transaction.description;
            row.cells[4].value = transaction.fromAccount;
            row.cells[5].value = transaction.amount.toStringAsFixed(1);
            totalTransactionAmount += transaction.amount;
          }
        }
      }
    });

    // Filter and process attendance records for the selected month
    final filteredAttendance = attendanceBox.values.where((attendance) {
      return attendance.date.year == selectedMonth.year &&
          attendance.date.month == selectedMonth.month &&
          attendance.payment <
              0; // Only include receipts (negative payments are receipts)
    }).toList();

    // Process attendance records
    for (var attendance in filteredAttendance) {
      PdfGridRow row = grid.rows.add();
      row.cells[0].value = DateFormat('dd/MM/yyyy').format(attendance.date);
      row.cells[1].value = attendance.categoryName;
      row.cells[2].value = attendance.subName;
      row.cells[3].value = attendance.description;
      row.cells[4].value = attendance.account;
      row.cells[5].value = attendance.payment
          .abs()
          .toStringAsFixed(1); // Use abs() for positive display
      totalAttendanceAmount += attendance.payment.abs();
    }

    // Add subtotal rows
    if (totalTransactionAmount > 0) {
      PdfGridRow transactionSubtotalRow = grid.rows.add();
      transactionSubtotalRow.cells[3].value = 'Transaction Subtotal:';
      transactionSubtotalRow.cells[4].value =
          totalTransactionAmount.toStringAsFixed(1);
      transactionSubtotalRow.style.backgroundBrush =
          PdfSolidBrush(PdfColor(230, 230, 230));
      transactionSubtotalRow.style.font = PdfStandardFont(
          PdfFontFamily.helvetica, 10,
          style: PdfFontStyle.bold);
    }

    if (totalAttendanceAmount > 0) {
      PdfGridRow attendanceSubtotalRow = grid.rows.add();
      attendanceSubtotalRow.cells[3].value = 'Attendance Subtotal:';
      attendanceSubtotalRow.cells[4].value =
          totalAttendanceAmount.toStringAsFixed(1);
      attendanceSubtotalRow.style.backgroundBrush =
          PdfSolidBrush(PdfColor(230, 230, 230));
      attendanceSubtotalRow.style.font = PdfStandardFont(
          PdfFontFamily.helvetica, 10,
          style: PdfFontStyle.bold);
    }

    // Add grand total row
    PdfGridRow totalRow = grid.rows.add();
    totalRow.cells[3].value = 'Total Receipts:';
    totalRow.cells[4].value =
        (totalTransactionAmount + totalAttendanceAmount).toStringAsFixed(1);
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
        'Monthly_Receipts_${DateFormat('MMM_yyyy').format(selectedMonth)}.pdf';
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
