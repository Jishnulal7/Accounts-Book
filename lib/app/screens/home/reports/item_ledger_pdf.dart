import 'package:intl/intl.dart';
import 'package:account_book/app/screens/home/exports.dart';

class ItemLedgerPdf extends StatelessWidget {
  final String filePath;

  const ItemLedgerPdf({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Statement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePdf(context),
          ),
        ],
      ),
      body: SfPdfViewer.file(
        File(filePath),
        initialScrollOffset: Offset.zero,
        initialZoomLevel: 1.0,
      ),
    );
  }

  void _sharePdf(BuildContext context) {
    // Implement your share functionality here
  }
}

class ItemPdfStatementService {
  static Future<File> generateItemStatement({
    required ItemModel item,
    required List<Map<String, dynamic>> transactions,
    required double openingBalance,
    required double closingBalance,
  }) async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Add a page
    final PdfPage page = document.pages.add();
    final ByteData fontData = await rootBundle.load('assets/fonts/arial.ttf');
    final List<int> fontBytes = fontData.buffer.asUint8List();
    // Create fonts
    final PdfFont headerFont = PdfTrueTypeFont(fontBytes, 18);
    final PdfFont contentFont = PdfTrueTypeFont(fontBytes, 12);

    // Draw header information
    _drawHeader(
        page, headerFont, contentFont, item, openingBalance, closingBalance);

    // Draw transaction table
    _drawTransactionTable(page, contentFont, transactions);

    // Save the document
    final List<int> bytes = await document.save();

    // Dispose the document
    document.dispose();

    // Save to temporary file
    final Directory tempDir = await getTemporaryDirectory();
    final File file = File('${tempDir.path}/item_statement.pdf');
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  static void _drawHeader(
    PdfPage page,
    PdfFont headerFont,
    PdfFont contentFont,
    ItemModel item,
    double openingBalance,
    double closingBalance,
  ) {
    final PdfGraphics graphics = page.graphics;

    // Draw title
    final PdfTextElement title = PdfTextElement(
      text: 'Item Statement',
      font: headerFont,
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
    );
    title.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 20, page.size.width, 50),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.onePage),
    );

    // Draw item details
    final String itemDetails = '''
Item Name: ${item.itemName ?? 'N/A'}
Unit: ${item.unit ?? 'N/A'}
Opening Stock: ${NumberFormat('#,##0.00').format(openingBalance)}
Closing Stock: ${NumberFormat('#,##0.00').format(closingBalance)}
''';

    graphics.drawString(
      itemDetails,
      contentFont,
      bounds: Rect.fromLTWH(50, 80, page.size.width - 100, 100),
    );
  }

  static void _drawTransactionTable(
    PdfPage page,
    PdfFont contentFont,
    List<Map<String, dynamic>> transactions,
  ) {
    // Create a PDF table
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 7);
    grid.headers.add(1);

    // Add header row
    final PdfGridRow headerRow = grid.headers[0];
    headerRow.cells[0].value = 'Date';
    headerRow.cells[1].value = 'Type';
    headerRow.cells[2].value = 'Party';
    headerRow.cells[3].value = 'Qty';
    headerRow.cells[4].value = 'Rate';
    headerRow.cells[5].value = 'Amount';
    headerRow.cells[6].value = 'Stock';

    // Add transaction rows
    for (final transaction in transactions) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value =
          DateFormat('dd/MM/yyyy').format(transaction['date'] as DateTime);
      row.cells[1].value = transaction['type'] as String;
      row.cells[2].value = transaction['partyName'] as String;
      row.cells[3].value =
          NumberFormat('#,##0.00').format(transaction['quantity'] as num);
      row.cells[4].value =
          NumberFormat('#,##0.00').format(transaction['rate'] as num);
      row.cells[5].value =
          NumberFormat('#,##0.00').format(transaction['amount'] as num);
      row.cells[6].value =
          NumberFormat('#,##0.00').format(transaction['balance'] as num);
    }

    // Set grid style
    grid.style = PdfGridStyle(
      font: contentFont,
      cellPadding: PdfPaddings(left: 5, right: 5, top: 5, bottom: 5),
    );

    // Draw the grid
    grid.draw(
      page: page,
      bounds:
          Rect.fromLTWH(50, 150, page.size.width - 100, page.size.height - 200),
    );
  }
}
