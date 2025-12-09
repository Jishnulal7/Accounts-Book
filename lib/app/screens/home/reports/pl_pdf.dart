import 'package:account_book/app/screens/home/exports.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'dart:async';


class ProfitLossPdfService {
  // Use "Rs." instead of the ₹ symbol with consistent formatting
  final currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

  // Document styling constants
  final _colors = _PdfColorScheme();
  final _spacing = _PdfSpacing();

  Future<String> generatePdf({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required ProfitLossData data,
    String? companyName,
    String? companyLogo,
    bool includeTaxInfo = false,
    String fileName = 'profit_loss_report',
  }) async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Set document properties
    document.compressionLevel = PdfCompressionLevel.best;

    // Add metadata
    document.documentInformation.title =
        '$title - ${DateFormat('dd/MM/yyyy').format(startDate)} to ${DateFormat('dd/MM/yyyy').format(endDate)}';
    document.documentInformation.author = companyName ?? 'Account Book App';
    document.documentInformation.creator = 'Account Book App';
    document.documentInformation.subject = 'Financial Report';

    // Add a new page with better margins
    final PdfPage page = document.pages.add();
    final Size pageSize =
        Size(page.getClientSize().width, page.getClientSize().height);

    double currentPosition = 0;

    // Add logo and company info if available
    if (companyName != null || companyLogo != null) {
      currentPosition = await _buildCompanyHeader(
        page: page,
        pageSize: pageSize,
        companyName: companyName,
        companyLogo: companyLogo,
      );
      currentPosition += _spacing.large;
    }

    // Add report header
    final PdfLayoutResult headerResult = await _buildHeader(
      page: page,
      pageSize: pageSize,
      title: title,
      startDate: startDate,
      endDate: endDate,
      yPosition: currentPosition,
    );

    currentPosition = headerResult.bounds.bottom + _spacing.large;

    // Add Trading Account section with improved visual design
    currentPosition = _buildTradingAccountSection(
      page: page,
      pageSize: pageSize,
      data: data,
      yPosition: currentPosition,
    );

    currentPosition += _spacing.large;

    // Add Profit & Loss Account section with consistent styling
    currentPosition = _buildProfitLossAccountSection(
      page: page,
      pageSize: pageSize,
      data: data,
      yPosition: currentPosition,
    );

    currentPosition += _spacing.large;

    // Add Net Profit Section with improved visual appeal
    currentPosition = _buildNetProfitSection(
      page: page,
      pageSize: pageSize,
      data: data,
      yPosition: currentPosition,
    );

    // Add tax information if requested
    if (includeTaxInfo) {
      currentPosition += _spacing.large;
      _buildTaxNotesSection(
          page: page, pageSize: pageSize, yPosition: currentPosition);
    }

    // Add footer with pagination
    _addFooter(page, pageSize);

