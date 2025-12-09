import 'dart:typed_data';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/components/attendance_model.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/components/save_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AllCategoryAttendancePDF extends StatefulWidget {
  const AllCategoryAttendancePDF({
    super.key,
    required this.categories,
    required this.startDate,
    required this.endDate,
  });

  final List<AttendanceCategory> categories;
  final DateTime startDate;
  final DateTime endDate;

  @override
  State<AllCategoryAttendancePDF> createState() =>
      _AllCategoryAttendancePDFState();
}

class _AllCategoryAttendancePDFState extends State<AllCategoryAttendancePDF> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SpeedDial(
            heroTag: 'download',
            onPress: () async {
              final pdfBytes = await _generatePdfBytes();
              await SavePDF().downloadPdf(
                  context, pdfBytes, 'All Categories', 'Attendance');
            },
            child: const Icon(Icons.download),
          ),
          const SizedBox(width: 10),
          SpeedDial(
            heroTag: 'share',
            onPress: () async {
              final pdfBytes = await _generatePdfBytes();
              await SavePDF().sharePdf(pdfBytes, 'All Categories Attendance');
            },
            child: const Icon(Icons.share),
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text('All Categories Attendance'),
      ),
      body: FutureBuilder<Uint8List>(
        future: _generatePdfBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error generating PDF'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No PDF data available'));
          }
          return SfPdfViewer.memory(snapshot.data!, key: UniqueKey());
        },
      ),
    );
  }

  Future<Uint8List> _generatePdfBytes() async {
    final document = await _generatePdf();
    return Uint8List.fromList(document.saveSync());
  }

  Future<PdfDocument> _generatePdf() async {
    final document = PdfDocument();

    for (var category in widget.categories) {
      for (var subcategory in category.subcategories) {
        final page = document.pages.add();
        _addStylishHeader(page, category.name, subcategory.name);
        _addAttendanceTable(page, category.name, subcategory);
      }
    }

    return document;
  }

  void _addStylishHeader(
      PdfPage page, String categoryName, String subcategoryName) {
    final headerText = PdfTextElement(
      text: 'Attendance for $categoryName - $subcategoryName',
      font: PdfStandardFont(PdfFontFamily.helvetica, 18,
          style: PdfFontStyle.bold),
    );
    headerText.draw(page: page, bounds: const Rect.fromLTWH(0, 0, 0, 0));

    final dateRangeText = PdfTextElement(
      text:
          'From ${DateFormat('dd MMM yyyy').format(widget.startDate)} to ${DateFormat('dd MMM yyyy').format(widget.endDate)}',
      font: PdfStandardFont(PdfFontFamily.helvetica, 12),
    );
    dateRangeText.draw(page: page, bounds: const Rect.fromLTWH(0, 25, 0, 0));

    final graphics = page.graphics;
    graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0), width: 1),
      const Offset(0, 45),
      Offset(page.getClientSize().width, 45),
    );
  }

  void _addAttendanceTable(
      PdfPage page, String categoryName, Subcategory subcategory) {
    final header = [
      'Date',
      'Attendance',
      'Wage',
      'Site Name',
      'Extra Charges',
      'Description',
      'Payment',
      'Balance'
    ];

    final table = PdfGrid();
    table.columns.add(count: header.length);
    table.headers.add(1);
    final headerRow = table.headers[0];
    for (int i = 0; i < header.length; i++) {
      headerRow.cells[i].value = header[i];
      headerRow.cells[i].style.backgroundBrush =
          PdfSolidBrush(PdfColor(66, 133, 244));
      headerRow.cells[i].style.textBrush = PdfBrushes.white;
      headerRow.cells[i].style.font =
          PdfStandardFont(PdfFontFamily.helvetica, 10);
    }

    // Fetch attendance records for this subcategory
    List<AttendanceModel> attendanceRecords =
        fetchAttendanceRecords(categoryName, subcategory.name);

    double runningBalance = subcategory.openingBalance;

    for (var record in attendanceRecords) {
      final row = table.rows.add();

      row.cells[0].value = DateFormat('dd MMM yyyy').format(record.date);
      row.cells[1].value = record.isPresent ? 'Present' : 'Absent';
      row.cells[2].value = record.wage.toStringAsFixed(1);
      row.cells[3].value = record.siteName;
      row.cells[4].value = record.extraCharges.toStringAsFixed(1);
      row.cells[5].value = record.description;
      row.cells[6].value = record.payment.toStringAsFixed(1);

      runningBalance += record.wage + record.extraCharges - record.payment;
      row.cells[7].value = runningBalance.toStringAsFixed(1);
    }

    // Apply alternating row colors
    for (int i = 0; i < table.rows.count; i++) {
      final row = table.rows[i];
      final brush = i % 2 == 0
          ? PdfSolidBrush(PdfColor(242, 242, 242))
          : PdfSolidBrush(PdfColor(255, 255, 255));
      for (int j = 0; j < row.cells.count; j++) {
        row.cells[j].style.backgroundBrush = brush;
      }
    }

    // Add summary row
    final summaryRow = table.rows.add();
    summaryRow.cells[0].value = 'Total';
    summaryRow.cells[1].value = '';
    summaryRow.cells[2].value = attendanceRecords
        .fold<double>(0, (sum, record) => sum + record.wage)
        .toStringAsFixed(1);
    summaryRow.cells[3].value = '';
    summaryRow.cells[4].value = attendanceRecords
        .fold<double>(0, (sum, record) => sum + record.extraCharges)
        .toStringAsFixed(1);
    summaryRow.cells[5].value = '';
    summaryRow.cells[6].value = attendanceRecords
        .fold<double>(0, (sum, record) => sum + record.payment)
        .toStringAsFixed(1);
    summaryRow.cells[7].value = runningBalance.toStringAsFixed(1);

    // Style summary row
    for (int i = 0; i < summaryRow.cells.count; i++) {
      summaryRow.cells[i].style.backgroundBrush =
          PdfSolidBrush(PdfColor(200, 200, 200));
      summaryRow.cells[i].style.font = PdfStandardFont(
          PdfFontFamily.helvetica, 10,
          style: PdfFontStyle.bold);
    }

    // Draw the table
    table.draw(
      page: page,
      bounds: Rect.fromLTWH(
          0, 60, page.getClientSize().width, page.getClientSize().height - 60),
    );
  }

  List<AttendanceModel> fetchAttendanceRecords(
      String categoryName, String subcategoryName) {
    final box = Hive.box<AttendanceModel>('attendanceBox');

    // Fetch all records
    List<AttendanceModel> allRecords =
        box.values.toList().cast<AttendanceModel>();

    // Filter records based on category and subcategory
    List<AttendanceModel> filteredRecords = allRecords.where((record) {
      return record.name == categoryName || record.subName == subcategoryName;
    }).toList();
    filteredRecords.sort((a, b) => a.date.compareTo(b.date));

    // Calculate running balance
    double runningBalance = 0;
    for (var record in filteredRecords) {
      runningBalance += record.wage + record.extraCharges - record.payment;
      record.balance = runningBalance;
    }

    return filteredRecords;
  }
}
