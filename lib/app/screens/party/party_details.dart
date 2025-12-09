import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/providers/edit_transaction_provider.dart';
import 'package:account_book/app/screens/party/exports.dart';

class PartyDetails extends StatefulWidget {
  final String partyId;
  final String partyName;

  const PartyDetails({
    super.key,
    required this.partyId,
    required this.partyName,
  });

  @override
  State<PartyDetails> createState() => _PartyDetailsState();
}

class _PartyDetailsState extends State<PartyDetails> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PartyProvider>(context, listen: false)
          .fetchPartyTransactions(widget.partyName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Consumer<PartyProvider>(
      builder: (context, partyProvider, child) {
        final party = partyProvider.getPartyById(widget.partyId);
        if (party == null) {
          return const Center(child: Text('Party not found'));
        }
        final partyBalance =
            partyProvider.calculatePartyBalance(widget.partyName);

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: Text(
              '${party.isCustomer == true ? 'Customer' : 'Supplier'} Details',
            ),
            actions: [
              _buildActionButton(
                icon: Icons.picture_as_pdf,
                label: 'Statement',
                onTap: () => _navigateToStatement(context),
              ),
              _buildActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () => _navigateToEdit(context, party, partyProvider),
              ),
              _buildActionButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                onTap: () => _checkAndShowDeleteDialog(context, partyProvider),
                isDestructive: true,
              ),
            ],
          ),
          body: isWideScreen
              ? _buildWideScreenLayout(
                  context, party, partyProvider, partyBalance, currencySymbol)
              : _buildMobileLayout(
                  context, party, partyProvider, partyBalance, currencySymbol),
        );
      },
    );
  }

  Widget _buildWideScreenLayout(BuildContext context, dynamic party,
      PartyProvider partyProvider, double partyBalance, String currencySymbol) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel with party details
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(context, party),
                const SizedBox(height: 16),
                _buildStatusCard(context, party, partyBalance, currencySymbol),
                const SizedBox(height: 16),
                _buildMetricsGrid(context, party, partyBalance, currencySymbol),
              ],
            ),
          ),
        ),
        // Right panel with tabs
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
            child: Card(
              child: CustomTabBar(
                tabTitles: const ['Party Transactions', 'Details'],
                tabViews: [
                  TransactionTypesList(
                    transactions: partyProvider.transactions,
                    onAddPayment:
                        (transaction, amount, date, method, reference) async {
                      // Use the appropriate provider or service to add the payment
                      final provider = Provider.of<EditTransactionProvider>(
                          context,
                          listen: false);
                      await provider.addPaymentRecord(
                        amount: amount,
                        paymentDate: date,
                        paymentMethod: method,
                        reference: reference,
                      );
                    },
                  ),
                  PartyTimeline(
                    partyName: widget.partyName,
                    partyId: widget.partyId,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, dynamic party,
      PartyProvider partyProvider, double partyBalance, String currencySymbol) {
    return Column(
      children: [
        Column(
          children: [
            _buildHeader(context, party),
            _buildStatusCard(context, party, partyBalance, currencySymbol),
            _buildMetricsGrid(context, party, partyBalance, currencySymbol),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomTabBar(
              tabTitles: const ['Party Transactions', 'Details'],
              tabViews: [
                TransactionTypesList(
                  transactions: partyProvider.transactions,
                  onAddPayment:
                      (transaction, amount, date, method, reference) async {
                    // Use the appropriate provider or service to add the payment
                    final provider = Provider.of<EditTransactionProvider>(
                        context,
                        listen: false);
                    await provider.addPaymentRecord(
                      amount: amount,
                      paymentDate: date,
                      paymentMethod: method,
                      reference: reference,
                    );
                  },
                ),
                PartyTimeline(
                  partyName: widget.partyName,
                  partyId: widget.partyId,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, dynamic party) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              party.name ?? '--',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: party.isCustomer == true
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                party.isCustomer == true ? 'Customer' : 'Supplier',
                style: TextStyle(
                  color: party.isCustomer == true ? Colors.blue : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, dynamic party,
      double partyBalance, String currencySymbol) {
    return Container(
      alignment: Alignment.topLeft,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol  ${partyBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: partyBalance >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, dynamic party,
      double partyBalance, String currencySymbol) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return GridView.count(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWideScreen ? 1 : 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: isWideScreen ? 3 : 2.2,
      children: [
        _buildMetricCard(
          context,
          title: 'Total Receivable',
          value:
              '$currencySymbol ${(partyBalance > 0 ? partyBalance : 0).toStringAsFixed(2)}',
          subtitle: 'Amount to receive',
          icon: Icons.arrow_upward,
          color: Colors.green,
        ),
        _buildMetricCard(
          context,
          title: 'Total Payable',
          value:
              '$currencySymbol ${(partyBalance < 0 ? -partyBalance : 0).toStringAsFixed(2)}',
          subtitle: 'Amount to pay',
          icon: Icons.arrow_downward,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: label,
      child: IconButton(
        icon: Icon(
          icon,
          color: isDestructive ? Colors.red : null,
        ),
        onPressed: onTap,
      ),
    );
  }

  // Navigation and Dialog Methods
  void _navigateToEdit(
      BuildContext context, dynamic party, PartyProvider partyProvider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditParty(
          party: party,
          onPartyEdit: () {
            partyProvider.fetchParties();
          },
        ),
      ),
    );
    if (result == true) {
      if (!context.mounted) return;
      Navigator.pop(context, true);
    }
  }

  void _navigateToStatement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartyStatementPage(
          partyName: widget.partyName,
        ),
      ),
    );
  }

  // New method to check transactions before showing delete dialog
  void _checkAndShowDeleteDialog(
      BuildContext context, PartyProvider partyProvider) {
    // Check if party has transactions
    bool hasTransactions = partyProvider.hasPartyTransactions(widget.partyName);

    if (hasTransactions) {
      // Show error dialog if party has transactions
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete Party'),
          content: const Text(
            'This party has associated sale or purchase transactions and cannot be deleted. You must delete all transactions for this party first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Show delete confirmation if no transactions
      _showDeleteDialog(context, partyProvider);
    }
  }

  void _showDeleteDialog(BuildContext context, PartyProvider partyProvider) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        cancelButtonText: 'Cancel',
        confirmButtonText: 'Delete',
        content: 'Are you sure you want to delete this party?',
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          final success = await partyProvider.deleteParty(widget.partyId);
          Navigator.pop(context); // Close dialog
          if (success) {
            Navigator.pop(context); // Return to parties list
          }
        },
        title: 'Delete Party',
      ),
    );
  }
}