    // Save and return the file path
    return _savePdf(document, fileName);
  }

  Future<double> _buildCompanyHeader({
    required PdfPage page,
    required Size pageSize,
    String? companyName,
    String? companyLogo,
  }) async {
    double yPosition = _spacing.medium;
    final double leftMargin = _spacing.horizontalMargin;

    // Add company logo if provided
    if (companyLogo != null) {
      try {
        final File logoFile = File(companyLogo);
        if (await logoFile.exists()) {
          final PdfBitmap logo = PdfBitmap(await logoFile.readAsBytes());
          page.graphics.drawImage(
            logo,
            Rect.fromLTWH(leftMargin, yPosition, 50, 50),
          );
        }
      } catch (e) {
        debugPrint('Could not load company logo: $e');
      }
    }

    // Add company name if provided
    if (companyName != null) {
      final PdfFont companyNameFont = PdfStandardFont(
          PdfFontFamily.helvetica, 18,
          style: PdfFontStyle.bold);

      final double textX = companyLogo != null ? leftMargin + 60 : leftMargin;

      PdfTextElement(
        text: companyName,
        font: companyNameFont,
        brush: PdfSolidBrush(_colors.primary),
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(textX, yPosition + 10, pageSize.width - 100, 30),
      );
    }

    return yPosition + 60;
  }

  Future<PdfLayoutResult> _buildHeader({
    required PdfPage page,
    required Size pageSize,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    double yPosition = 40,
  }) async {
    // Use standard fonts with better sizing
    final PdfFont headerFont =
        PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    final PdfFont subHeaderFont = PdfStandardFont(PdfFontFamily.helvetica, 11);

    // Draw header background
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_colors.headerBackground),
      bounds: Rect.fromLTWH(_spacing.horizontalMargin, yPosition,
          pageSize.width - (_spacing.horizontalMargin * 2), 60),
    );

    // Draw header border
    page.graphics.drawRectangle(
      pen: PdfPen(_colors.border, width: 0.7),
      bounds: Rect.fromLTWH(_spacing.horizontalMargin, yPosition,
          pageSize.width - (_spacing.horizontalMargin * 2), 60),
    );

    // Draw the title with improved formatting
    final PdfLayoutResult result = PdfTextElement(
      text: title.toUpperCase(),
      font: headerFont,
      brush: PdfSolidBrush(_colors.primaryText),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(_spacing.horizontalMargin, yPosition + 10,
          pageSize.width - (_spacing.horizontalMargin * 2), 30),
    )!;

    // Draw the date range with improved formatting
    final String dateRange =
        'From ${DateFormat('dd MMM yyyy').format(startDate)} to ${DateFormat('dd MMM yyyy').format(endDate)}';
    PdfTextElement(
      text: dateRange,
      font: subHeaderFont,
      brush: PdfSolidBrush(_colors.secondaryText),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(_spacing.horizontalMargin, result.bounds.bottom + 5,
          pageSize.width - (_spacing.horizontalMargin * 2), 20),
    );

    return result;
  }

  double _buildTradingAccountSection({
    required PdfPage page,
    required Size pageSize,
    required ProfitLossData data,
    required double yPosition,
  }) {
    // Define section width and positions with better margins
    final double sectionWidth =
        pageSize.width - (_spacing.horizontalMargin * 2);
    final double leftMargin = _spacing.horizontalMargin;
    final double rightMargin = leftMargin + sectionWidth;
    final double sectionHeight = 200; // Adjusted for better spacing

    // Create section heading with improved fonts
    final PdfFont sectionFont =
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
    final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final PdfFont boldContentFont =
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

    // Section header with improved style
    final PdfLayoutResult sectionResult = PdfTextElement(
      text: 'TRADING ACCOUNT',
      font: sectionFont,
      brush: PdfSolidBrush(_colors.primary),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(leftMargin, yPosition, sectionWidth, 20),
    )!;

    double currentY = sectionResult.bounds.bottom + _spacing.medium;

    // Draw section background with rounded corners
    _drawRoundedRectangle(
      page: page,
      bounds: Rect.fromLTWH(leftMargin, currentY, sectionWidth, sectionHeight),
      fillColor: _colors.sectionBackground,
      borderColor: _colors.border,
      borderWidth: 0.7,
    );

    currentY += _spacing.medium;

    // Draw column headers with background
    _drawSectionColumnHeaders(
      page: page,
      leftMargin: leftMargin,
      rightMargin: rightMargin,
      yPosition: currentY,
      leftTitle: 'Debit Side',
      rightTitle: 'Credit Side',
    );

    currentY += 25;

    // Draw debit side entries with improved layout
    final double columnWidth = (sectionWidth - 40) / 2;

    // First column: debit entries
    _drawLineItem(page, 'Opening Stock', data.openingStock, leftMargin + 10,
        currentY, contentFont, false, columnWidth);
    currentY += _spacing.lineHeight;

    _drawLineItem(page, 'Purchases', data.netPurchases, leftMargin + 10,
        currentY, contentFont, false, columnWidth);
    currentY += _spacing.lineHeight;

    _drawLineItem(page, 'Direct Expenses', data.directExpenses, leftMargin + 10,
        currentY, contentFont, false, columnWidth);
    currentY += _spacing.lineHeight;

    // Draw divider line
    _drawDashedLine(
      page: page,
      startX: leftMargin + 10,
      endX: leftMargin + columnWidth - 10,
      y: currentY,
      dashColor: _colors.divider,
    );

    currentY += _spacing.small;

    // Draw debit total with improved styling
    final double debitTotal =
        data.openingStock + data.netPurchases + data.directExpenses;
    _drawLineItem(page, 'Total', debitTotal, leftMargin + 10, currentY,
        boldContentFont, false, columnWidth, true);

    // Second column: credit entries (positioned on right side)
    double creditY = currentY - (2 * _spacing.lineHeight);

    _drawLineItem(page, 'Sales', data.netSales, leftMargin + columnWidth + 20,
        creditY, contentFont, true, columnWidth);
    creditY += _spacing.lineHeight;

    _drawLineItem(page, 'Closing Stock', data.closingStock,
        leftMargin + columnWidth + 20, creditY, contentFont, true, columnWidth);
    creditY += _spacing.lineHeight;

    // Draw divider line for credit side
    _drawDashedLine(
      page: page,
      startX: leftMargin + columnWidth + 20,
      endX: rightMargin - 10,
      y: creditY,
      dashColor: _colors.divider,
    );

    creditY += _spacing.small;

    // Draw credit total with improved styling
    final double creditTotal = data.netSales + data.closingStock;
    _drawLineItem(page, 'Total', creditTotal, leftMargin + columnWidth + 20,
        creditY, boldContentFont, true, columnWidth, true);

    // Calculate where to place the gross profit/loss section
    final double gpSectionY = currentY + 30;

    // Draw gross profit/loss box with improved styling
    _drawGrossProfitLossBox(
        page: page,
        data: data,
        yPosition: gpSectionY,
        leftMargin: leftMargin,
        width: sectionWidth);

    return yPosition +
        sectionHeight +
        60; // Return bottom position of the section
  }

  double _buildProfitLossAccountSection({
    required PdfPage page,
    required Size pageSize,
    required ProfitLossData data,
    required double yPosition,
  }) {
    // Define section width and positions with better margins
    final double sectionWidth =
        pageSize.width - (_spacing.horizontalMargin * 2);
    final double leftMargin = _spacing.horizontalMargin;
    final double rightMargin = leftMargin + sectionWidth;
    final double sectionHeight = 180; // Adjusted for better spacing

    // Create section heading with improved fonts
    final PdfFont sectionFont =
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
    final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final PdfFont boldContentFont =
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

    // Section header with improved style
    final PdfLayoutResult sectionResult = PdfTextElement(
      text: 'PROFIT & LOSS ACCOUNT',
      font: sectionFont,
      brush: PdfSolidBrush(_colors.primary),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(leftMargin, yPosition, sectionWidth, 20),
    )!;

    double currentY = sectionResult.bounds.bottom + _spacing.medium;

    // Draw section background with rounded corners
    _drawRoundedRectangle(
      page: page,
      bounds: Rect.fromLTWH(leftMargin, currentY, sectionWidth, sectionHeight),
      fillColor: _colors.sectionBackground,
      borderColor: _colors.border,
      borderWidth: 0.7,
    );

    currentY += _spacing.medium;

    // Draw column headers with background
    _drawSectionColumnHeaders(
      page: page,
      leftMargin: leftMargin,
      rightMargin: rightMargin,
      yPosition: currentY,
      leftTitle: 'Debit Side',
      rightTitle: 'Credit Side',
    );

    currentY += 25;

    // Draw debit and credit sides with improved layout
    final double columnWidth = (sectionWidth - 40) / 2;

    // First column: debit entries
    _drawLineItem(page, 'Indirect Expenses', data.indirectExpenses,
        leftMargin + 10, currentY, contentFont, false, columnWidth);
    currentY += _spacing.lineHeight;

    // Draw divider line
    _drawDashedLine(
      page: page,
      startX: leftMargin + 10,
      endX: leftMargin + columnWidth - 10,
      y: currentY,
      dashColor: _colors.divider,
    );

    currentY += _spacing.small;

    // Draw debit total with improved styling
    _drawLineItem(page, 'Total', data.indirectExpenses, leftMargin + 10,
        currentY, boldContentFont, false, columnWidth, true);

    // Second column: credit entries
    double creditY = currentY - _spacing.lineHeight;

    _drawLineItem(
        page,
        'Gross Profit b/d',
        data.grossProfit > 0 ? data.grossProfit : 0,
        leftMargin + columnWidth + 20,
        creditY - _spacing.lineHeight,
        contentFont,
        true,
        columnWidth);

    _drawLineItem(page, 'Indirect Incomes', data.indirectIncomes,
        leftMargin + columnWidth + 20, creditY, contentFont, true, columnWidth);
    creditY += _spacing.lineHeight;

    // Draw divider line for credit side
    _drawDashedLine(
      page: page,
      startX: leftMargin + columnWidth + 20,
      endX: rightMargin - 10,
      y: creditY,
      dashColor: _colors.divider,
    );

    creditY += _spacing.small;

    // Draw credit total with improved styling
    final double creditTotal =
        (data.grossProfit > 0 ? data.grossProfit : 0) + data.indirectIncomes;
    _drawLineItem(page, 'Total', creditTotal, leftMargin + columnWidth + 20,
        creditY, boldContentFont, true, columnWidth, true);

    return yPosition + sectionHeight + 40; // Return bottom position
  }

  double _buildNetProfitSection({
    required PdfPage page,
    required Size pageSize,
    required ProfitLossData data,
    required double yPosition,
  }) {
    // Define section width and positions with better margins
    final double sectionWidth =
        pageSize.width - (_spacing.horizontalMargin * 2);
    final double leftMargin = _spacing.horizontalMargin;

    // Create fonts with improved sizing
    final PdfFont titleFont =
        PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
    final PdfFont amountFont =
        PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);

    // Background color based on profit/loss with improved colors
    final PdfColor backgroundColor = data.netProfitBeforeTax >= 0
        ? _colors.profitBackground
        : _colors.lossBackground;

    // Text color based on profit/loss
    final PdfColor textColor =
        data.netProfitBeforeTax >= 0 ? _colors.profit : _colors.loss;

    // Draw background with rounded corners for better appearance
    _drawRoundedRectangle(
      page: page,
      bounds: Rect.fromLTWH(leftMargin, yPosition, sectionWidth, 70),
      fillColor: backgroundColor,
      borderColor: textColor,
      borderWidth: 1.0,
      cornerRadius: 10,
    );

    // Draw title text with improved positioning
    final String titleText = data.netProfitBeforeTax >= 0
        ? 'NET PROFIT FOR THE PERIOD'
        : 'NET LOSS FOR THE PERIOD';

    PdfTextElement(
      text: titleText,
      font: titleFont,
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(leftMargin, yPosition + 15, sectionWidth, 20),
    );

    // Draw amount text with improved styling
    PdfTextElement(
      text: currencyFormat.format(data.netProfitBeforeTax.abs()),
      font: amountFont,
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
      brush: PdfSolidBrush(textColor),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(leftMargin, yPosition + 35, sectionWidth, 30),
    );

    return yPosition + 70; // Return bottom position
  }

  double _buildTaxNotesSection({
    required PdfPage page,
    required Size pageSize,
    required double yPosition,
  }) {
    final double sectionWidth =
        pageSize.width - (_spacing.horizontalMargin * 2);
    final double leftMargin = _spacing.horizontalMargin;

    final PdfFont noteHeaderFont =
        PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);
    final PdfFont noteFont = PdfStandardFont(PdfFontFamily.helvetica, 9);

    // Draw note header
    PdfTextElement(
      text: 'NOTES:',
      font: noteHeaderFont,
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(leftMargin, yPosition, sectionWidth, 20),
    );

    // Draw note content
    const String note =
        'This report is prepared for internal management purposes only. '
        'Tax calculations and statutory compliance should be performed separately '
        'in accordance with applicable tax laws and regulations.';

    PdfTextElement(
      text: note,
      font: noteFont,
      format: PdfStringFormat(
        alignment: PdfTextAlignment.left,
        paragraphIndent: 0,
        wordWrap: PdfWordWrapType.word,
      ),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(leftMargin, yPosition + 20, sectionWidth, 50),
    );

    return yPosition + 70;
  }

  void _addFooter(PdfPage page, Size pageSize) {
    final PdfFont footerFont = PdfStandardFont(PdfFontFamily.helvetica, 8);
    final String footerText =
        'Generated on ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())} | Page 1 of 1';

    PdfTextElement(
      text: footerText,
      font: footerFont,
      brush: PdfSolidBrush(_colors.secondaryText),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(_spacing.horizontalMargin, pageSize.height - 40,
          pageSize.width - (_spacing.horizontalMargin * 2), 20),
    );
  }

  void _drawLineItem(PdfPage page, String label, double amount, double x,
      double y, PdfFont font, bool isCredit, double maxWidth,
      [bool isTotal = false]) {
    // Draw background for total rows
    if (isTotal) {
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(isCredit
            ? _colors.creditTotalBackground
            : _colors.debitTotalBackground),
        bounds: Rect.fromLTWH(x, y - 2, maxWidth - 20, 20),
      );
    }

    // Draw label with improved alignment
    PdfTextElement(
      text: label,
      font: font,
      brush: PdfSolidBrush(isTotal ? _colors.totalText : _colors.primaryText),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(x + 5, y, maxWidth * 0.6, 20),
    );

    // Draw amount with improved alignment and formatting
    final PdfColor textColor = isCredit ? _colors.credit : _colors.debit;
    PdfTextElement(
      text: currencyFormat.format(amount),
      font: font,
      brush: PdfSolidBrush(isTotal ? _colors.totalText : textColor),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(x, y, maxWidth - 25, 20),
    );
  }

  void _drawRoundedRectangle({
    required PdfPage page,
    required Rect bounds,
    required PdfColor fillColor,
    required PdfColor borderColor,
    double borderWidth = 0.5,
    double cornerRadius = 5,
  }) {
    // Draw fill
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(fillColor),
      bounds:
          Rect.fromLTWH(bounds.left, bounds.top, bounds.width, bounds.height),
      // cornerRadius: cornerRadius,
    );

    // Draw border
    page.graphics.drawRectangle(
      pen: PdfPen(borderColor, width: borderWidth),
      bounds:
          Rect.fromLTWH(bounds.left, bounds.top, bounds.width, bounds.height),
      // cornerRadius: cornerRadius,
    );
  }

  void _drawSectionColumnHeaders({
    required PdfPage page,
    required double leftMargin,
    required double rightMargin,
    required double yPosition,
    required String leftTitle,
    required String rightTitle,
  }) {
    final double sectionWidth = rightMargin - leftMargin;
    final double columnWidth = (sectionWidth - 40) / 2;
    final PdfFont headerFont =
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

    // Left header with background
    _drawRoundedRectangle(
      page: page,
      bounds: Rect.fromLTWH(leftMargin + 10, yPosition, columnWidth - 10, 20),
      fillColor: _colors.debitHeaderBackground,
      borderColor: _colors.debitHeaderBorder,
    );

    // Left title
    PdfTextElement(
      text: leftTitle,
      font: headerFont,
      brush: PdfSolidBrush(_colors.headerText),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(leftMargin + 10, yPosition, columnWidth - 10, 20),
    );

    // Right header with background
    _drawRoundedRectangle(
      page: page,
      bounds: Rect.fromLTWH(
          leftMargin + columnWidth + 20, yPosition, columnWidth - 10, 20),
      fillColor: _colors.creditHeaderBackground,
      borderColor: _colors.creditHeaderBorder,
    );

    // Right title
    PdfTextElement(
      text: rightTitle,
      font: headerFont,
      brush: PdfSolidBrush(_colors.headerText),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(
          leftMargin + columnWidth + 20, yPosition, columnWidth - 10, 20),
    );
  }

  void _drawDashedLine({
    required PdfPage page,
    required double startX,
    required double endX,
    required double y,
    required PdfColor dashColor,
  }) {
    final PdfPen dashPen = PdfPen(
      dashColor,
      width: 0.5,
      dashStyle: PdfDashStyle.dash,
    );

    page.graphics.drawLine(
      dashPen,
      Offset(startX, y),
      Offset(endX, y),
    );
  }

  void _drawGrossProfitLossBox({
    required PdfPage page,
    required ProfitLossData data,
    required double yPosition,
    required double leftMargin,
    required double width,
  }) {
    final String gpLabel =
        data.grossProfit >= 0 ? 'GROSS PROFIT' : 'GROSS LOSS';
    final PdfColor backgroundColor = data.grossProfit >= 0
        ? PdfColor(235, 255, 235)
        : PdfColor(255, 235, 235);
    final PdfColor textColor =
        data.grossProfit >= 0 ? _colors.profit : _colors.loss;

    final PdfFont gpFont =
        PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);

    // Draw background with gradient effect
    _drawRoundedRectangle(
      page: page,
      bounds: Rect.fromLTWH(
          leftMargin + (width * 0.25), yPosition, width * 0.5, 40),
      fillColor: backgroundColor,
      borderColor: textColor,
      cornerRadius: 8,
    );

    // Draw label
    PdfTextElement(
      text: gpLabel,
      font: gpFont,
      brush: PdfSolidBrush(textColor),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(
          leftMargin + (width * 0.25), yPosition + 5, width * 0.5, 20),
    );

    // Draw amount
