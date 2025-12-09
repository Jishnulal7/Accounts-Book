import 'package:account_book/app/screens/party/exports.dart';
import 'package:intl/intl.dart';

class PartyStatementPage extends StatelessWidget {
  final String partyName;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  PartyStatementPage({super.key, required this.partyName});

  Future<Map<String, dynamic>> getBusinessData() async {
    final prefs = await SharedPreferences.getInstance();
    final businessDataString = prefs.getString('businessData');
    if (businessDataString != null) {
      return json.decode(businessDataString);
    }
    return {};
  }

  Future<String> generatePDF(BuildContext context) async {
    try {
      debugPrint('Starting PDF generation...');

      // Get business data
      final businessData = await getBusinessData();
      debugPrint('Business data loaded');

      // Load the Arial font data
      final ByteData fontData = await rootBundle.load('assets/fonts/arial.ttf');
      final List<int> fontBytes = fontData.buffer.asUint8List();

      // Get transactions from provider
      final provider = Provider.of<PartyProvider>(context, listen: false);
      final transactions = provider.transactions;

      debugPrint('Retrieved ${transactions.length} transactions');

      // Create a new PDF document
      final PdfDocument document = PdfDocument();

      // Create the custom font
      final PdfFont arialFont = PdfTrueTypeFont(fontBytes, 12);
      final PdfFont arialFontTitle = PdfTrueTypeFont(fontBytes, 24);
      final PdfFont arialFontHeader = PdfTrueTypeFont(fontBytes, 16);
      final PdfFont arialFontSmall = PdfTrueTypeFont(fontBytes, 10);
      final PdfFont arialFontTiny = PdfTrueTypeFont(fontBytes, 8);

      debugPrint('Fonts loaded');

      // Add a new page with margins
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();
      final double margin = 40;

      double currentY = margin;

      // Add logo if exists
      // if (businessData['logoPath'] != null) {
      //   try {
      //     final File logoFile = File(businessData['logoPath']);
      //     if (await logoFile.exists()) {
      //       final PdfBitmap logo = PdfBitmap(await logoFile.readAsBytes());
      //       // Draw logo with max height of 50
      //       final double aspectRatio = logo.width / logo.height;
      //       final double logoHeight = 50.0;
      //       final double logoWidth = logoHeight * aspectRatio;
      //       page.graphics.drawImage(
      //           logo, Rect.fromLTWH(margin, currentY, logoWidth, logoHeight));
      //       currentY += logoHeight + 10;
      //     }
      //   } catch (e) {
      //     debugPrint('Error loading logo: $e');
      //   }
      // }

      // Add company header
      final PdfTextElement companyName = PdfTextElement(
          text: businessData['businessName'] ?? 'Your Company Name',
          font: arialFontHeader);
      companyName.draw(
          page: page,
          bounds:
              Rect.fromLTWH(margin, currentY, pageSize.width - 2 * margin, 30));
      currentY += 30;

      // Add company details
      final StringBuffer companyDetails = StringBuffer();
      if (businessData['address'] != null) {
        companyDetails.writeln('Address: ${businessData['address']}');
      }
      if (businessData['mobile'] != null) {
        companyDetails.writeln('Phone: ${businessData['mobile']}');
      }
      if (businessData['email'] != null) {
        companyDetails.writeln('Email: ${businessData['email']}');
      }
      if (businessData['gstin'] != null) {
        companyDetails.writeln('GSTIN: ${businessData['gstin']}');
      }
      if (businessData['pan'] != null) {
        companyDetails.writeln('PAN: ${businessData['pan']}');
      }

      final PdfTextElement companyDetailsElement =
          PdfTextElement(text: companyDetails.toString(), font: arialFontSmall);
      companyDetailsElement.draw(
          page: page,
          bounds:
              Rect.fromLTWH(margin, currentY, pageSize.width - 2 * margin, 70));
      currentY += 80;

      // Add statement title
      final PdfTextElement title =
          PdfTextElement(text: 'Statement of Account', font: arialFontTitle);
      title.draw(
          page: page,
          bounds:
              Rect.fromLTWH(margin, currentY, pageSize.width - 2 * margin, 40));
      currentY += 40;

      // Add party details
      final PdfTextElement partyDetails = PdfTextElement(
          text:
              'Party Name: $partyName\nStatement Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
          font: arialFont);
      partyDetails.draw(
          page: page,
          bounds:
              Rect.fromLTWH(margin, currentY, pageSize.width - 2 * margin, 40));
      currentY += 50;

      // Create a PDF grid
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 5);
      grid.headers.add(1);

      // Style the grid
      final PdfGridRow header = grid.headers[0];
      header.style.backgroundBrush = PdfSolidBrush(PdfColor(68, 114, 196));
      header.style.textBrush = PdfBrushes.white;
      header.style.font = arialFont;

      header.cells[0].value = 'Date';
      header.cells[1].value = 'Type';
      header.cells[2].value = 'Invoice No';
      header.cells[3].value = 'Amount';
      header.cells[4].value = 'Balance';

      grid.columns[0].width = 80;
      grid.columns[1].width = 70;
      grid.columns[2].width = 100;

      double runningBalance = 0;

      // Add rows
      for (var i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final PdfGridRow row = grid.rows.add();
        final bool isPurchase = transaction is PurchaseModel;

        runningBalance +=
            isPurchase ? transaction.balanceAmount : -transaction.balanceAmount;

        row.cells[0].value = DateFormat('dd/MM/yyyy').format(transaction.date);
        row.cells[1].value = isPurchase ? 'Purchase' : 'Sale';
        row.cells[2].value = transaction.invoiceNumber;
        row.cells[3].value =
            NumberFormat.currency(symbol: '₹').format(transaction.totalAmount);
        row.cells[4].value =
            NumberFormat.currency(symbol: '₹').format(runningBalance);

        if (i % 2 == 0) {
          row.style.backgroundBrush = PdfSolidBrush(PdfColor(242, 242, 242));
        }

        row.style.font = arialFontSmall;
      }

      grid.style.cellPadding =
          PdfPaddings(left: 5, right: 5, top: 5, bottom: 5);

      // Draw grid
      grid.draw(
          page: page,
          bounds: Rect.fromLTWH(margin, currentY, pageSize.width - 2 * margin,
              pageSize.height - currentY - 60));

      // Add footer
      final PdfTextElement footer = PdfTextElement(
          text:
              'This is a computer generated statement and does not require signature.',
          font: arialFontTiny);
      footer.draw(
          page: page,
          bounds: Rect.fromLTWH(
              margin, pageSize.height - 50, pageSize.width - 2 * margin, 20));

      // Save document
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String path = '${appDir.path}/statement.pdf';
      debugPrint('Saving PDF to: $path');

      final List<int> bytes = await document.save();
      await File(path).writeAsBytes(bytes);
      document.dispose();

      debugPrint('PDF generated and saved successfully');
      return path;
    } catch (e, stackTrace) {
      debugPrint('Error generating PDF: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Party Statement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              try {
                final path = await generatePDF(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PDF saved to: $path'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save PDF: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: generatePDF(context),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error generating PDF: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            debugPrint('PDF path received: ${snapshot.data}');
            return SfPdfViewer.file(
              File(snapshot.data!),
              key: _pdfViewerKey,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                debugPrint('PDF loaded successfully');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF Statement loaded successfully'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                debugPrint('PDF load failed: ${details.error}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to load PDF: ${details.error}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          }

          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating PDF...'),
              ],
            ),
          );
        },
      ),
    );
  }
}
