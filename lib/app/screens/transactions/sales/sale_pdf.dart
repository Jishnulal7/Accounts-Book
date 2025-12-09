import 'package:account_book/app/screens/transactions/export.dart';
import 'package:account_book/app/screens/transactions/purchase/purchase_pdf.dart';
import 'package:intl/intl.dart';

class SalePdf extends StatelessWidget {
  final SaleModel sale;
  final PartyModel party;

  SalePdf({
    super.key,
    required this.sale,
    required this.party,
  });

  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  String getStateCode(String stateName) {
    final Map<String, String> statesMap = {
      'Jammu and Kashmir': '01',
      'Himachal Pradesh': '02',
      'Punjab': '03',
      'Chandigarh': '04',
      'Uttarakhand': '05',
      'Haryana': '06',
      'Delhi': '07',
      'Rajasthan': '08',
      'Uttar Pradesh': '09',
      'Bihar': '10',
      'Sikkim': '11',
      'Arunachal Pradesh': '12',
      'Nagaland': '13',
      'Manipur': '14',
      'Mizoram': '15',
      'Tripura': '16',
      'Meghalaya': '17',
      'Assam': '18',
      'West Bengal': '19',
      'Jharkhand': '20',
      'Odisha': '21',
      'Chhattisgarh': '22',
      'Madhya Pradesh': '23',
      'Gujarat': '24',
      'Maharashtra': '27',
      'Karnataka': '29',
      'Goa': '30',
      'Lakshadweep': '31',
      'Kerala': '32',
      'Tamil Nadu': '33',
      'Puducherry': '34',
      'Telangana': '36',
      'Andhra Pradesh': '37',
      'Ladakh': '38'
    };
    return statesMap[stateName] ?? 'No Data';
  }

  // Load business profile data from SharedPreferences
  Future<Map<String, String>> loadBusinessProfile() async {
    final prefs = await SharedPreferences.getInstance();

    // First try to load from businessData JSON
    String? businessDataJson = prefs.getString('businessData');

    if (businessDataJson != null) {
      try {
        // Parse the JSON string
        Map<String, dynamic> businessData = json.decode(businessDataJson);

        return {
          'businessName': businessData['businessName'] ?? '',
          'gstin': businessData['gstin'] ?? '',
          'pan': businessData['pan'] ?? '',
          'email': businessData['email'] ?? '',
          'mobile': businessData['mobile'] ?? '',
          'address':
              '${businessData['street'] ?? ''}, ${businessData['city'] ?? ''}',
          'state': businessData['state'] ?? 'Kerala',
          'stateCode': businessData['stateCode'] ??
              getStateCode(businessData['state'] ?? 'Kerala'),
          'pincode': businessData['postalCode'] ?? '',
          'country': businessData['country'] ?? 'India',
          'logoPath': businessData['logoPath'] ?? '',
        };
      } catch (e) {
        debugPrint('Error parsing businessData JSON: $e');
        // Fall back to legacy method if JSON parsing fails
      }
    }

    // Fall back to individual preferences if no JSON data exists
    final state = prefs.getString('state') ?? 'Kerala';
    return {
      'businessName': prefs.getString('businessName') ?? '',
      'gstin': prefs.getString('gstin') ?? '',
      'pan': prefs.getString('pan') ?? '',
      'email': prefs.getString('email') ?? '',
      'mobile': prefs.getString('mobile') ?? '',
      'address': prefs.getString('address') ?? '',
      'state': state,
      'stateCode': getStateCode(state),
      'pincode': prefs.getString('pincode') ?? '',
    };
  }

  Future<Map<String, String>> loadBankDetails() async {
    final prefs = await SharedPreferences.getInstance();

    // First try to load from businessData JSON
    String? businessDataJson = prefs.getString('businessData');

    if (businessDataJson != null) {
      try {
        // Parse the JSON string
        Map<String, dynamic> businessData = json.decode(businessDataJson);

        // Check if bank details exist in the JSON
        if (businessData.containsKey('bankName') ||
            businessData.containsKey('accountHolder') ||
            businessData.containsKey('accountNumber') ||
            businessData.containsKey('ifscCode') ||
            businessData.containsKey('bankBranch')) {
          return {
            'bankName': businessData['bankName'] ?? '',
            'accountHolder': businessData['accountHolder'] ?? '',
            'accountNumber': businessData['accountNumber'] ?? '',
            'ifscCode': businessData['ifscCode'] ?? '',
            'bankBranch': businessData['bankBranch'] ?? '',
          };
        }
      } catch (e) {
        debugPrint('Error parsing businessData JSON for bank details: $e');
      }
    }

    // Fall back to individual preferences
    return {
      'bankName': prefs.getString('bankName') ?? '',
      'accountHolder': prefs.getString('accountHolder') ?? '',
      'accountNumber': prefs.getString('accountNumber') ?? '',
      'ifscCode': prefs.getString('ifscCode') ?? '',
      'bankBranch': prefs.getString('bankBranch') ?? '',
    };
  }

