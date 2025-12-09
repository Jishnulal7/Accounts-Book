import 'dart:async';
import 'package:account_book/app/screens/home/exports.dart';
import 'package:account_book/app/screens/transactions/sales/sale_order.dart';
import 'package:hive_ce/hive.dart';

class SalesScreens extends StatefulWidget {
  const SalesScreens({super.key, required this.onSaleAdded});
  final VoidCallback onSaleAdded;

  @override
  State<SalesScreens> createState() => _SalesScreensState();
}

class _SalesScreensState extends State<SalesScreens>
    with SingleTickerProviderStateMixin {
  bool isSearching = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  SortOption currentSort = SortOption.dateDesc;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_updateFAB);
  }

  void _updateFAB() {
    // setState(() {}); // Force rebuild to update FAB
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SaleModel> sortSales(List<SaleModel> sales) {
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

  String _getTitle() {
    switch (_tabController.index) {
      case 1:
        return 'Sales Order';
      case 0:
        return 'Invoices / Sales';
      case 2:
        return 'Sales Return';
      case 3:
        return 'Proforma Invoices';
      case 4:
        return 'Delivery Challan';
      case 5:
        return 'Quotations';
      default:
        return 'Sales Order';
    }
  }

  Widget _getFloatingActionButton(BuildContext context) {
    switch (_tabController.index) {
      case 1:
        return SpeedDial(
          label: Text('Add Sales Order'),
          child: const Icon(Icons.add),
          onPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SaleOrder(
                  onItemAdded: widget.onSaleAdded,
                ),
              ),
            );
          },
        );
      case 0:
        return SpeedDial(
          label: Text('Add Invoice'),
          child: const Icon(Icons.add),
          onPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateSale(
                  onItemAdded: widget.onSaleAdded,
                ),
              ),
            );
          },
        );
      case 2:
        return SpeedDial(
          label: Text('Add Sales Return'),
          child: const Icon(Icons.add),
          onPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SalesReturn(
                  onItemAdded: widget.onSaleAdded,
                ),
              ),
            );
          },
        );
      case 3:
        return SpeedDial(
          label: Text('Add Proforma'),
          child: const Icon(Icons.add),
          onPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProformaInvoice(
                  onItemAdded: widget.onSaleAdded,
                ),
              ),
            );
          },
        );
      case 4:
        return SpeedDial(
          label: Text('Add Delivery Challan'),
          child: const Icon(Icons.add),
          onPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeliveryChallan(
                  onItemAdded: widget.onSaleAdded,
                ),
              ),
            );
          },
        );
      case 5:
        return SpeedDial(
          label: Text('Add Quotation'),
          child: const Icon(Icons.add),
          onPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Estimate(
                  onItemAdded: widget.onSaleAdded,
                ),
              ),
            );
          },
        );
      default:
        return SpeedDial(
          label: Text('Add Sales Order'),
          child: const Icon(Icons.add),
          onPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SaleOrder(
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    Timer? debounce;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search ${_getTitle().toLowerCase()}...',
                    border: InputBorder.none,
                  ),
                  // onChanged: (value) =>
                  //     setState(() => searchQuery = value.toLowerCase()),
                  onChanged: (value) {
                    if (debounce?.isActive ?? false) debounce!.cancel();
                    debounce = Timer(const Duration(milliseconds: 300), () {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    });
                  },
                )
              : Row(
                  children: [
                    Text(_getTitle()),
                    const SizedBox(width: 4),
                    Icon(
                      currentSort == SortOption.dateAsc
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                    ),
                  ],
                ),
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
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: SizedBox(
              width: double.infinity,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: isSmallScreen
                    ? TabAlignment.start
                    : TabAlignment.center, // Center align on larger screens
                labelPadding:
                    EdgeInsets.symmetric(horizontal: 16), // Consistent padding
                onTap: (index) {
                  setState(() {});
                },
                tabs: const [
                  Tab(text: 'Invoices / Sales'),
                  Tab(text: 'Sales Order'),
                  Tab(text: 'Sales Return'),
                  Tab(text: 'Proforma'),
                  Tab(text: 'Delivery Challan'),
                  Tab(text: 'Quotations'),
                ],
              ),
            ),
          ),
          leadingWidth: isSmallScreen ? 40 : null,
        ),
        floatingActionButton: _getFloatingActionButton(context),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInvoiceList(),
            _buildSalesOrderList(),
            _buildSalesReturnList(),
            _buildProformaInvoiceList(),
            _buildDeliveryChallanList(),
            _buildQuotationList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceList() {
    return FutureBuilder(
      future: Provider.of<DashboardProvider>(context, listen: false).getBoxes(),
      builder: (context, AsyncSnapshot<List<Box<dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final saleBox = snapshot.data![0] as Box<SaleModel>;
          final partyBox = snapshot.data![5] as Box<PartyModel>;

          return Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              List<SaleModel> validSales = saleBox.values
                  .where(
                    (sale) =>
                        sale.type != SalesType.estimation &&
                        sale.type != SalesType.deliveryChallan &&
                        sale.type != SalesType.salesReturn &&
                        sale.type != SalesType.proforma &&
                        sale.type != SalesType.salesOrder,
                  )
                  .toList();

              if (searchQuery.isNotEmpty) {
                validSales = validSales.where((sale) {
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == sale.partyId,
                    orElse: () => PartyModel(name: sale.partyName),
                  );
                  return party.name!.toLowerCase().contains(searchQuery) ||
                      sale.partyName.toLowerCase().contains(searchQuery);
                }).toList();
              }

              validSales = sortSales(validSales);

              return ListView.builder(
                itemCount: validSales.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final sale = validSales[index];
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == sale.partyId,
                    orElse: () => PartyModel(name: sale.partyName),
                  );

                  return TransactionCard(
                    party: party,
                    sale: sale,
                    purchaseModel: null,
                    onSaleDeleted: () => provider.refreshData(),
                    onSaleUpdated: () => provider.refreshData(),
                    onPurchaseUpdated: () => provider.refreshData(),
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildQuotationList() {
    return FutureBuilder(
      future: Provider.of<DashboardProvider>(context, listen: false).getBoxes(),
      builder: (context, AsyncSnapshot<List<Box<dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final saleBox = snapshot.data![0] as Box<SaleModel>;
          final partyBox = snapshot.data![5] as Box<PartyModel>;

          return Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              List<SaleModel> validSales = saleBox.values
                  .where(
                    (sale) => sale.type == SalesType.estimation,
                  )
                  .toList();

              if (searchQuery.isNotEmpty) {
                validSales = validSales.where((sale) {
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == sale.partyId,
                    orElse: () => PartyModel(name: sale.partyName),
                  );
                  return party.name!.toLowerCase().contains(searchQuery) ||
                      sale.partyName.toLowerCase().contains(searchQuery);
                }).toList();
              }

              return ListView.builder(
                itemCount: validSales.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final sale = validSales[index];
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == sale.partyId,
                    orElse: () => PartyModel(name: sale.partyName),
                  );

                  return TransactionCard(
                    party: party,
                    sale: sale,
                    purchaseModel: null,
                    onSaleDeleted: () => provider.refreshData(),
                    onSaleUpdated: () => provider.refreshData(),
                    onPurchaseUpdated: () => provider.refreshData(),
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildSalesReturnList() {
    return FutureBuilder(
      future: Provider.of<DashboardProvider>(context, listen: false).getBoxes(),
      builder: (context, AsyncSnapshot<List<Box<dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final saleBox = snapshot.data![0] as Box<SaleModel>;
          final partyBox = snapshot.data![5] as Box<PartyModel>;

          return Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              List<SaleModel> validSales = saleBox.values
                  .where(
                    (sale) =>
                        sale.type != SalesType.estimation &&
                        sale.type != SalesType.deliveryChallan &&
                        sale.type != SalesType.sale &&
                        sale.type != SalesType.proforma &&
                        sale.type != SalesType.salesOrder,
                  )
                  .toList();

              if (searchQuery.isNotEmpty) {
                validSales = validSales.where((sale) {
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == sale.partyId,
                    orElse: () => PartyModel(name: sale.partyName),
                  );
                  return party.name!.toLowerCase().contains(searchQuery) ||
                      sale.partyName.toLowerCase().contains(searchQuery);
                }).toList();
              }

              validSales = sortSales(validSales);

              return ListView.builder(
                itemCount: validSales.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final sale = validSales[index];
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == sale.partyId,
                    orElse: () => PartyModel(name: sale.partyName),
                  );

                  return TransactionCard(
                    party: party,
                    sale: sale,
                    purchaseModel: null,
                    onSaleDeleted: () => provider.refreshData(),
                    onSaleUpdated: () => provider.refreshData(),
                    onPurchaseUpdated: () => provider.refreshData(),
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildSalesOrderList() {
    return FutureBuilder(
      future: Provider.of<DashboardProvider>(context, listen: false).getBoxes(),
      builder: (context, AsyncSnapshot<List<Box<dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final saleBox = snapshot.data![0] as Box<SaleModel>;
          final partyBox = snapshot.data![5] as Box<PartyModel>;

          return Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              List<SaleModel> validSales = saleBox.values
                  .where(
                    (sale) => sale.type == SalesType.salesOrder,
                  )
                  .toList();

              if (searchQuery.isNotEmpty) {
                validSales = validSales.where((sale) {
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == sale.partyId,
                    orElse: () => PartyModel(name: sale.partyName),
                  );
                  return party.name!.toLowerCase().contains(searchQuery) ||
                      sale.partyName.toLowerCase().contains(searchQuery);
                }).toList();
              }

              validSales = sortSales(validSales);

              return ListView.builder(
                itemCount: validSales.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final sale = validSales[index];
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == sale.partyId,
                    orElse: () => PartyModel(name: sale.partyName),
                  );

                  return TransactionCard(
                    party: party,
                    sale: sale,
                    purchaseModel: null,
                    onSaleDeleted: () => provider.refreshData(),
                    onSaleUpdated: () => provider.refreshData(),
                    onPurchaseUpdated: () => provider.refreshData(),
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildProformaInvoiceList() {
    return FutureBuilder(
      future: Provider.of<DashboardProvider>(context, listen: false).getBoxes(),
      builder: (context, AsyncSnapshot<List<Box<dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final saleBox = snapshot.data![0] as Box<SaleModel>;
          final partyBox = snapshot.data![5] as Box<PartyModel>;

          return Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              List<SaleModel> validSales = saleBox.values
                  .where(
                    (sale) => sale.type == SalesType.proforma,
                  )
                  .toList();

              if (searchQuery.isNotEmpty) {
                validSales = validSales.where((sale) {
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == sale.partyId,
                    orElse: () => PartyModel(name: sale.partyName),
                  );
                  return party.name!.toLowerCase().contains(searchQuery) ||
                      sale.partyName.toLowerCase().contains(searchQuery);
                }).toList();
              }

              return ListView.builder(
                itemCount: validSales.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final sale = validSales[index];
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == sale.partyId,
                    orElse: () => PartyModel(name: sale.partyName),
                  );

                  return TransactionCard(
                    party: party,
                    sale: sale,
                    purchaseModel: null,
                    onSaleDeleted: () => provider.refreshData(),
                    onSaleUpdated: () => provider.refreshData(),
                    onPurchaseUpdated: () => provider.refreshData(),
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildDeliveryChallanList() {
    return FutureBuilder(
      future: Provider.of<DashboardProvider>(context, listen: false).getBoxes(),
      builder: (context, AsyncSnapshot<List<Box<dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final saleBox = snapshot.data![0] as Box<SaleModel>;
          final partyBox = snapshot.data![5] as Box<PartyModel>;

          return Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              List<SaleModel> validSales = saleBox.values
                  .where(
                    (sale) => sale.type == SalesType.deliveryChallan,
                  )
                  .toList();

              if (searchQuery.isNotEmpty) {
                validSales = validSales.where((sale) {
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == sale.partyId,
                    orElse: () => PartyModel(name: sale.partyName),
                  );
                  return party.name!.toLowerCase().contains(searchQuery) ||
                      sale.partyName.toLowerCase().contains(searchQuery);
                }).toList();
              }

              return ListView.builder(
                itemCount: validSales.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final sale = validSales[index];
                  final party = partyBox.values.firstWhere(
                    (p) => p.id == sale.partyId,
                    orElse: () => PartyModel(name: sale.partyName),
                  );

                  return TransactionCard(
                    party: party,
                    sale: sale,
                    purchaseModel: null,
                    onSaleDeleted: () => provider.refreshData(),
                    onSaleUpdated: () => provider.refreshData(),
                    onPurchaseUpdated: () => provider.refreshData(),
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
