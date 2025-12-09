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

class DailyxpensePdfGenerator {
  final DateTime selectedDate;
  final Box<TransactionModel> transactionBox;
  final Box<AttendanceModel> attendanceBox;

  DailyxpensePdfGenerator({
    required this.selectedDate,
    required this.transactionBox,
    required this.attendanceBox,
  });

  Future<String> generatePaymentPdfReport() async {
    // Filter Payment transactions for the selected date
    final filteredTransactions = transactionBox.values.where((transaction) {
      return transaction.date.year == selectedDate.year &&
          transaction.date.month == selectedDate.month &&
          transaction.date.day == selectedDate.day &&
          transaction.transactionType == TransactionType.payment;
    }).toList();

    // Filter Attendance records for the selected date
    final filteredAttendance = attendanceBox.values.where((attendance) {
      return attendance.date.year == selectedDate.year &&
          attendance.date.month == selectedDate.month &&
          attendance.date.day == selectedDate.day;
    }).toList();

    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    // Add title to the page
    page.graphics.drawString(
      'Daily Payment Report - ${DateFormat('dd MMMM yyyy').format(selectedDate)}',
      PdfStandardFont(PdfFontFamily.helvetica, 20),
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 6);
    grid.headers.add(1);

    PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Time';
    header.cells[3].value = 'Description';
    header.cells[1].value = 'Category';
    header.cells[2].value = 'Sub-Category';
    header.cells[4].value = 'Amount';
    header.cells[5].value = 'Account';

    header.style.backgroundBrush = PdfSolidBrush(PdfColor(255, 0, 0));
    header.style.textBrush = PdfBrushes.white;
    header.style.font =
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

    double totalPayment = 0;

    // Add Payment transactions
    for (var transaction in filteredTransactions) {
      PdfGridRow row = grid.rows.add();
      row.cells[0].value = DateFormat('HH:mm').format(transaction.date);
      row.cells[3].value = transaction.description;
      row.cells[1].value = transaction.categoryName ?? '';
      row.cells[2].value =
          transaction.subCategory ?? transaction.generalSubCategory ?? '';
      row.cells[4].value = transaction.amount.toStringAsFixed(1);
      row.cells[5].value = transaction.fromAccount;

      totalPayment += transaction.amount;
    }

    // Add Attendance records as payments
    for (var attendance in filteredAttendance) {
      PdfGridRow row = grid.rows.add();
      row.cells[0].value = DateFormat('HH:mm').format(attendance.date);
      row.cells[3].value = attendance.description;
      row.cells[1].value = attendance.categoryName;
      row.cells[2].value = attendance.subName;
      row.cells[4].value = attendance.payment.toStringAsFixed(1);
      row.cells[5].value = attendance.account;

      totalPayment += attendance.payment;
    }

    // Add total row
    PdfGridRow totalRow = grid.rows.add();
    totalRow.cells[2].value = 'Total Payment';
    totalRow.cells[4].value = totalPayment.toStringAsFixed(1);

    PdfGridCellStyle totalStyle = PdfGridCellStyle();
    totalStyle.backgroundBrush = PdfSolidBrush(PdfColor(255, 200, 200));
    totalStyle.font =
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    totalRow.cells[2].style = totalStyle;
    totalRow.cells[4].style = totalStyle;

    grid.style.cellPadding = PdfPaddings(left: 5, right: 5, top: 3, bottom: 3);

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(
          0, 50, page.getClientSize().width, page.getClientSize().height - 50),
    );

    List<int> bytes = await document.save();
    Uint8List uint8List = Uint8List.fromList(bytes);
    final fileName =
        'Daily_Payment_Report_${DateFormat('dd_MM_yyyy').format(selectedDate)}.pdf';
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
