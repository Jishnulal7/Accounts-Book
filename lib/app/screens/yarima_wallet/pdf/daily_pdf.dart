import 'dart:io';
import 'package:account_book/app/screens/yarima_wallet/pdf/components/save_pdf.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DailyPdf extends StatefulWidget {
  const DailyPdf({
    super.key,
    required this.pdfPath,
    required this.subIndex,
    required this.tabIndex,
    required this.selectMonth,
  });
  final String pdfPath;
  final DateTime selectMonth;
  final int subIndex;
  final int tabIndex;
  @override
  State<DailyPdf> createState() => _DailyPdfState();
}

class _DailyPdfState extends State<DailyPdf> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SfPdfViewer.file(File(widget.pdfPath)),
      floatingActionButton: _buildFloatingActionButtons(context),
      appBar: AppBar(
        title: const Text('Daily Pdf'),
      ),
    );
  }

  Row _buildFloatingActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: null,
          onPressed: () async {
            try {
              await SavePDF().savePdf(
                context,
                widget.pdfPath,
                widget.selectMonth,
                widget.tabIndex,
                widget.subIndex,
              );
            } catch (e) {
              debugPrint("Error saving PDF: $e");
            }
          },
          child: const Icon(Icons.download),
        ),
        const SizedBox(width: 10),
        FloatingActionButton(
          heroTag: null,
          onPressed: () async {
            try {
              await SavePDF().sharePDF(widget.pdfPath);
            } catch (e) {
              debugPrint("Error sharing PDF: $e");
            }
          },
          child: const Icon(Icons.share),
        ),
      ],
    );
  }
}
