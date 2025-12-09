import 'package:account_book/app/screens/party/exports.dart';

class TransactionType {
  (String, PdfColor) getTransactionTypeStyle(String type) {
    switch (type.toLowerCase()) {
      // Sales types
      case 'sale':
        return ('Sale', PdfColor(255, 137, 71)); // deepOrangeAccent
      case 'sales return':
        return ('Sales Return', PdfColor(255, 137, 71));
      case 'credit note':
        return ('Credit Note', PdfColor(255, 137, 71));
      case 'estimate':
        return ('Estimate', PdfColor(255, 137, 71));
      case 'delivery challan':
        return ('Delivery Challan', PdfColor(255, 137, 71));

      // Purchase types
      case 'purchase':
        return ('Purchase', PdfColor(76, 175, 80)); // AppColor.kGreen
      case 'debit note':
        return ('Debit Note', PdfColor(255, 137, 71));
      case 'purchase order':
        return ('Purchase Order', PdfColor(255, 137, 71));
      case 'purchase return':
        return ('Purchase Return', PdfColor(255, 137, 71));

      default:
        return (type, PdfColor(0, 0, 0)); // Default black
    }
  }
}