// Draw amount
    PdfTextElement(
      text: currencyFormat.format(data.grossProfit.abs()),
      font: gpFont,
      brush: PdfSolidBrush(textColor),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    ).draw(
      page: page,
      bounds: Rect.fromLTWH(
          leftMargin + (width * 0.25), yPosition + 20, width * 0.5, 20),
    );
  }

  Future<String> _savePdf(PdfDocument document, String fileName) async {
    // Get application directory
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String timestamp =
        DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String outputPath = '${appDocDir.path}/${fileName}_$timestamp.pdf';

    // Save document to file
    final File file = File(outputPath);
    await file.writeAsBytes(await document.save());

    // Dispose the document
    document.dispose();

    return outputPath;
  }

  Future<void> openPdf(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        debugPrint('Error opening PDF: ${result.message}');
        // Consider showing a message to the user here
      }
    } catch (e) {
      debugPrint('Error opening PDF: $e');
      // Consider showing a message to the user here
    }
  }

  // Helper method to share PDF
  Future<bool> sharePdf(String filePath) async {
    try {
      // final result = await Share.shareFiles(
      //   [filePath],
      //   text: 'Profit & Loss Report',
      //   subject: 'Financial Report',
      // );
      return true;
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      return false;
    }
  }
}

/// Color scheme for PDF styling
class _PdfColorScheme {
  // Primary colors
  final PdfColor primary = PdfColor(0, 75, 145);
  final PdfColor secondary = PdfColor(128, 128, 128);

