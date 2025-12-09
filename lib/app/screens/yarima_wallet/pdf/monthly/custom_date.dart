import 'dart:io';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class CustomDateRangeMonthlyPDF {
  Map<String, List<TransactionModel>> groupAndSortTransactions(
      List<TransactionModel> transactions) {
    // First, group transactions by month-year
    Map<String, List<TransactionModel>> groupedTransactions = {};

    for (var transaction in transactions) {
      // Create a key in format "YYYY-MM" for grouping
      String monthKey =
          "${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}";

      if (!groupedTransactions.containsKey(monthKey)) {
        groupedTransactions[monthKey] = [];
      }
      groupedTransactions[monthKey]!.add(transaction);
    }

    // Sort transactions within each month
    groupedTransactions.forEach((month, transactions) {
      transactions.sort((a, b) {
        // Sort by date within the same month
        int dateComparison = a.date.day.compareTo(b.date.day);
        if (dateComparison != 0) return dateComparison;

        // If same date, sort by transaction type
        if (a.transactionType != b.transactionType) {
          Map<TransactionType, int> typePriority = {
            TransactionType.receipt: 0,
            TransactionType.payment: 1,
            TransactionType.transfer: 2,
          };
          return typePriority[a.transactionType]!
              .compareTo(typePriority[b.transactionType]!);
        }

        // If same transaction type, sort by amount
        return b.amount.compareTo(a.amount);
      });
    });

    return groupedTransactions;
  }

  Future<String> generateCustomDateRangePDF(
    Box<TransactionModel> transactionBox,
    DateTime startDate,
    DateTime endDate,
    Map<String, List<TransactionModel>> transactionsByMonth,
    double closingBalance,
  ) async {
    // Validate and normalize dates to start of day and end of day
    final DateTime normalizedStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime normalizedEndDate =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final PdfDocument document = PdfDocument();
    document.pageSettings.margins.all = 20;

    PdfPage page = document.pages.add();

    final PdfFont titleFont =
        PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final String reportTitle =
        'Financial Report: ${DateFormat('dd/MM/yyyy').format(normalizedStartDate)} - ${DateFormat('dd/MM/yyyy').format(normalizedEndDate)}';
    final Size titleSize = titleFont.measureString(reportTitle);

    page.graphics.drawString(reportTitle, titleFont,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds:
            Rect.fromLTWH(0, 0, page.getClientSize().width, titleSize.height),
        format: PdfStringFormat(alignment: PdfTextAlignment.center));

    double yOffset = titleSize.height + 20;

    final PdfGrid transactionsGrid = PdfGrid();
    transactionsGrid.columns.add(count: 9);
    transactionsGrid.headers.add(1);

    final PdfGridRow header = transactionsGrid.headers[0];
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
    header.style.font = PdfStandardFont(PdfFontFamily.helvetica, 10);

    // Filter transactions within date range
    List<TransactionModel> filteredTransactions =
        transactionBox.values.where((transaction) {
      final DateTime transactionDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      return (transactionDate.isAtSameMomentAs(normalizedStartDate) ||
          transactionDate.isAtSameMomentAs(normalizedEndDate) ||
          (transactionDate.isAfter(normalizedStartDate) &&
              transactionDate.isBefore(normalizedEndDate)));
    }).toList();

    // Group and sort transactions by month
    Map<String, List<TransactionModel>> groupedTransactions =
        groupAndSortTransactions(filteredTransactions);

    // Sort month keys to process transactions in chronological order
    List<String> sortedMonths = groupedTransactions.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    double runningBalance = closingBalance;
    double totalReceipt = 0;
    double totalPayment = 0;
    double totalTransfer = 0;

    // Process transactions month by month
    for (String monthKey in sortedMonths) {
      List<TransactionModel> monthTransactions = groupedTransactions[monthKey]!;

      // Add month header row
      DateTime monthDate = DateTime(int.parse(monthKey.split('-')[0]),
          int.parse(monthKey.split('-')[1]), 1);
      PdfGridRow monthRow = transactionsGrid.rows.add();
      monthRow.cells[0].value = DateFormat('MMMM yyyy').format(monthDate);
      for (int i = 1; i < monthRow.cells.count; i++) {
        monthRow.cells[i].value = '';
      }

      // Style the month header row
      PdfGridCellStyle monthRowStyle = PdfGridCellStyle();
      monthRowStyle.backgroundBrush = PdfSolidBrush(PdfColor(220, 220, 220));
      monthRowStyle.font = PdfStandardFont(PdfFontFamily.helvetica, 10,
          style: PdfFontStyle.bold);
      for (int i = 0; i < monthRow.cells.count; i++) {
        monthRow.cells[i].style = monthRowStyle;
      }

      // Process transactions for this month
      for (var transaction in monthTransactions) {
        double receipt = 0;
        double payment = 0;
        double transfer = 0;

        if (transaction.amount <= 0) {
          debugPrint(
              'Warning: Invalid amount ${transaction.amount} for transaction on ${transaction.date}');
          continue;
        }

        switch (transaction.transactionType) {
          case TransactionType.receipt:
            receipt = transaction.amount;
            totalReceipt += receipt;
            runningBalance += receipt;
            break;
          case TransactionType.payment:
            payment = transaction.amount;
            totalPayment += payment;
            runningBalance -= payment;
            break;
          case TransactionType.transfer:
            transfer = transaction.amount;
            totalTransfer += transfer;
            break;
          }

        String categoryName = transaction.categoryName ?? 'Uncategorized';
        String subCategory =
            transaction.subCategory ?? transaction.generalSubCategory ?? 'N/A';

        addRow(
          transactionsGrid,
          transaction.date,
          receipt,
          payment,
          transfer,
          transaction.fromAccount,
          categoryName,
          subCategory,
          transaction.description,
          runningBalance,
        );
      }
    }

    // Add totals row with validation
    PdfGridRow totalRow = transactionsGrid.rows.add();
    totalRow.cells[0].value = 'Totals';
    totalRow.cells[1].value = totalReceipt.toStringAsFixed(2);
    totalRow.cells[2].value = totalPayment.toStringAsFixed(2);
    totalRow.cells[3].value = totalTransfer.toStringAsFixed(2);
    totalRow.cells[8].value = runningBalance.toStringAsFixed(2);

    // Style the totals row
    PdfGridCellStyle totalRowStyle = PdfGridCellStyle();
    totalRowStyle.backgroundBrush = PdfSolidBrush(PdfColor(200, 200, 200));
    totalRowStyle.font =
        PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);
    for (int i = 0; i < totalRow.cells.count; i++) {
      totalRow.cells[i].style = totalRowStyle;
    }

    // Set columns width
    transactionsGrid.columns[0].width = 80; // Date
    transactionsGrid.columns[1].width = 70; // Receipt
    transactionsGrid.columns[2].width = 70; // Payment
    transactionsGrid.columns[3].width = 70; // Transfer
    transactionsGrid.columns[8].width = 80; // Balance

    transactionsGrid.style.cellPadding =
        PdfPaddings(left: 5, right: 5, top: 5, bottom: 5);

    transactionsGrid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 0),
    );

    List<int> bytes = await document.save();
    document.dispose();
    String filePath;
    if (kIsWeb) {
      // For web, use file_saver to download
      await FileSaver.instance.saveFile(
        name:
            'yearly_receipts_report_${DateFormat('yyyyMMdd').format(normalizedStartDate)}_${DateFormat('yyyyMMdd').format(normalizedEndDate)}.pdf',
        bytes: Uint8List.fromList(bytes),
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      filePath =
          'yearly_receipts_report_${DateFormat('yyyyMMdd').format(normalizedStartDate)}_${DateFormat('yyyyMMdd').format(normalizedEndDate)}.pdf';
    } else {
      // For mobile/desktop, use path_provider
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;

      filePath =
          '$appDocPath/yearly_receipts_report_${DateFormat('yyyyMMdd').format(normalizedStartDate)}_${DateFormat('yyyyMMdd').format(normalizedEndDate)}.pdf';

      final File file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
    }

    return filePath;
  }

  void addRow(
    PdfGrid grid,
    DateTime date,
    double receipt,
    double payment,
    double transfer,
    String account,
    String category,
    String subCategory,
    String description,
    double runningBalance,
  ) {
    PdfGridRow row = grid.rows.add();
    row.cells[0].value = DateFormat('dd/MM/yyyy').format(date);
    row.cells[1].value = receipt > 0 ? receipt.toStringAsFixed(2) : '';
    row.cells[2].value = payment > 0 ? payment.toStringAsFixed(2) : '';
    row.cells[3].value = transfer > 0 ? transfer.toStringAsFixed(2) : '';
    row.cells[4].value = account;
    row.cells[5].value = category;
    row.cells[6].value = subCategory;
    row.cells[7].value = description;
    row.cells[8].value = runningBalance.toStringAsFixed(2);
  }
}
