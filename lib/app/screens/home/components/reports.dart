import 'package:account_book/app/screens/home/exports.dart';
import 'package:account_book/app/screens/home/reports/purchases/purchase_transactions.dart';

class ReportsQuickLink extends StatefulWidget {
  final VoidCallback onSaleAdded;

  const ReportsQuickLink({
    super.key,
    required this.onSaleAdded,
  });

  @override
  State<ReportsQuickLink> createState() => _ReportsQuickLinkState();
}

class _ReportsQuickLinkState extends State<ReportsQuickLink> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header row
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reports',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          Column(
            children: [
              _buildAllReportsGrid(context),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCardColor(BuildContext context, MaterialColor baseColor) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      // For dark mode, use a darker shade with reduced opacity
      return baseColor.shade700.withOpacity(0.2);
    }
    // For light mode, use the original light shade
    return baseColor.shade50;
  }

  Widget _buildAllReportsGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return StaggeredGrid.count(
            crossAxisCount: _getCrossAxisCount(constraints.maxWidth),
            mainAxisSpacing: _getGridSpacing(constraints.maxWidth),
            crossAxisSpacing: _getGridSpacing(constraints.maxWidth),
            children: [
              _buildReportCard(
                context,
                icon: Icons.table_chart_outlined,
                label: 'Reports',
                description: 'Access all reports',
                color: _getCardColor(context, Colors.green),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReportsScreen()),
                ),
              ),
              _buildReportCard(
                context,
                icon: Icons.list_alt,
                label: 'All Transactions',
                description: 'Track & Manage all transactions',
                color: _getCardColor(context, Colors.blue),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllTransactionsScreen(),
                  ),
                ),
              ),
              _buildReportCard(
                context,
                icon: Icons.receipt,
                label: 'Sale Transactions',
                description: 'Track & Manage sale type transactions',
                color: _getCardColor(context, Colors.green),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SalesScreens(
                      onSaleAdded: () =>
                          Provider.of<DashboardProvider>(context, listen: false)
                              .refreshData(),
                    ),
                  ),
                ),
              ),
              _buildReportCard(
                context,
                icon: Icons.shopping_cart,
                label: 'Purchases Transactions',
                description: 'Track & Manage purchase type transactions',
                color: _getCardColor(context, Colors.blue),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PurchaseScreens(
                      onSaleAdded: () =>
                          Provider.of<DashboardProvider>(context, listen: false)
                              .refreshData(),
                    ),
                  ),
                ),
              ),
              _buildReportCard(
                context,
                icon: Icons.description,
                label: 'Balance Sheet',
                description: 'View financial position',
                color: _getCardColor(context, Colors.green),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BalanceSheetScreen()),
                ),
              ),
              _buildReportCard(
                context,
                icon: Icons.percent,
                label: 'Profit & Loss',
                description: 'Track business proformance',
                color: _getCardColor(context, Colors.blue),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfitAndLossScreen(),
                  ),
                ),
              ),
              _buildReportCard(
                context,
                icon: Icons.text_snippet,
                label: 'Day Book',
                description: 'Track Daily Transactions ',
                color: _getCardColor(context, Colors.green),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DayBookScreen(),
                  ),
                ),
              ),
              _buildReportCard(
                context,
                icon: Icons.payment,
                label: 'Cash Book',
                description: 'Track Cash Releted Transactions ',
                color: _getCardColor(context, Colors.blue),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CashbookScreen(),
                  ),
                ),
              ),
              _buildReportCard(
                context,
                icon: Icons.assessment,
                label: 'Assets',
                description: 'Track Assets ',
                color: _getCardColor(context, Colors.green),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssetsScreen(),
                  ),
                ),
              ),
              _buildReportCard(
                context,
                icon: Icons.looks_sharp,
                label: 'Liability',
                description: 'Track Liabilities ',
                color: _getCardColor(context, Colors.blue),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiabilitiesScreen(),
                  ),
                ),
              ),
              _buildReportCard(
                context,
                icon: Icons.track_changes,
                label: 'Trail Balance',
                description: 'Track Liabilities ',
                color: _getCardColor(context, Colors.green),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrialBalanceScreen(),
                  ),
                ),
              ),
              _buildReportCard(
                context,
                icon: Icons.person,
                label: 'Party Ledger',
                description: 'Track business Proformance',
                color: _getCardColor(context, Colors.blue),
                onTap: () async {
                  // Get parties from the provider
                  final provider =
                      Provider.of<DashboardProvider>(context, listen: false);
                  final parties = await provider.getParties();

                  // Show party selection dialog
                  if (context.mounted) {
                    final selectedParty = await showDialog<PartyModel>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Select Party'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: parties.length,
                              itemBuilder: (context, index) {
                                final party = parties[index];
                                return ListTile(
                                  title: Text(party.name ?? 'Unknown Party'),
                                  subtitle: Text(party.contactNumber ?? ''),
                                  onTap: () {
                                    Navigator.of(context).pop(party);
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );

                    // If a party was selected, navigate to the ledger
                    if (selectedParty != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return PartyLedger(
                              partyId: selectedParty.id ?? '',
                            );
                          },
                        ),
                      );
                    }
                  }
                },
              ),
              _buildReportCard(
                context,
                icon: Icons.inventory_2_outlined,
                label: 'Item Report',
                description: 'Track business Proformance',
                color: _getCardColor(context, Colors.green),
                onTap: () async {
                  // Get parties from the provider
                  final provider =
                      Provider.of<DashboardProvider>(context, listen: false);
                  final parties = await provider.getItems();

                  // Show party selection dialog
                  if (context.mounted) {
                    final selectedParty = await showDialog<ItemModel>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Select Item'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: parties.length,
                              itemBuilder: (context, index) {
                                final party = parties[index];
                                return ListTile(
                                  title:
                                      Text(party.itemName ?? 'Unknown Party'),
                                  subtitle: Text(party.subCategory ?? ''),
                                  onTap: () {
                                    Navigator.of(context).pop(party);
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );

                    // If a party was selected, navigate to the ledger
                    if (selectedParty != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return ItemLedgerScreen(
                              itemId: selectedParty.id ?? '',
                            );
                          },
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  int _getCrossAxisCount(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 3;
  }

  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.8),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getGridSpacing(double width) {
    if (width < 600) return 16;
    if (width < 900) return 20;
    if (width < 1200) return 24;
    return 28;
  }
}
