import 'dart:typed_data';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/screens/yarima_wallet/pdf/components/save_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AttendancePDF extends StatefulWidget {
  const AttendancePDF({
    super.key,
    required this.categoryName,
    required this.subcategoryName,
    required this.attendanceRecords,
    required this.startDate,
    required this.endDate,
  });

  final String categoryName;
  final String subcategoryName;
  final List<AttendanceModel> attendanceRecords;
  final DateTime startDate;
  final DateTime endDate;

  @override
  State<AttendancePDF> createState() => _AttendancePDFState();
}

class _AttendancePDFState extends State<AttendancePDF> {
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
                  context, pdfBytes, widget.categoryName, 'Attendance');
            },
            child: const Icon(Icons.download),
          ),
          const SizedBox(width: 10),
          SpeedDial(
            heroTag: 'share',
            onPress: () async {
              final pdfBytes = await _generatePdfBytes();
              await SavePDF().sharePdf(pdfBytes, widget.categoryName);
            },
            child: const Icon(Icons.share),
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(
            '${widget.categoryName} - ${widget.subcategoryName} Attendance'),
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
    final page = document.pages.add();

    _addStylishHeader(page);
    _addAttendanceTable(page);

    return document;
  }

  void _addStylishHeader(PdfPage page) {
    final headerText = PdfTextElement(
      text: 'Attendance for ${widget.categoryName} - ${widget.subcategoryName}',
      font: PdfStandardFont(PdfFontFamily.helvetica, 24,
          style: PdfFontStyle.bold),
    );
    headerText.draw(page: page, bounds: const Rect.fromLTWH(0, 0, 0, 0));

    final dateRangeText = PdfTextElement(
      text:
          'From ${DateFormat('dd MMM yyyy').format(widget.startDate)} to ${DateFormat('dd MMM yyyy').format(widget.endDate)}',
      font: PdfStandardFont(PdfFontFamily.helvetica, 14),
    );
    dateRangeText.draw(page: page, bounds: const Rect.fromLTWH(0, 30, 0, 0));

    final graphics = page.graphics;
    graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0), width: 1),
      const Offset(0, 55),
      Offset(page.getClientSize().width, 55),
    );
  }

  void _addAttendanceTable(PdfPage page) {
    final header = [
      'Date',
      'Attendance',
      'Account',
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

    double runningBalance = widget.attendanceRecords.isNotEmpty
        ? widget.attendanceRecords.first.openingBalance
        : 0;

    for (int i = 0; i < widget.attendanceRecords.length; i++) {
      final record = widget.attendanceRecords[i];

      final row = table.rows.add();

      row.cells[0].value = DateFormat('dd MMM yyyy').format(record.date);
      row.cells[1].value = record.isPresent ? 'Present' : 'Absent';
      row.cells[2].value = record.name;
      row.cells[3].value = record.wage.toStringAsFixed(1);
      row.cells[4].value = record.siteName;
      row.cells[5].value = record.extraCharges.toStringAsFixed(1);
      row.cells[6].value = record.description;
      row.cells[7].value = record.payment.toStringAsFixed(1);

      runningBalance += record.wage + record.extraCharges - record.payment;
      row.cells[8].value = runningBalance.toStringAsFixed(1);
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
    summaryRow.cells[2].value = '';
    summaryRow.cells[3].value = widget.attendanceRecords
        .fold<double>(0, (sum, record) => sum + record.wage)
        .toStringAsFixed(1);
    summaryRow.cells[4].value = '';
    summaryRow.cells[5].value = widget.attendanceRecords
        .fold<double>(0, (sum, record) => sum + record.extraCharges)
        .toStringAsFixed(1);
    summaryRow.cells[6].value = '';
    summaryRow.cells[7].value = widget.attendanceRecords
        .fold<double>(0, (sum, record) => sum + record.payment)
        .toStringAsFixed(1);
    summaryRow.cells[8].value = runningBalance.toStringAsFixed(1);

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
          0, 70, page.getClientSize().width, page.getClientSize().height - 70),
    );
  }
}
