

import 'package:account_book/app/screens/profile/exports.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  List<Map<String, String>> _bankAccounts = [];
  static const double maxContentWidth = 800; // Wider than profile screen for better display of bank details

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final String? bankDetailsJson = prefs.getString('bankDetails');

    if (bankDetailsJson != null) {
      final List<dynamic> dynamicList = json.decode(bankDetailsJson);
      setState(() {
        _bankAccounts = dynamicList.map((item) {
          return Map<String, String>.from(item);
        }).toList();
      });
    }
  }

  double _calculateHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= maxContentWidth) {
      return 16.0;
    }
    final extraSpace = (screenWidth - maxContentWidth) / 2;
    return extraSpace > 24 ? 24.0 : extraSpace;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Details'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: _calculateHorizontalPadding(context),
              vertical: 16,
            ),
            child: Column(
              children: [
                if (_bankAccounts.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No bank details added',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _bankAccounts.length,
                    itemBuilder: (context, index) {
                      final account = _bankAccounts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.account_balance,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            title: Text(
                              account['bankName'] ?? 'Bank Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('Account Holder', account['accountHolder']),
                                  _buildDetailRow('Account Number', account['accountNumber']),
                                  _buildDetailRow('Branch', account['bankBranch']),
                                  _buildDetailRow('IFSC Code', account['ifscCode']),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Edit',
                                  onPressed: () => _editBankAccount(account),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Delete',
                                  onPressed: () => _removeBankAccount(account),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddBankDetailsDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Bank Details'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editBankAccount(Map<String, String> account) async {
    final int index = _bankAccounts.indexOf(account);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return BankDetailsBottomSheet(
          onSave: (updatedDetails) async {
            setState(() {
              _bankAccounts[index] = updatedDetails;
            });
            await _saveBankDetails();
          },
          existingDetails: account,
        );
      },
    );
  }

  Future<void> _showAddBankDetailsDialog([Map<String, String>? existingDetails]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return BankDetailsBottomSheet(
          onSave: (newDetails) async {
            setState(() {
              _bankAccounts.add(newDetails);
            });
            await _saveBankDetails();
          },
          existingDetails: existingDetails,
        );
      },
    );
  }

  Future<void> _saveBankDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bankDetails', json.encode(_bankAccounts));
  }

  void _removeBankAccount(Map<String, String> account) async {
    setState(() {
      _bankAccounts.remove(account);
    });
    await _saveBankDetails();
  }
}