  Future<String> generateInvoice(SaleModel sale) async {
    try {
      final businessProfile = await loadBusinessProfile();
      final bankDetails = await loadBankDetails();
      final PdfDocument document = PdfDocument();
      document.pageSettings.size = PdfPageSize.a4;
      document.pageSettings.margins.all = 40;
      final PdfPage page = document.pages.add();
      final PdfGraphics graphics = page.graphics;

      // Define fonts
      final PdfFont headerFont = PdfStandardFont(PdfFontFamily.helvetica, 20,
          style: PdfFontStyle.bold);
      final PdfFont subHeaderFont = PdfStandardFont(PdfFontFamily.helvetica, 12,
          style: PdfFontStyle.bold);
      final PdfFont boldFont =
          PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold);
      final PdfFont regularFont = PdfStandardFont(PdfFontFamily.helvetica, 8);

      final double pageWidth = page.getClientSize().width;
      final double contentWidth = pageWidth - 80;
      double currentY = 40; // Track vertical position

      // Draw main header
      final Size headerSize = headerFont.measureString('TAX INVOICE');
      graphics.drawString('TAX INVOICE', headerFont,
          bounds: Rect.fromLTWH((pageWidth - headerSize.width) / 2, currentY,
              headerSize.width, headerSize.height));
      currentY += headerSize.height + 10;

      // Draw sub-header
      final String subHeader =
          'Invoice No: ${sale.invoiceNumber}     Date: ${DateFormat('dd-MMM-yyyy').format(sale.date)}';
      final Size subHeaderSize = subHeaderFont.measureString(subHeader);
      graphics.drawString(subHeader, subHeaderFont,
          bounds: Rect.fromLTWH((pageWidth - subHeaderSize.width) / 2, currentY,
              subHeaderSize.width, subHeaderSize.height));
      currentY += subHeaderSize.height + 20;

      // Get business and party state codes
      final String businessStateCode = businessProfile['stateCode'] ??
          getStateCode(businessProfile['state'] ?? 'Kerala');

      final String? partyState = party.shippingState!.isEmpty
          ? party.billingState
          : party.shippingState;

      // Check if party state is empty or null
      final bool isPartyStateEmpty = partyState == null || partyState.isEmpty;
      String partyStateCode = '';

      if (!isPartyStateEmpty) {
        partyStateCode = getStateCode(partyState);
      }

      // Define styles for address headers
      final PdfFont addressHeaderFont =
          PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold);
      final PdfBrush addressHeaderBrush = PdfSolidBrush(PdfColor(60, 60, 60));
      final PdfStringFormat centerAlign =
          PdfStringFormat(alignment: PdfTextAlignment.center);

      // Create background colors for address headers
      final PdfBrush fromHeaderBrush =
          PdfSolidBrush(PdfColor(240, 240, 240)); // Light gray
      final PdfBrush toHeaderBrush =
          PdfSolidBrush(PdfColor(240, 240, 240)); // Light gray

      // Define address box dimensions (reduced height)
      final double addressBoxWidth = contentWidth / 2 - 20;
      final double addressBoxHeight = 130; // Reduced height
      final double headerHeight = 18; // Reduced header height

      // ---------- FROM ADDRESS SECTION ----------
      // Draw from address header background
      graphics.drawRectangle(
          brush: fromHeaderBrush,
          bounds: Rect.fromLTWH(40, currentY, addressBoxWidth, headerHeight));

      // Draw "FROM" text in header
      graphics.drawString('FROM', addressHeaderFont,
          brush: addressHeaderBrush,
          bounds: Rect.fromLTWH(40, currentY, addressBoxWidth, headerHeight),
          format: centerAlign);

