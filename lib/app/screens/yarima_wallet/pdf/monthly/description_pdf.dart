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


class DescriptionPdf {
  Future<String> generateFilteredPdfReport(
    DateTime selectedMonth,
    Box<TransactionModel> transactionBox,
    Box<AttendanceModel> attendanceBox,
    String filter,
    BuildContext context,
  ) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    // Add title
    page.graphics.drawString(
      'Filtered Transaction Report',
      PdfStandardFont(PdfFontFamily.helvetica, 20),
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );

    // Initialize PDF grid with headers
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 9);
    grid.headers.add(1);

    PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Date';
    header.cells[1].value = 'Receipt';
    header.cells[2].value = 'Payment';
    header.cells[3].value = 'Transfer';
    header.cells[4].value = 'Account';
    header.cells[5].value = 'Category';
    header.cells[6].value = 'Sub-Category';
    header.cells[7].value = 'Description';
    header.cells[8].value = 'Balance';

    header.style.backgroundBrush = PdfSolidBrush(PdfColor(179, 220, 255));
    header.style.textBrush = PdfBrushes.black;
    header.style.font = PdfStandardFont(PdfFontFamily.helvetica, 11);

    // Variables to calculate totals
    double totalReceipt = 0;
    double totalPayment = 0;
    double totalTransfer = 0;
    double totalAttendanceReceipt = 0;
    double runningBalance = 0;

    // Process transactions from transaction box
    final filteredTransactions = transactionBox.values.where((transaction) {
      return transaction.description
          .toLowerCase()
          .contains(filter.toLowerCase());
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (var transaction in filteredTransactions) {
      // Determine amounts based on transaction type
      double receipt = 0;
      double payment = 0;
      double transfer = 0;

      if (transaction.transactionType == TransactionType.receipt) {
        receipt = transaction.amount;
        totalReceipt += receipt;
        runningBalance += receipt;
      } else if (transaction.transactionType == TransactionType.payment) {
        payment = transaction.amount;
        totalPayment += payment;
        runningBalance -= payment;
      } else if (transaction.transactionType == TransactionType.transfer) {
        transfer = transaction.amount;
        totalTransfer += transfer;
        // Transfer doesn't affect running balance
      }

      // Add transaction details to PDF grid
      PdfGridRow row = grid.rows.add();
      row.cells[0].value = DateFormat('dd/MM/yyyy').format(transaction.date);
      row.cells[1].value = receipt > 0 ? receipt.toStringAsFixed(2) : '';
      row.cells[2].value = payment > 0 ? payment.toStringAsFixed(2) : '';
      row.cells[3].value = transfer > 0 ? transfer.toStringAsFixed(2) : '';
      row.cells[4].value = transaction.fromAccount;
      row.cells[5].value = transaction.categoryName ?? '';
      row.cells[6].value =
          transaction.subCategory ?? transaction.generalSubCategory ?? '';
      row.cells[7].value = transaction.description;
      row.cells[8].value = runningBalance.toStringAsFixed(2);
    }

    // Process Attendance Records
    final filteredAttendance = attendanceBox.values.where((attendance) {
      return attendance.description
          .toLowerCase()
          .contains(filter.toLowerCase());
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Add attendance records to the grid
    for (var attendance in filteredAttendance) {
      // Attendance records with negative payment are considered receipts
      if (attendance.payment < 0) {
        double attendanceReceipt = attendance.payment.abs();
        totalAttendanceReceipt += attendanceReceipt;
        runningBalance += attendanceReceipt;

        PdfGridRow row = grid.rows.add();
        row.cells[0].value = DateFormat('dd/MM/yyyy').format(attendance.date);
        row.cells[1].value = attendanceReceipt.toStringAsFixed(2);
        row.cells[2].value = ''; // Payment column
        row.cells[3].value = ''; // Transfer column
        row.cells[4].value = attendance.account;
        row.cells[5].value = attendance.categoryName;
        row.cells[6].value = attendance.subName;
        row.cells[7].value = attendance.description;
        row.cells[8].value = runningBalance.toStringAsFixed(2);
      }
    }

    // Add totals row to the grid
    PdfGridRow totalRow = grid.rows.add();
    totalRow.cells[0].value = 'Totals';
    totalRow.cells[1].value =
        (totalReceipt + totalAttendanceReceipt).toStringAsFixed(2);
    totalRow.cells[2].value = totalPayment.toStringAsFixed(2);
    totalRow.cells[3].value = totalTransfer.toStringAsFixed(2);
    totalRow.cells[8].value = runningBalance.toStringAsFixed(2);

    // Style totals row
    PdfGridCellStyle totalRowStyle = PdfGridCellStyle();
    totalRowStyle.backgroundBrush = PdfSolidBrush(PdfColor(200, 200, 200));
    totalRowStyle.font =
        PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);
    for (int i = 0; i < totalRow.cells.count; i++) {
      totalRow.cells[i].style = totalRowStyle;
    }

    // Draw the grid on the PDF page
    grid.style.cellPadding = PdfPaddings(left: 5, right: 5, top: 3, bottom: 3);
    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(
          0, 50, page.getClientSize().width, page.getClientSize().height - 50),
    );
    final fileName =
        'Filtered_Report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf';
    // Save and return the file path
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
