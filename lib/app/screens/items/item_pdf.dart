import 'package:account_book/app/screens/items/exports.dart';
import 'package:intl/intl.dart';
import 'dart:math' show max;

class ItemStatementPDF extends StatefulWidget {
  final String itemId;
  final ItemModel item;
  final List<Map<String, dynamic>> transactions;

  const ItemStatementPDF({
    required this.itemId,
    required this.item,
    required this.transactions,
    super.key,
  });

  @override
  State<ItemStatementPDF> createState() => _ItemStatementPDFState();
}

class _ItemStatementPDFState extends State<ItemStatementPDF> {
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _generatePDF();
  }

  Future<void> _generatePDF() async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    // Header
    _drawHeader(page);

    // Item Details
    _drawItemDetails(page);

    // Transactions Table
    _drawTransactionsTable(page);

    // Footer
    _drawFooter(page);

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/item_statement.pdf');
    await file.writeAsBytes(await document.save());
    document.dispose();

    setState(() {
      _pdfPath = file.path;
    });
  }

  void _drawHeader(PdfPage page) {
    final PdfGraphics graphics = page.graphics;
    final PdfFont headerFont = PdfTrueTypeFont(
        File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(), 20);
    final PdfFont subHeaderFont = PdfTrueTypeFont(
        File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync(), 12);

    // Title
    graphics.drawString('Item Statement', headerFont,
        bounds: const Rect.fromLTWH(70, 20, 400, 30),
        format: PdfStringFormat(alignment: PdfTextAlignment.center));

    // Subtitle
    graphics.drawString(
        'Generated on: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
        subHeaderFont,
        bounds: const Rect.fromLTWH(70, 50, 400, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center));
  }

  void _drawItemDetails(PdfPage page) {
    final PdfGraphics graphics = page.graphics;
    final PdfFont sectionFont = PdfTrueTypeFont(
        File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(), 14);
    final PdfFont contentFont = PdfTrueTypeFont(
        File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync(), 12);

    // Draw Border
    graphics.drawRectangle(
      bounds: const Rect.fromLTWH(50, 90, 400, 160),
      pen: PdfPen(PdfColor(0, 0, 0)),
    );

    // Section Title
    graphics.drawString('Item Details', sectionFont,
        bounds: const Rect.fromLTWH(55, 100, 200, 20));

    // Details Grid
    final List<List<String>> details = [
      ['Item Name:', widget.item.itemName ?? '--'],
      ['Type:', widget.item.itemType ?? '--'],
      [
        'Current Stock:',
        '${widget.item.stockQuantity} ${widget.item.unit ?? ''}'
      ],
      [
        'Unit Price:',
        'Rs. ${widget.item.amount?.toStringAsFixed(2) ?? '0.00'}'
      ],
      [
        'Stock Value:',
        'Rs. ${(widget.item.stockQuantity ?? 0) * (widget.item.amount ?? 0)}'
      ],
      [
        'Low Stock Alert:',
        '${widget.item.lowStockQuantity ?? 0} ${widget.item.unit ?? ''}'
      ],
    ];

    double yOffset = 130;
    for (var detail in details) {
      graphics.drawString(detail[0], contentFont,
          bounds: Rect.fromLTWH(55, yOffset, 150, 20));
      graphics.drawString(detail[1], contentFont,
          bounds: Rect.fromLTWH(200, yOffset, 200, 20));
      yOffset += 25;
    }
  }

  void _drawTransactionsTable(PdfPage page) {
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 7);
    grid.headers.add(1);

    final PdfGridRow header = grid.headers[0];
    header.style.backgroundBrush = PdfSolidBrush(PdfColor(68, 114, 196));
    header.style.textBrush = PdfBrushes.white;
    header.style.font =
        PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);

    // Define headers
    final headers = [
      'Date',
      'Type',
      'Party',
      'Quantity',
      'Rate',
      'Amount',
      'Invoice'
    ];

    // Set header values
    for (int i = 0; i < headers.length; i++) {
      header.cells[i].value = headers[i];
    }

    // Add rows
    for (var transaction in widget.transactions) {
      final PdfGridRow row = grid.rows.add();
      final (typeText, typeColor) =
          TransactionType().getTransactionTypeStyle(transaction['type']);

      // Add cell values
      row.cells[0].value = DateFormat('dd/MM/yyyy').format(transaction['date']);
      row.cells[1].value = typeText;
      row.cells[1].style.textBrush = PdfSolidBrush(typeColor);
      row.cells[2].value = transaction['partyName'];
      row.cells[3].value = transaction['quantity'].toString();
      row.cells[4].value = '${transaction['rate'].toStringAsFixed(2)}';
      row.cells[5].value = '${transaction['amount'].toStringAsFixed(2)}';
      row.cells[6].value = transaction['invoiceNumber'];

      if (grid.rows.count % 2 == 0) {
        row.style.backgroundBrush = PdfSolidBrush(PdfColor(242, 242, 242));
      }
    }

    // Set grid style
    grid.style = PdfGridStyle(
      cellPadding: PdfPaddings(left: 5, right: 5, top: 5, bottom: 5),
      font: PdfStandardFont(PdfFontFamily.helvetica, 10),
    );

    // Calculate available width
    final double pageWidth = page.getClientSize().width;
    final double totalTableWidth = pageWidth - 100; // Accounting for margins

    // Calculate column widths based on content
    List<double> calculateColumnWidths() {
      List<double> maxWidths = List.filled(headers.length, 0);
      final PdfStringFormat format = PdfStringFormat();
      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 10);

      // Check header widths
      for (int i = 0; i < headers.length; i++) {
        double headerWidth =
            font.measureString(headers[i], format: format).width + 10;
        maxWidths[i] = headerWidth;
      }

      // Check data widths
      for (int i = 0; i < grid.rows.count; i++) {
        for (int j = 0; j < headers.length; j++) {
          String cellValue = grid.rows[i].cells[j].value.toString();
          double cellWidth =
              font.measureString(cellValue, format: format).width + 10;
          maxWidths[j] = max(maxWidths[j], cellWidth);
        }
      }

      // Adjust widths to fit page
      double totalWidth = maxWidths.reduce((a, b) => a + b);
      double scaleFactor = totalTableWidth / totalWidth;

      return maxWidths.map((width) => width * scaleFactor).toList();
    }

    // Apply calculated widths
    final List<double> columnWidths = calculateColumnWidths();
    for (int i = 0; i < grid.columns.count; i++) {
      grid.columns[i].width = columnWidths[i];
    }

    // Draw the grid
    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(50, 300, totalTableWidth, 0),
    );
  }

  void _drawFooter(PdfPage page) {
    final PdfGraphics graphics = page.graphics;
    final PdfFont footerFont = PdfTrueTypeFont(
        File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync(), 10);

    // Add Page Number
    graphics.drawString(
      'Page 1 of 1',
      footerFont,
      bounds: Rect.fromLTWH(
          0, page.getClientSize().height - 50, page.getClientSize().width, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );

    // Footer Text
    graphics.drawString(
      'This is a computer-generated statement. Contact us at yarimaind@gmail.com.',
      footerFont,
      bounds: Rect.fromLTWH(
          0, page.getClientSize().height - 30, page.getClientSize().width, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Statement'),
      ),
      body: _pdfPath == null
          ? const Center(child: CircularProgressIndicator())
          : SfPdfViewer.file(File(_pdfPath!)),
    );
  }
}
