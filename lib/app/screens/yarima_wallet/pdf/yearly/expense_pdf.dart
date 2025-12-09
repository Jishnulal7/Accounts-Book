import 'dart:io';
import 'dart:ui';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/yearlytab.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class YearlyPaymentPDF {
  Future<String> generateYearlyPaymentPDF(
    Box<TransactionModel> yearlyTransactionBox,
    Box<AttendanceModel> attendanceBox,
    DateTime selectedYear,
    Map<String, Map<String, dynamic>> yearlyData,
    double closingBalance,
  ) async {
    final PdfDocument document = PdfDocument();
    document.pageSettings.margins.all = 20;

    PdfPage page = document.pages.add();

    final PdfFont titleFont =
        PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final Size titleSize =
        titleFont.measureString('Yearly Payment Report ${selectedYear.year}');
    page.graphics.drawString(
        'Yearly Payment Report ${selectedYear.year}', titleFont,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds:
            Rect.fromLTWH(0, 0, page.getClientSize().width, titleSize.height),
        format: PdfStringFormat(alignment: PdfTextAlignment.center));

    double yOffset = titleSize.height + 20;

    final PdfGrid yearlyGrid = PdfGrid();
    yearlyGrid.columns.add(count: 2);
    yearlyGrid.headers.add(1);

    final PdfGridRow yearlyHeader = yearlyGrid.headers[0];
    yearlyHeader.cells[0].value = 'Month';
    yearlyHeader.cells[1].value = 'Total Payments';

    double yearlyTotalPayments = 0;

    for (final month in YearlyTab.orderedMonths) {
      final monthYear = '$month ${selectedYear.year}';
      final data = yearlyData[monthYear];
      final PdfGridRow row = yearlyGrid.rows.add();
      row.cells[0].value = month;

      double monthlyPayments =
          data != null ? double.parse(data['totalPayments'].toString()) : 0;

      yearlyTotalPayments += monthlyPayments;

      row.cells[1].value = monthlyPayments.toStringAsFixed(1);
    }

    // Add yearly total row
    final PdfGridRow yearlyTotalRow = yearlyGrid.rows.add();
    yearlyTotalRow.cells[0].value = 'Yearly Total';
    yearlyTotalRow.cells[1].value = yearlyTotalPayments.toStringAsFixed(1);

    // Style the yearly total row
    for (int i = 0; i < yearlyTotalRow.cells.count; i++) {
      yearlyTotalRow.cells[i].style.backgroundBrush =
          PdfSolidBrush(PdfColor(220, 220, 220));
      yearlyTotalRow.cells[i].style.font = PdfStandardFont(
          PdfFontFamily.helvetica, 10,
          style: PdfFontStyle.bold);
    }

    yearlyGrid.style.cellPadding =
        PdfPaddings(left: 5, right: 5, top: 5, bottom: 5);
    for (int i = 0; i < yearlyHeader.cells.count; i++) {
      yearlyHeader.cells[i].style.backgroundBrush =
          PdfSolidBrush(PdfColor(179, 220, 255));
      yearlyHeader.cells[i].style.font = PdfStandardFont(
          PdfFontFamily.helvetica, 10,
          style: PdfFontStyle.bold);
    }

    PdfLayoutResult yearlyGridResult = yearlyGrid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 0),
    )!;

    // Add total yearly payments
    yOffset = yearlyGridResult.bounds.bottom + 20;
    page.graphics.drawString(
        'Total Yearly Payments: ${yearlyTotalPayments.toStringAsFixed(1)}',
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center));

    for (final month in YearlyTab.orderedMonths) {
      final monthYear = '$month ${selectedYear.year}';
      final data = yearlyData[monthYear];
      if (data != null) {
        page = document.pages.add();
        yOffset = 20;

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
        monthlyGrid.columns.add(count: 7); // Updated to 7 columns
        monthlyGrid.headers.add(1);

        final PdfGridRow monthlyHeader = monthlyGrid.headers[0];
        monthlyHeader.cells[0].value = 'Date';
        monthlyHeader.cells[1].value = 'Category';
        monthlyHeader.cells[2].value = 'Sub-Category'; // Added Sub-Category
        monthlyHeader.cells[3].value = 'Description';
        monthlyHeader.cells[4].value = 'Account';
        monthlyHeader.cells[5].value = 'Payment';
        monthlyHeader.cells[6].value = 'Attendance';

        final monthIndex = YearlyTab.monthIndexMapping[month]!;
        final monthStart = DateTime(selectedYear.year, monthIndex, 1);
        final monthEnd = DateTime(selectedYear.year, monthIndex + 1, 0);

        final List<TransactionModel> transactions = yearlyTransactionBox.values
            .where((transaction) =>
                transaction.date
                    .isAfter(monthStart.subtract(const Duration(days: 1))) &&
                transaction.date
                    .isBefore(monthEnd.add(const Duration(days: 1))) &&
                transaction.transactionType == TransactionType.payment)
            .toList();

        transactions.sort((a, b) => a.date.compareTo(b.date));

        double totalPayments = 0;
        double totalAttendance = 0;

        for (final transaction in transactions) {
          final PdfGridRow row = monthlyGrid.rows.add();
          row.cells[0].value =
              DateFormat('dd/MM/yyyy').format(transaction.date);
          row.cells[1].value = transaction.categoryName ?? '';
          row.cells[2].value = transaction.subCategory ??
              transaction.generalSubCategory ??
              ''; // Added Sub-Category
          row.cells[3].value = transaction.description;
          row.cells[4].value = transaction.fromAccount;
          row.cells[5].value = transaction.amount.toStringAsFixed(1);
          row.cells[6].value = '-';

          totalPayments += transaction.amount;
        }

        // Add attendance records for the month
        final List<AttendanceModel> attendanceRecords = attendanceBox.values
            .where((attendance) =>
                attendance.date
                    .isAfter(monthStart.subtract(const Duration(days: 1))) &&
                attendance.date.isBefore(monthEnd.add(const Duration(days: 1))))
            .toList();

        for (final attendance in attendanceRecords) {
          final PdfGridRow row = monthlyGrid.rows.add();
          row.cells[0].value = DateFormat('dd/MM/yyyy').format(attendance.date);
          row.cells[1].value = attendance.subName;
          row.cells[2].value = ''; // Empty Sub-Category for attendance
          row.cells[3].value = attendance.description;
          row.cells[4].value = attendance.account;
          row.cells[5].value = '-';
          row.cells[6].value = attendance.payment.toStringAsFixed(1);

          totalAttendance += attendance.payment;
        }

        // Add summary row
        final PdfGridRow summaryRow = monthlyGrid.rows.add();
        summaryRow.cells[0].value = 'Monthly Total';
        summaryRow.cells[1].value = '';
        summaryRow.cells[2].value = '';
        summaryRow.cells[3].value = '';
        summaryRow.cells[4].value = '';
        summaryRow.cells[5].value = totalPayments.toStringAsFixed(1);
        summaryRow.cells[6].value = totalAttendance.toStringAsFixed(1);

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
        name: 'yearly_payment_report_${selectedYear.year}.pdf',
        bytes: Uint8List.fromList(bytes),
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      filePath = 'downloaded/yearly_payment_report_${selectedYear.year}.pdf';
    } else {
      // For mobile/desktop, use path_provider
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;

      filePath = '$appDocPath/yearly_payment_report_${selectedYear.year}.pdf';

      final File file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
    }

    return filePath;
  }
}
