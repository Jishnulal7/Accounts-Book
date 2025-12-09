import 'dart:io';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/daily_pdf.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DailyPdfGenerator {
  final DateTime selectedDate;
  final double openingBalance;
  final Box<TransactionModel> transactionBox;
  final Box<AttendanceModel> attendanceBox;
  final BuildContext context;

  DailyPdfGenerator({
    required this.selectedDate,
    required this.context,
    required this.openingBalance,
    required this.transactionBox,
    required this.attendanceBox,
  });

  Future<String> generateDailyPdfReport() async {
    // Filter transactions for the selected date
    final filteredTransactions = transactionBox.values.where((transaction) {
      return transaction.date.year == selectedDate.year &&
          transaction.date.month == selectedDate.month &&
          transaction.date.day == selectedDate.day;
    }).toList();

    // Filter attendance records for the selected date
    final filteredAttendance = attendanceBox.values.where((attendance) {
      return attendance.date.year == selectedDate.year &&
          attendance.date.month == selectedDate.month &&
          attendance.date.day == selectedDate.day;
    }).toList();

    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    // Add title to the page
    page.graphics.drawString(
      'Daily Transaction Report - ${DateFormat('dd MMMM yyyy').format(selectedDate)}',
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
    header.cells[0].value = 'Time';
    header.cells[1].value = 'Category';
    header.cells[2].value = 'Sub-Category';
    header.cells[3].value = 'Description';
    header.cells[4].value = 'Account';
    header.cells[5].value = 'Receipt';
    header.cells[6].value = 'Payment';
    header.cells[7].value = 'Balance';
    header.style.backgroundBrush = PdfSolidBrush(PdfColor(179, 220, 255));
    header.style.textBrush = PdfBrushes.black;
    header.style.font = PdfStandardFont(PdfFontFamily.helvetica, 10);

    double runningBalance = openingBalance;
    double totalReceipt = 0;
    double totalPayment = 0;

    // Add opening balance row
    PdfGridRow openingBalanceRow = grid.rows.add();
    openingBalanceRow.cells[0].value = 'Opening Balance';
    openingBalanceRow.cells[7].value = openingBalance.toStringAsFixed(2);

    // Function to add a row to the grid
    void addRow(
      DateTime date,
      String categoryName,
      String? subCategory,
      String description,
      String account,
      double receipt,
      double payment,
    ) {
      PdfGridRow row = grid.rows.add();
      row.cells[0].value = DateFormat('HH:mm').format(date);
      row.cells[1].value = categoryName;
      row.cells[2].value = subCategory ?? '';
      row.cells[3].value = description;
      row.cells[4].value = account;
      row.cells[5].value = receipt > 0 ? receipt.toStringAsFixed(2) : '';
      row.cells[6].value = payment > 0 ? payment.toStringAsFixed(2) : '';

      if (receipt > 0) {
        runningBalance += receipt;
        totalReceipt += receipt;
      } else {
        runningBalance -= payment;
        totalPayment += payment;
      }

      row.cells[7].value = runningBalance.toStringAsFixed(2);
    }

    // Add transactions
    for (var transaction in filteredTransactions) {
      String categoryName = transaction.categoryName ?? '';
      String? subCategory =
          transaction.subCategory ?? transaction.generalSubCategory ?? '';
      double receipt = 0;
      double payment = 0;

      if (transaction.transactionType == TransactionType.receipt) {
        receipt = transaction.amount;
      } else {
        payment = transaction.amount;
      }

      addRow(
        transaction.date,
        categoryName,
        subCategory,
        transaction.description,
        transaction.fromAccount,
        receipt,
        payment,
      );
    }

    // Add attendance records
    for (var attendance in filteredAttendance) {
      addRow(
        attendance.date,
        attendance.generalCategoryName ?? attendance.categoryName ?? '',
        attendance.subName,
        attendance.description,
        attendance.account,
        0,
        attendance.payment,
      );
    }

    // Add total row
    PdfGridRow totalRow = grid.rows.add();
    totalRow.cells[0].value = 'Totals';
    totalRow.cells[5].value = totalReceipt.toStringAsFixed(2);
    totalRow.cells[6].value = totalPayment.toStringAsFixed(2);
    totalRow.cells[7].value = runningBalance.toStringAsFixed(2);

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
    document.dispose();

    final fileName =
        'Daily_Report_${DateFormat('dd_MM_yyyy').format(selectedDate)}.pdf';

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

  void viewPdf(
      BuildContext context, String pdfPath, int subIndex, int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyPdf(
          pdfPath: pdfPath,
          subIndex: subIndex,
          tabIndex: tabIndex,
          selectMonth: selectedDate,
        ),
      ),
    );
  }
}
