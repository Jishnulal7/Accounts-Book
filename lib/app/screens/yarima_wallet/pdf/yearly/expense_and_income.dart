import 'dart:io';
import 'dart:ui';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/tab/yearlytab.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class YearlyPaymentAndReceipt {
  Future<String> generateYearlyPaymentAndReceiptPDF(
    Box<TransactionModel> yearlyTransactionBox,
    DateTime selectedYear,
    Map<String, Map<String, dynamic>> yearlyData,
  ) async {
    final PdfDocument document = PdfDocument();
    document.pageSettings.margins.all = 20;

    // Add yearly summary page
    addYearlySummaryPage(document, selectedYear, yearlyData);

    // Add monthly details
    addMonthlyDetails(document, yearlyTransactionBox, selectedYear, yearlyData);

    List<int> bytes = await document.save();
    document.dispose();
    String filePath;

    if (kIsWeb) {
      // For web, use file_saver to download
      await FileSaver.instance.saveFile(
        name: 'yearly_Payment_and_Receipt_report_${selectedYear.year}.pdf',
        bytes: Uint8List.fromList(bytes),
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      filePath =
          'downloaded/yearly_Payment_and_Receipt_report_${selectedYear.year}.pdf';
    } else {
      // For mobile/desktop, use path_provider
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;

      filePath = '$appDocPath/yearly_Payment_and_Receipt_report_${selectedYear.year}.pdf';

      final File file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
    }

    return filePath;
  }

  void addYearlySummaryPage(
    PdfDocument document,
    DateTime selectedYear,
    Map<String, Map<String, dynamic>> yearlyData,
  ) {
    PdfPage page = document.pages.add();

    final PdfFont titleFont =
        PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final Size titleSize = titleFont.measureString(
        'Yearly Payment and Receipt Summary ${selectedYear.year}');
    page.graphics.drawString(
        'Yearly Payment and Receipt Summary ${selectedYear.year}', titleFont,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds:
            Rect.fromLTWH(0, 0, page.getClientSize().width, titleSize.height),
        format: PdfStringFormat(alignment: PdfTextAlignment.center));

    double yOffset = titleSize.height + 20;

    final PdfGrid yearlyGrid = PdfGrid();
    yearlyGrid.columns.add(count: 3);
    yearlyGrid.headers.add(1);

    final PdfGridRow yearlyHeader = yearlyGrid.headers[0];
    yearlyHeader.cells[0].value = 'Month';
    yearlyHeader.cells[1].value = 'Total Receipt';
    yearlyHeader.cells[2].value = 'Total Payment';

    double yearlyTotalReceipt = 0;
    double yearlyTotalPayment = 0;

    for (final month in YearlyTab.orderedMonths) {
      final monthYear = '$month ${selectedYear.year}';
      final data = yearlyData[monthYear];
      final PdfGridRow row = yearlyGrid.rows.add();
      row.cells[0].value = month;

      double monthlyReceipt =
          data != null ? double.parse(data['totalReceipts'].toString()) : 0;
      double monthlyPayment =
          data != null ? double.parse(data['totalPayments'].toString()) : 0;

      yearlyTotalReceipt += monthlyReceipt;
      yearlyTotalPayment += monthlyPayment;

      row.cells[1].value = monthlyReceipt.toStringAsFixed(1);
      row.cells[2].value = monthlyPayment.toStringAsFixed(1);
    }

    // Add yearly total row
    final PdfGridRow yearlyTotalRow = yearlyGrid.rows.add();
    yearlyTotalRow.cells[0].value = 'Yearly Total';
    yearlyTotalRow.cells[1].value = yearlyTotalReceipt.toStringAsFixed(1);
    yearlyTotalRow.cells[2].value = yearlyTotalPayment.toStringAsFixed(1);

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

    // Add net Receipt/Payment
    yOffset = yearlyGridResult.bounds.bottom + 20;
    double netAmount = yearlyTotalReceipt - yearlyTotalPayment;
    String netLabel = netAmount >= 0 ? 'Net Receipt' : 'Net Payment';
    page.graphics.drawString('$netLabel: ${netAmount.abs().toStringAsFixed(1)}',
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center));
  }

  void addMonthlyDetails(
    PdfDocument document,
    Box<TransactionModel> yearlyTransactionBox,
    DateTime selectedYear,
    Map<String, Map<String, dynamic>> yearlyData,
  ) {
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
        monthlyGrid.columns.add(count: 6); // Increased column count to 6
        monthlyGrid.headers.add(1);

        final PdfGridRow monthlyHeader = monthlyGrid.headers[0];
        monthlyHeader.cells[0].value = 'Date';
        monthlyHeader.cells[1].value = 'Description';
        monthlyHeader.cells[2].value = 'Category';
        monthlyHeader.cells[3].value = 'Sub-Category';
        monthlyHeader.cells[4].value = 'Account';
        monthlyHeader.cells[5].value = 'Amount';

        final monthIndex = YearlyTab.monthIndexMapping[month]!;
        final monthStart = DateTime(selectedYear.year, monthIndex, 1);
        final monthEnd = DateTime(selectedYear.year, monthIndex + 1, 0);

        final List<TransactionModel> transactions = yearlyTransactionBox.values
            .where((transaction) =>
                transaction.date
                    .isAfter(monthStart.subtract(const Duration(days: 1))) &&
                transaction.date
                    .isBefore(monthEnd.add(const Duration(days: 1))) &&
                (transaction.transactionType == TransactionType.payment ||
                    transaction.transactionType == TransactionType.receipt))
            .toList();

        transactions.sort((a, b) => a.date.compareTo(b.date));

        double totalPayment = 0;
        double totalReceipt = 0;

        for (final transaction in transactions) {
          final PdfGridRow row = monthlyGrid.rows.add();
          row.cells[0].value =
              DateFormat('dd/MM/yyyy').format(transaction.date);
          row.cells[1].value = transaction.description;
          row.cells[2].value = transaction.categoryName ?? '';
          row.cells[3].value =
              transaction.subCategory ?? transaction.generalSubCategory ?? '';
          row.cells[4].value = transaction.fromAccount;
          row.cells[5].value = transaction.amount.toStringAsFixed(1);

          if (transaction.transactionType == TransactionType.payment) {
            totalPayment += transaction.amount;
          } else if (transaction.transactionType == TransactionType.receipt) {
            totalReceipt += transaction.amount;
          }
        }

        // Add summary rows
        final PdfGridRow paymentSummaryRow = monthlyGrid.rows.add();
        paymentSummaryRow.cells[0].value = 'Total Payment';
        paymentSummaryRow.cells[5].value = totalPayment.toStringAsFixed(1);

        final PdfGridRow receiptSummaryRow = monthlyGrid.rows.add();
        receiptSummaryRow.cells[0].value = 'Total Receipt';
        receiptSummaryRow.cells[5].value = totalReceipt.toStringAsFixed(1);

        // Style the summary rows
        for (final row in [paymentSummaryRow, receiptSummaryRow]) {
          for (int i = 0; i < row.cells.count; i++) {
            row.cells[i].style.backgroundBrush =
                PdfSolidBrush(PdfColor(220, 220, 220));
            row.cells[i].style.font = PdfStandardFont(
                PdfFontFamily.helvetica, 10,
                style: PdfFontStyle.bold);
          }
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
  }
}
