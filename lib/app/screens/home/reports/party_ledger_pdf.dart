import 'package:intl/intl.dart';
import 'package:account_book/app/screens/home/exports.dart';

class PdfStatementForParty{
  static Future<File> generatePartyStatement({
    required PartyModel party,
    required List<Transaction> transactions,
    required double openingBalance,
    required double currentBalance,
  }) async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Add a page
    final PdfPage page = document.pages.add();
    final ByteData fontData = await rootBundle.load('assets/fonts/arial.ttf');
    final List<int> fontBytes = fontData.buffer.asUint8List();

    // Create a PDF font
    final PdfFont headerFont = PdfTrueTypeFont(fontBytes, 18);
    final PdfFont contentFont = PdfTrueTypeFont(fontBytes, 12);

    // Draw header information
    _drawHeader(page, headerFont, contentFont, party, currentBalance);

    // Create and draw transaction table
    _drawTransactionTable(page, contentFont, transactions, openingBalance);

    // Save the document
    final List<int> bytes = await document.save();

    // Dispose the document
    document.dispose();

    // Save to temporary file
    final Directory tempDir = await getTemporaryDirectory();
    final File file = File('${tempDir.path}/party_statement.pdf');
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  static void _drawHeader(
    PdfPage page,
    PdfFont headerFont,
    PdfFont contentFont,
    PartyModel party,
    double currentBalance,
  ) {
    final PdfGraphics graphics = page.graphics;
    final PdfLayoutResult result = PdfTextElement(
      text: 'Party Statement',
      font: headerFont,
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(0, 0, page.size.width, 50),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
    )!;

    double yPos = result.bounds.bottom + 20;

    // Party Information
    final String partyInfo = '''
Name: ${party.name ?? 'N/A'}
Contact: ${party.contactNumber ?? 'N/A'}
Current Balance: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(currentBalance)}
''';

    graphics.drawString(
      partyInfo,
      contentFont,
      bounds: Rect.fromLTWH(50, yPos, page.size.width - 100, 100),
    );

    yPos += 80;
  }

  static void _drawTransactionTable(
    PdfPage page,
    PdfFont contentFont,
    List<Transaction> transactions,
    double openingBalance,
  ) {
    // Create a PDF table
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 5);
    grid.headers.add(1);

    // Add header row
    final PdfGridRow headerRow = grid.headers[0];
    headerRow.cells[0].value = 'Date';
    headerRow.cells[1].value = 'Description';
    headerRow.cells[2].value = 'Debit (₹)';
    headerRow.cells[3].value = 'Credit (₹)';
    headerRow.cells[4].value = 'Balance (₹)';

    // Add transaction rows
    double runningBalance = openingBalance;
    for (final transaction in transactions) {
      runningBalance += transaction.debit - transaction.credit;

      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = DateFormat('dd/MM/yyyy').format(transaction.date);
      row.cells[1].value = transaction.description;
      row.cells[2].value = transaction.debit > 0
          ? NumberFormat('#,##0.00').format(transaction.debit)
          : '-';
      row.cells[3].value = transaction.credit > 0
          ? NumberFormat('#,##0.00').format(transaction.credit)
          : '-';
      row.cells[4].value = NumberFormat('#,##0.00').format(runningBalance);
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