      // Draw from address box
      graphics.drawRectangle(
          pen: PdfPen(PdfColor(180, 180, 180), width: 0.5),
          bounds:
              Rect.fromLTWH(40, currentY, addressBoxWidth, addressBoxHeight));

      // Format business profile data in a more compact form
      final String fromAddress = '''${businessProfile['businessName']}
${businessProfile['address']}
${businessProfile['state']} - ${businessProfile['pincode']}, ${businessProfile['country']}
GSTIN: ${businessProfile['gstin']} 
PAN: ${businessProfile['pan']}
State Code: $businessStateCode
Email: ${businessProfile['email']} 
Ph: ${businessProfile['mobile']}''';

      // Draw from address content
      final PdfTextElement fromAddressElement = PdfTextElement(
          text: fromAddress,
          font: regularFont,
          brush: PdfSolidBrush(PdfColor(0, 0, 0)));

      fromAddressElement.draw(
          page: page,
          bounds: Rect.fromLTWH(45, currentY + headerHeight + 3,
              addressBoxWidth - 10, addressBoxHeight - headerHeight - 5));

      // ---------- TO ADDRESS SECTION ----------
      // Draw to address header background
      graphics.drawRectangle(
          brush: toHeaderBrush,
          bounds: Rect.fromLTWH(
              pageWidth / 2 + 20, currentY, addressBoxWidth, headerHeight));

      // Draw "TO" text in header
      graphics.drawString('TO', addressHeaderFont,
          brush: addressHeaderBrush,
          bounds: Rect.fromLTWH(
              pageWidth / 2 + 20, currentY, addressBoxWidth, headerHeight),
          format: centerAlign);

      // Draw to address box
      graphics.drawRectangle(
          pen: PdfPen(PdfColor(180, 180, 180), width: 0.5),
          bounds: Rect.fromLTWH(
              pageWidth / 2 + 20, currentY, addressBoxWidth, addressBoxHeight));

      // Parse transport details in more compact form
      String formattedTransportDetails = '';
      if (sale.transportaionDetails != null &&
          sale.transportaionDetails!.length >= 4) {
        formattedTransportDetails =
            '''Transport: ${sale.transportaionDetails![0]} | Vehicle: ${sale.transportaionDetails![1]}
Date of Supply: ${sale.transportaionDetails![2]} | Place: ${sale.transportaionDetails![3]}''';
      } else {
        formattedTransportDetails = '''Transport: N/A | Vehicle: N/A
Date of Supply: ${DateFormat('dd-MMM-yyyy').format(sale.date)} | Place: ${party.billingAddress}''';
      }

      // Format party data in more compact form
      final String toAddress = '''${party.name ?? "Party Name not provided"}
Shipping Address: ${party.shippingAddress}
GSTIN: ${party.gstNumber ?? 'N/A'} 
PAN: ${party.panNumber ?? 'N/A'}
State Code: ${isPartyStateEmpty ? 'N/A' : partyStateCode}
Email: ${party.email ?? 'N/A'} 
Ph: ${party.contactNumber ?? 'N/A'}
$formattedTransportDetails''';

      // Draw to address content
      final PdfTextElement toAddressElement = PdfTextElement(
          text: toAddress,
          font: regularFont,
          brush: PdfSolidBrush(PdfColor(0, 0, 0)));

      toAddressElement.draw(
          page: page,
          bounds: Rect.fromLTWH(pageWidth / 2 + 25, currentY + headerHeight + 3,
              addressBoxWidth - 10, addressBoxHeight - headerHeight - 5));

