import 'package:account_book/app/screens/home/exports.dart';
import 'package:hive_ce/hive.dart';

class PurchaseScreens extends StatefulWidget {
  const PurchaseScreens({super.key, required this.onSaleAdded});
  final VoidCallback onSaleAdded;

  @override
  State<PurchaseScreens> createState() => _PurchaseScreensState();
}

class _PurchaseScreensState extends State<PurchaseScreens>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isSearching = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  SortOption currentSort = SortOption.dateDesc;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_updateFAB);
  }

  List<PurchaseModel> sortSales(List<PurchaseModel> sales) {
    switch (currentSort) {
      case SortOption.dateAsc:
        return sales..sort((a, b) => a.date.compareTo(b.date));
      case SortOption.dateDesc:
        return sales..sort((a, b) => b.date.compareTo(a.date));
      case SortOption.amountAsc:
        return sales..sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
      case SortOption.amountDesc:
        return sales..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_updateFAB);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateFAB() {
    setState(() {}); // Force rebuild to update FAB
  }

  String _getTitle() {
    switch (_tabController.index) {
      case 0:
        return 'Purchases';
      case 1:
        return 'Purchase Orders';
      case 2:
        return 'Purchase Returns';
      default:
        return 'Purchases';
    }
  }

  Widget _getFloatingActionButton(BuildContext context) {
    switch (_tabController.index) {
      case 0:
        return SpeedDial(
          label: Text('Add Purchase'),
          child: const Icon(Icons.add),
          onPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatePurchase(
                  onItemAdded: widget.onSaleAdded,
                ),
              ),
            );
          },
        );
      case 1:
        return SpeedDial(
          label: Text('Add Purchase Order'),
          child: const Icon(Icons.add),
          onPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PurchaseOrder(
                  onItemAdded: widget.onSaleAdded,
                ),
              ),
            );
          },
        );
      case 2:
        return SpeedDial(
          label: Text('Add Purchase Return'),
          child: const Icon(Icons.add),
          onPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PurchaseReturn(
                  onItemAdded: widget.onSaleAdded,
                ),
              ),
            );
          },
        );
      default:
        return SpeedDial(
          label: Text('Add Purchase'),
          child: const Icon(Icons.add),
          onPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatePurchase(
                  onItemAdded: widget.onSaleAdded,
                ),
              ),
            );
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search purchases...',
                  border: InputBorder.none,
                ),
                onChanged: (value) =>
                    setState(() => searchQuery = value.toLowerCase()),
              )
            : Text(_getTitle()),
        actions: [
          GlobalSortButton(
            currentSort: currentSort,
            onSortChanged: (SortOption newSort) {
              setState(() => currentSort = newSort);
            },
          ),
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  isSearching = false;
                  searchQuery = '';
                  _searchController.clear();
                } else {
                  isSearching = true;
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Purchases'),
            Tab(text: 'Purchase Orders'),
            Tab(text: 'Purchase Returns'),
          ],
        ),
      ),
      floatingActionButton: _getFloatingActionButton(context),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPurchaseList(),
          _buildPurchaseOrderList(),
          _buildPurchaseReturnList(),
        ],
      ),
    );
  }

  Widget _buildPurchaseList() {
    return FutureBuilder(
      future: Provider.of<DashboardProvider>(context, listen: false).getBoxes(),
      builder: (context, AsyncSnapshot<List<Box<dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final purchaseBox = snapshot.data![1] as Box<PurchaseModel>;
          final partyBox = snapshot.data![5] as Box<PartyModel>;

          return Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              List<PurchaseModel> filteredPurchases = purchaseBox.values
                  .where((purchase) => purchase.type == PurchaseType.purchase)
                  .toList();

              filteredPurchases = filteredPurchases.where((purchase) {
                if (searchQuery.isEmpty) return true;
                return purchase.partyName.toLowerCase().contains(searchQuery) ||
                    partyBox.values
                        .firstWhere(
                          (p) => p.id == purchase.partyId,
                          orElse: () => PartyModel(name: purchase.partyName),
                        )
                        .name!
                        .toLowerCase()
                        .contains(searchQuery);
              }).toList();

              // Apply sorting
              filteredPurchases = sortSales(filteredPurchases);

              return ListView.builder(
                itemCount: filteredPurchases.length,
                itemBuilder: (context, index) {
                  final purchase = filteredPurchases[index];
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == purchase.partyId,
                    orElse: () => PartyModel(name: purchase.partyName),
                  );

                  return TransactionCard(
                    sale: null,
                    purchaseModel: purchase,
                    onSaleDeleted: () => provider.refreshData(),
                    onSaleUpdated: () => provider.refreshData(),
                    onPurchaseUpdated: () => provider.refreshData(),
                    party: party,
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildPurchaseOrderList() {
    return FutureBuilder(
      future: Provider.of<DashboardProvider>(context, listen: false).getBoxes(),
      builder: (context, AsyncSnapshot<List<Box<dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final purchaseBox = snapshot.data![1] as Box<PurchaseModel>;
          final partyBox = snapshot.data![5] as Box<PartyModel>;

          return Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              List<PurchaseModel> filteredPurchases = purchaseBox.values
                  .where(
                      (purchase) => purchase.type == PurchaseType.purchaseOrder)
                  .toList();

              filteredPurchases = filteredPurchases.where((purchase) {
                if (searchQuery.isEmpty) return true;
                return purchase.partyName.toLowerCase().contains(searchQuery) ||
                    partyBox.values
                        .firstWhere(
                          (p) => p.id == purchase.partyId,
                          orElse: () => PartyModel(name: purchase.partyName),
                        )
                        .name!
                        .toLowerCase()
                        .contains(searchQuery);
              }).toList();

              // Apply sorting
              filteredPurchases = sortSales(filteredPurchases);

              return ListView.builder(
                itemCount: filteredPurchases.length,
                itemBuilder: (context, index) {
                  final purchase = filteredPurchases[index];
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == purchase.partyId,
                    orElse: () => PartyModel(name: purchase.partyName),
                  );

                  return TransactionCard(
                    sale: null,
                    purchaseModel: purchase,
                    onSaleDeleted: () => provider.refreshData(),
                    onSaleUpdated: () => provider.refreshData(),
                    onPurchaseUpdated: () => provider.refreshData(),
                    party: party,
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildPurchaseReturnList() {
    return FutureBuilder(
      future: Provider.of<DashboardProvider>(context, listen: false).getBoxes(),
      builder: (context, AsyncSnapshot<List<Box<dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final purchaseBox = snapshot.data![1] as Box<PurchaseModel>;
          final partyBox = snapshot.data![5] as Box<PartyModel>;

          return Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              List<PurchaseModel> filteredPurchases = purchaseBox.values
                  .where((purchase) =>
                      purchase.type == PurchaseType.purchaseReturn)
                  .toList();

              filteredPurchases = filteredPurchases.where((purchase) {
                if (searchQuery.isEmpty) return true;
                return purchase.partyName.toLowerCase().contains(searchQuery) ||
                    partyBox.values
                        .firstWhere(
                          (p) => p.id == purchase.partyId,
                          orElse: () => PartyModel(name: purchase.partyName),
                        )
                        .name!
                        .toLowerCase()
                        .contains(searchQuery);
              }).toList();

              // Apply sorting
              filteredPurchases = sortSales(filteredPurchases);

              return ListView.builder(
                itemCount: filteredPurchases.length,
                itemBuilder: (context, index) {
                  final purchase = filteredPurchases[index];
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == purchase.partyId,
                    orElse: () => PartyModel(name: purchase.partyName),
                  );

                  return TransactionCard(
                    sale: null,
                    purchaseModel: purchase,
                    onSaleDeleted: () => provider.refreshData(),
                    onSaleUpdated: () => provider.refreshData(),
                    onPurchaseUpdated: () => provider.refreshData(),
                    party: party,
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}
