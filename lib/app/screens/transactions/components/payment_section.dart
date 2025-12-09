import 'package:account_book/app/providers/transaction_provider.dart';
import 'package:account_book/app/screens/transactions/export.dart';

class PaymentTypeSection extends StatefulWidget {
  final String paymentType;
  final ValueChanged<String?> onPaymentTypeChange;

  const PaymentTypeSection({
    super.key,
    required this.paymentType,
    required this.onPaymentTypeChange,
  });

  @override
  PaymentTypeSectionState createState() => PaymentTypeSectionState();
}

class PaymentTypeSectionState extends State<PaymentTypeSection> {
  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final String? bankDetailsJson = prefs.getString('bankDetails');
    prefs.getString('selectedBankId');

    if (bankDetailsJson != null) {
      json.decode(bankDetailsJson);
      setState(() {});
    }
  }

  void _showBankDetailsBottomSheet([Map<String, String>? existingDetails]) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return BankDetailsBottomSheet(
          existingDetails: existingDetails,
          onSave: (newDetails) async {
            List<Map<String, String>> updatedAccounts;

            if (existingDetails != null) {
              updatedAccounts = List.from(provider.bankAccounts);
              int index = updatedAccounts.indexOf(existingDetails);
              updatedAccounts[index] = newDetails;
            } else {
              updatedAccounts = List.from(provider.bankAccounts)
                ..add(newDetails);
              // Auto-select if first account
              if (updatedAccounts.length == 1) {
                await provider.saveSelectedBank(newDetails['accountNumber']);
              }
            }

            await provider.saveBankDetails(updatedAccounts);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Cash', label: Text('Cash')),
              ButtonSegment(value: 'Cheque', label: Text('Cheque')),
              ButtonSegment(value: 'Card', label: Text('Card')),
              ButtonSegment(value: 'Upi', label: Text('Upi')),
              ButtonSegment(value: 'Bank', label: Text('Bank')),
            ],
            selected: {widget.paymentType},
            onSelectionChanged: (Set<String> newSelection) {
              widget.onPaymentTypeChange(newSelection.first);
              if (newSelection.first != 'Bank') {
                provider.setSelectedBankId(null);
              }
            },
          ),
        ),
        if (widget.paymentType == 'Bank')
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                ...provider.bankAccounts.map((account) => RadioListTile<String>(
                      title: Text(
                          '${account['bankName']} - ${account['accountNumber']}'),
                      subtitle: Text('IFSC: ${account['ifscCode']}'),
                      value: account['accountNumber']!,
                      groupValue: provider.selectedBankId,
                      onChanged: (String? value) {
                        provider.saveSelectedBank(value);
                      },
                      secondary: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showBankDetailsBottomSheet(account),
                      ),
                    )),
                if (provider.bankAccounts.isEmpty)
                  const Text(
                    'No bank accounts added yet',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => _showBankDetailsBottomSheet(),
                      child: const Text('Add Bank Account'),
                    ),
                    if (provider.selectedBankId != null)
                      TextButton(
                        onPressed: () {
                          provider.saveSelectedBank(null);
                        },
                        child: const Text('Clear Selection',
                            style: TextStyle(color: Colors.red)),
                      )
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
