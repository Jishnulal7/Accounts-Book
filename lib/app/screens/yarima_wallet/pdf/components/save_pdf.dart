import 'dart:io';
import 'package:account_book/app/data/helpers/enums/toast.dart';
import 'package:account_book/app/widgets/custom_toast.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SavePDF {
  Future<void> downloadPdf(
      BuildContext context, Uint8List pdfBytes, String name, String sub) async {
    try {
      String fileName = '$name-$sub.pdf';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: pdfBytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );

      ToastService.show(
        context,
        message: 'PDF saved successfully',
        type: ToastType.success,
      );
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      ToastService.show(
        context,
        message: 'Error saving PDF: $e',
        type: ToastType.error,
      );
    }
  }

  Future<void> sharePdf(Uint8List pdfBytes, String name) async {
    if (kIsWeb) {
      // On web, download the file
      await FileSaver.instance.saveFile(
        name: '$name-transactions.pdf',
        bytes: pdfBytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
    } else {
      // Mobile/desktop sharing method
      try {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$name-transactions.pdf');
        await file.writeAsBytes(pdfBytes);
        await Share.shareXFiles([XFile(file.path)], text: '$name Transactions');
      } catch (e) {
        debugPrint('Error sharing PDF: $e');
      }
    }
  }

  Future<void> savePdf(
    BuildContext context,
    String pdfPath,
    DateTime selectedMonth,
    int tabIndex,
    int subIndex,
  ) async {
    try {
      // Read PDF bytes
      final pdfBytes = await File(pdfPath).readAsBytes();

      // Generate filename based on tabIndex and subIndex
      String fileName = _generateFileName(selectedMonth, tabIndex, subIndex);

      // Save file using FileSaver
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: pdfBytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      ToastService.show(
        context,
        message: 'PDF saved successfully',
        type: ToastType.success,
      );
    } catch (error) {
      debugPrint("Error saving PDF: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving PDF: $error'),
        ),
      );
    }
  }

  Future<void> sharePDF(String pdfPath) async {
    try {
      final pdfBytes = await File(pdfPath).readAsBytes();

      if (kIsWeb) {
        // On web, download the file
        await FileSaver.instance.saveFile(
          name: 'shared-document.pdf',
          bytes: pdfBytes,
          ext: 'pdf',
          mimeType: MimeType.pdf,
        );
      } else {
        // Mobile/desktop sharing
        final xFile = XFile(pdfPath);
        await Share.shareXFiles([xFile], text: 'Sharing PDF');
      }
    } catch (error) {
      debugPrint("Error sharing PDF: $error");
    }
  }

  String _generateFileName(DateTime selectedMonth, int tabIndex, int subIndex) {
    String fileName = '';
    if (tabIndex == 0) {
      String year = DateFormat('yyyy').format(selectedMonth);
      String reportType = '';
      switch (subIndex) {
        case 1:
          reportType = 'Expense';
          break;
        case 2:
          reportType = 'Receipt';
          break;
        case 3:
          reportType = 'Transfers';
          break;
        default:
          reportType = 'Yearly';
          break;
      }
      fileName = '$reportType $year';
    } else if (tabIndex == 1) {
      String month = DateFormat('MMMM').format(selectedMonth);
      String year = DateFormat('y').format(selectedMonth);
      String reportType = '';
      switch (subIndex) {
        case 1:
          reportType = 'Payment';
          break;
        case 2:
          reportType = 'Receipt';
          break;
        case 3:
          reportType = 'Transfers';
          break;
        default:
          reportType = 'Monthly';
          break;
      }
      fileName = '$reportType $month $year';
    } else {
      fileName = 'Digital_wallet';
    }
    return fileName;
  }
}
