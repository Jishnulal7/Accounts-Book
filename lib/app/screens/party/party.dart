import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/party/exports.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';

class PartyScreen extends StatelessWidget {
  const PartyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: SpeedDial(
        onPress: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateParty(
              onPartyCreated: () {
                Provider.of<PartyProvider>(context, listen: false)
                    .fetchParties();
              },
            ),
          ),
        ),
        label: const Text('Create a Party'),
        animatedIcon: AnimatedIcons.add_event,
      ),
      body: Consumer<PartyProvider>(
        builder: (context, partyProvider, child) {
          if (partyProvider.partyList.isEmpty) {
            return _buildEmptyState(context);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // Use list view for screens smaller than 600px
              if (constraints.maxWidth < 600) {
                return RefreshIndicator(
                  onRefresh: () => partyProvider.fetchParties(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: partyProvider.partyList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final party = partyProvider.partyList[index];
                      return _buildPartyCard(
                          context, party, partyProvider, false);
                    },
                  ),
                );
              }

              // Use grid view for larger screens
              final columnCount = _calculateColumnCount(constraints.maxWidth);
              return RefreshIndicator(
                onRefresh: () => partyProvider.fetchParties(),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    childAspectRatio: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: partyProvider.partyList.length,
                  itemBuilder: (context, index) {
                    final party = partyProvider.partyList[index];
                    return _buildPartyCard(context, party, partyProvider, true);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  int _calculateColumnCount(double width) {
    if (width < 900) return 2; // Tablet
    if (width < 1200) return 3; // Desktop
    return 4; // Large Desktop
  }

  Widget _buildPartyCard(
    BuildContext context,
    PartyModel party,
    PartyProvider partyProvider,
    bool isGrid,
  ) {
    final isCustomer = party.isCustomer ?? false;
    final balance = party.openingBalance ?? 0;
    final balanceColor = balance >= 0 ? Colors.green : Colors.red;
    final partyBalance = partyProvider.calculatePartyBalance(party.name!);
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: isGrid ? EdgeInsets.zero : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PartyDetails(
              partyId: party.id!,
              partyName: party.name!,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCustomer ? Colors.blue : Colors.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          party.name!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isCustomer ? Icons.person : Icons.business,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCustomer ? 'Customer' : 'Supplier',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(party.date!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isGrid) const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Balance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '$currencySymbol ${partyBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 20),
          const Text(
            'No Parties Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to create a new party',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