  // Text colors
  final PdfColor primaryText = PdfColor(50, 50, 50);
  final PdfColor secondaryText = PdfColor(100, 100, 100);
  final PdfColor headerText = PdfColor(255, 255, 255);
  final PdfColor totalText = PdfColor(50, 50, 50);

  // Background colors
  final PdfColor headerBackground = PdfColor(0, 75, 145);
  final PdfColor sectionBackground = PdfColor(250, 250, 250);

  // Border colors
  final PdfColor border = PdfColor(200, 200, 200);
  final PdfColor divider = PdfColor(180, 180, 180);

  // Debit/Credit colors
  final PdfColor debit = PdfColor(220, 50, 50);
  final PdfColor credit = PdfColor(0, 128, 0);

  // Header backgrounds
  final PdfColor debitHeaderBackground = PdfColor(240, 128, 128);
  final PdfColor debitHeaderBorder = PdfColor(220, 50, 50);
  final PdfColor creditHeaderBackground = PdfColor(144, 238, 144);
  final PdfColor creditHeaderBorder = PdfColor(0, 128, 0);

  // Total row backgrounds
  final PdfColor debitTotalBackground = PdfColor(255, 230, 230);
  final PdfColor creditTotalBackground = PdfColor(230, 255, 230);

  // Profit/Loss colors
  final PdfColor profit = PdfColor(0, 128, 0);
  final PdfColor loss = PdfColor(220, 50, 50);
  final PdfColor profitBackground = PdfColor(235, 255, 235);
  final PdfColor lossBackground = PdfColor(255, 235, 235);

  // Extensions
  PdfColor get lighter => PdfColor(
        (red + 80) > 255 ? 255 : red + 80,
        (green + 80) > 255 ? 255 : green + 80,
        (blue + 80) > 255 ? 255 : blue + 80,
      );

  int get red => _color.red;
  int get green => _color.green;
  int get blue => _color.blue;

  final Color _color = Color(0xFF000000);
}

/// Spacing constants for PDF layout
class _PdfSpacing {
  final double small = 5.0;
  final double medium = 10.0;
  final double large = 20.0;
  final double lineHeight = 18.0;
  final double horizontalMargin = 50.0;
}

/// Data class for storing profit and loss information
class ProfitLossData {
  final double netSales;
  final double netPurchases;
  final double openingStock;
  final double closingStock;
  final double directExpenses;
  final double indirectIncomes;
  final double indirectExpenses;
  final double grossProfit;
  final double netProfitBeforeTax;

  ProfitLossData({
    required this.netSales,
    required this.netPurchases,
    required this.openingStock,
    required this.closingStock,
    required this.directExpenses,
    required this.indirectIncomes,
    required this.indirectExpenses,
    required this.grossProfit,
    required this.netProfitBeforeTax,
  });
}