      // Update currentY to the bottom of the address sections (reduced spacing after)
      currentY +=
          addressBoxHeight + 10; // Reduced spacing after address section
      final PdfGrid itemsGrid = PdfGrid();
      itemsGrid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 8, right: 8, top: 5, bottom: 5),
        font: regularFont,
      );

      // Determine if we need to use IGST or CGST/SGST
      // If party state is empty, use generic GST instead of specific tax types
      final bool useGenericGST = isPartyStateEmpty;
      final bool isSameState = !useGenericGST &&
          partyState.toLowerCase() == businessProfile['state']?.toLowerCase();

      // Configure columns - Add columns based on GST type
      if (useGenericGST) {
        // Generic GST column when party state is empty
        itemsGrid.columns.add(count: 7);
        itemsGrid.columns[0].width = contentWidth * 0.08; // Sl No
        itemsGrid.columns[1].width = contentWidth * 0.32; // Description
        itemsGrid.columns[2].width = contentWidth * 0.10; // HSN/SAC
        itemsGrid.columns[3].width = contentWidth * 0.12; // Quantity
        itemsGrid.columns[4].width = contentWidth * 0.12; // Rate
        itemsGrid.columns[5].width = contentWidth * 0.14; // GST %
        itemsGrid.columns[6].width = contentWidth * 0.12; // Total
      } else if (isSameState) {
        // CGST and SGST columns for same state
        itemsGrid.columns.add(count: 9);
        itemsGrid.columns[0].width = contentWidth * 0.08; // Sl No
        itemsGrid.columns[1].width = contentWidth * 0.28; // Description
        itemsGrid.columns[2].width = contentWidth * 0.08; // HSN/SAC
        itemsGrid.columns[3].width = contentWidth * 0.10; // Quantity
        itemsGrid.columns[4].width = contentWidth * 0.10; // Rate
        itemsGrid.columns[5].width = contentWidth * 0.09; // CGST %
        itemsGrid.columns[6].width = contentWidth * 0.09; // SGST %
        itemsGrid.columns[7].width = contentWidth * 0.08; // Amount
        itemsGrid.columns[8].width = contentWidth * 0.10; // Total
      } else {
        // IGST column for different state
        itemsGrid.columns.add(count: 8);
        itemsGrid.columns[0].width = contentWidth * 0.08; // Sl No
        itemsGrid.columns[1].width = contentWidth * 0.30; // Description
        itemsGrid.columns[2].width = contentWidth * 0.08; // HSN/SAC
        itemsGrid.columns[3].width = contentWidth * 0.12; // Quantity
        itemsGrid.columns[4].width = contentWidth * 0.12; // Rate
        itemsGrid.columns[5].width = contentWidth * 0.12; // IGST %
        itemsGrid.columns[6].width = contentWidth * 0.08; // Amount
        itemsGrid.columns[7].width = contentWidth * 0.10; // Total
      }

      // Add header row with appropriate GST headers
      final PdfGridRow headerRow = itemsGrid.headers.add(1)[0];
      List<String> headers;

      if (useGenericGST) {
        headers = [
          'Sl No.',
          'Description',
          'HSN/SAC',
          'Quantity',
          'Rate',
          'GST %',
          'Total'
        ];
      } else if (isSameState) {
        headers = [
          'Sl No.',
          'Description',
          'HSN/SAC',
          'Quantity',
          'Rate',
          'CGST %',
          'SGST %',
          'Amount',
          'Total'
        ];
      } else {
        headers = [
          'Sl No.',
          'Description',
          'HSN/SAC',
          'Quantity',
          'Rate',
          'IGST %',
          'Amount',
          'Total'
        ];
      }

      for (int i = 0; i < headers.length; i++) {
        headerRow.cells[i].value = headers[i];
        headerRow.cells[i].style = PdfGridCellStyle(
            backgroundBrush: PdfSolidBrush(PdfColor(230, 230, 230)),
            font: boldFont,
            format: PdfStringFormat(
                alignment:
                    i == 1 ? PdfTextAlignment.left : PdfTextAlignment.right,
                lineAlignment: PdfVerticalAlignment.middle));
      }

      // Add items with GST breakdown
      double totalGST = 0;
      double totalCGST = 0;
      double totalSGST = 0;
      double totalIGST = 0;
      double subtotal = 0;

      if (sale.item.isNotEmpty) {
        for (int i = 0; i < sale.item.length; i++) {
          final item = sale.item[i];
          final PdfGridRow row = itemsGrid.rows.add();
          String unit = item.unit.contains('(') && item.unit.contains(')')
              ? item.unit
                  .substring(item.unit.indexOf('(') + 1, item.unit.indexOf(')'))
              : item.unit;

          double itemTotal = item.quantity * item.rate;
          double taxRate = item.taxAmount;
          double taxAmount = itemTotal * (taxRate / 100);

          if (useGenericGST) {
            // Use generic GST for empty party state
            totalGST += taxAmount;

            row.cells[0].value = (i + 1).toString();
            row.cells[1].value = item.itemName;
            row.cells[2].value = item.hsnCode ?? '--';
            row.cells[3].value = '${item.quantity} $unit';
            row.cells[4].value = NumberFormat('#,##0.00').format(item.rate);
            row.cells[5].value = taxRate.toStringAsFixed(2);
            row.cells[6].value =
                NumberFormat('#,##0.00').format(itemTotal + taxAmount);
          } else if (isSameState) {
            // Split tax into CGST and SGST
            double cgstRate = taxRate / 2;
            double sgstRate = taxRate / 2;
            double cgstAmount = taxAmount / 2;
            double sgstAmount = taxAmount / 2;

            totalCGST += cgstAmount;
            totalSGST += sgstAmount;

            row.cells[0].value = (i + 1).toString();
            row.cells[1].value = item.itemName;
            row.cells[2].value = item.hsnCode ?? '--';
            row.cells[3].value = '${item.quantity} $unit';
            row.cells[4].value = NumberFormat('#,##0.00').format(item.rate);
            row.cells[5].value = cgstRate.toStringAsFixed(2);
            row.cells[6].value = sgstRate.toStringAsFixed(2);
            row.cells[7].value = NumberFormat('#,##0.00').format(itemTotal);
            row.cells[8].value =
                NumberFormat('#,##0.00').format(itemTotal + taxAmount);
          } else {
            // Use IGST
            totalIGST += taxAmount;

            row.cells[0].value = (i + 1).toString();
            row.cells[1].value = item.itemName;
            row.cells[2].value = item.hsnCode ?? '--';
            row.cells[3].value = '${item.quantity} $unit';
            row.cells[4].value = NumberFormat('#,##0.00').format(item.rate);
            row.cells[5].value = taxRate.toStringAsFixed(2);
            row.cells[6].value = NumberFormat('#,##0.00').format(itemTotal);
            row.cells[7].value =
                NumberFormat('#,##0.00').format(itemTotal + taxAmount);
          }

          subtotal += itemTotal;

          // Style each cell in the row
          int colCount = useGenericGST ? 7 : (isSameState ? 9 : 8);
          for (int j = 0; j < colCount; j++) {
            row.cells[j].style = PdfGridCellStyle(
                backgroundBrush:
                    i % 2 == 1 ? PdfSolidBrush(PdfColor(245, 245, 245)) : null,
                borders: PdfBorders(
                  bottom: PdfPen(PdfColor(0, 0, 0), width: 0.5),
                  top: PdfPen(PdfColor(0, 0, 0), width: 0.5),
                  left: PdfPen(PdfColor(0, 0, 0), width: 0.5),
                  right: PdfPen(PdfColor(0, 0, 0), width: 0.5),
                ),
                font: regularFont,
                format: PdfStringFormat(
                    alignment:
                        j == 1 ? PdfTextAlignment.left : PdfTextAlignment.right,
                    lineAlignment: PdfVerticalAlignment.middle));
          }
        }
      }

      // Draw items grid at the current Y position
      final PdfLayoutResult itemsLayout = itemsGrid.draw(
          page: page, bounds: Rect.fromLTWH(40, currentY, contentWidth, 0))!;

      currentY = itemsLayout.bounds.bottom + 20;

      // Create and draw summary section
      final PdfGrid summaryGrid = PdfGrid();
      summaryGrid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 8, right: 8, top: 5, bottom: 5),
        font: regularFont,
      );

      summaryGrid.columns.add(count: 2);
      summaryGrid.columns[0].width = 120;
      summaryGrid.columns[1].width = 100;

      void addSummaryRow(String label, double value, {bool isBold = false}) {
        final row = summaryGrid.rows.add();
        row.cells[0].value = label;
        row.cells[1].value = NumberFormat('#,##0.00').format(value);

        for (int i = 0; i < 2; i++) {
          row.cells[i].style = PdfGridCellStyle(
              borders: PdfBorders(
                bottom: PdfPen(PdfColor(0, 0, 0), width: 0.5),
                top: PdfPen(PdfColor(0, 0, 0), width: 0.5),
                left: PdfPen(PdfColor(0, 0, 0), width: 0.5),
                right: PdfPen(PdfColor(0, 0, 0), width: 0.5),
              ),
              font: isBold ? boldFont : regularFont,
              format: PdfStringFormat(
                  alignment:
                      i == 0 ? PdfTextAlignment.left : PdfTextAlignment.right));
        }
      }

      addSummaryRow('Sub Total:', subtotal);

      if (sale.discounts != null && sale.discounts! > 0) {
        addSummaryRow('Discount:', sale.discounts!);
        subtotal -= sale.discounts!;
      }

      // Add GST breakdown based on state comparison and empty state handling
      double totalTaxAmount = 0;
      if (useGenericGST) {
        addSummaryRow('GST:', totalGST);
        totalTaxAmount = totalGST;
      } else if (isSameState) {
        addSummaryRow('CGST:', totalCGST);
        addSummaryRow('SGST:', totalSGST);
        totalTaxAmount = totalCGST + totalSGST;
      } else {
        addSummaryRow('IGST:', totalIGST);
        totalTaxAmount = totalIGST;
      }

      if (sale.shippingCharges != null && sale.shippingCharges! > 0) {
        addSummaryRow('Shipping:', sale.shippingCharges!);
        subtotal += sale.shippingCharges!;
      }
      if (sale.packingCharges != null && sale.packingCharges! > 0) {
        addSummaryRow('Packing Charges:', sale.packingCharges!);
        subtotal += sale.packingCharges!;
      }
      if (sale.additionalCharges != null && sale.additionalCharges! > 0) {
        addSummaryRow('Additional Charges:', sale.additionalCharges!);
        subtotal += sale.additionalCharges!;
      }

      final double totalAmount = subtotal + totalTaxAmount;
      addSummaryRow('Total Amount:', totalAmount, isBold: true);

      // Draw summary grid
      final PdfLayoutResult summaryLayout = summaryGrid.draw(
          page: page,
          bounds: Rect.fromLTWH(pageWidth - 260, currentY, 220, 0))!;

      currentY = summaryLayout.bounds.bottom + 20;

      // Convert amount to words and draw
      final numberToWord = NumberToWord();
      final String amountInWords = numberToWord.convert(totalAmount.round());
      final PdfTextElement amountInWordsElement = PdfTextElement(
          text: 'Amount in words:\nRupees $amountInWords Only',
          font: regularFont);

      final PdfLayoutResult amountInWordsLayout = amountInWordsElement.draw(
          page: page,
          bounds: Rect.fromLTWH(40, currentY, contentWidth - 260, 0))!;

      currentY = amountInWordsLayout.bounds.bottom + 20;

      // Add terms and conditions
      String termsText = '''
Terms and Conditions:
1. Goods once sold will not be taken back or exchanged
2. Interest @18% p.a. will be charged if the payment is not made within the stipulated time
3. Subject to local jurisdiction''';

      // Add bank details only if payment type is bank
      if (sale.paymentType?.toLowerCase() == 'bank') {
        termsText += '''

Bank Details:
   Bank Name: ${bankDetails['bankName'] ?? 'N/A'}
   Account Holder: ${bankDetails['accountHolder'] ?? 'N/A'}
   Account No: ${bankDetails['accountNumber'] ?? 'N/A'}
   IFSC Code: ${bankDetails['ifscCode'] ?? 'N/A'}
   Branch: ${bankDetails['bankBranch'] ?? 'N/A'}''';
      }

      final PdfTextElement termsElement =
          PdfTextElement(text: termsText, font: regularFont);
      final PdfLayoutResult termsLayout = termsElement.draw(
          page: page, bounds: Rect.fromLTWH(40, currentY, contentWidth, 0))!;

      currentY = termsLayout.bounds.bottom + 40;

      // Add footer
      final PdfTextElement footerElement = PdfTextElement(
          text: 'This is a computer generated invoice',
          font: regularFont,
          brush: PdfSolidBrush(PdfColor(128, 128, 128)));

      footerElement.draw(
          page: page,
          bounds: Rect.fromLTWH(
              40, page.getClientSize().height - 40, contentWidth, 0));

      // Save the document
      final String dir = (await getApplicationDocumentsDirectory()).path;
      final String path = '$dir/Invoice_${sale.invoiceNumber}.pdf';
      final File file = File(path);
      await file.writeAsBytes(await document.save());
      document.dispose();

      return path;
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      throw Exception('Failed to generate PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                // final path =
                await generateInvoice(sale);
                // Add your sharing logic here
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error sharing invoice: $e')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              (context as Element).markNeedsBuild();
            },
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: generateInvoice(sale),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData) {
            return SfPdfViewer.file(
              File(snapshot.data!),
              key: _pdfViewerKey,
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
