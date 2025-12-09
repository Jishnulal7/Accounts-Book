import 'package:account_book/app/screens/home/exports.dart';
import 'package:account_book/app/screens/home/reports/purchases/purchase_transactions.dart';
import 'package:account_book/app/screens/transactions/sales/sale_order.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  bool _isDrawerExpanded = true;

  // Refresh keys for each tab
  final List<GlobalKey<RefreshableWidgetState>> _refreshKeys = [
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
    GlobalKey<RefreshableWidgetState>(),
  ];

  // Widget options
  late final List<Widget> _widgetOptions = [
    const Dashboard(),
    const PartyScreen(),
    const ItemScreen(),
    ReportsQuickLink(
      onSaleAdded: () =>
          Provider.of<DashboardProvider>(context, listen: false).refreshData(),
    ),
    SalesScreens(
      onSaleAdded: () {
        Provider.of<DashboardProvider>(context, listen: false).refreshData();
      },
    ),
    CreateSale(
      isDrawer: true,
      onItemAdded: () {
        Provider.of<DashboardProvider>(context, listen: false).refreshData();
      },
    ),
    SaleOrder(
      onItemAdded: () {
        Provider.of<DashboardProvider>(context, listen: false).refreshData();
      },
      isDrawer: true,
    ),
    SalesReturn(
      isDrawer: true,
      onItemAdded: () {
        Provider.of<DashboardProvider>(context, listen: false).refreshData();
      },
    ),
    Estimate(
      isDrawer: true,
      onItemAdded: () {
        Provider.of<DashboardProvider>(context, listen: false).refreshData();
      },
    ),
    ProformaInvoice(
      isDrawer: true,
      onItemAdded: () {
        Provider.of<DashboardProvider>(context, listen: false).refreshData();
      },
    ),
    DeliveryChallan(
      isDrawer: true,
      onItemAdded: () {
        Provider.of<DashboardProvider>(context, listen: false).refreshData();
      },
    ),
    const YarimaWalletHome(),
    PurchaseScreens(
      onSaleAdded: () {
        Provider.of<DashboardProvider>(context, listen: false).refreshData();
      },
    ),
    CreatePurchase(
      isDrawer: true,
      onItemAdded: () {
        Provider.of<DashboardProvider>(context, listen: false).refreshData();
      },
    ),
    PurchaseOrder(
      isDrawer: true,
      onItemAdded: () {
        Provider.of<DashboardProvider>(context, listen: false).refreshData();
      },
    ),
    PurchaseReturn(
      isDrawer: true,
      onItemAdded: () {
        Provider.of<DashboardProvider>(context, listen: false).refreshData();
      },
    ),
    const YarimaWalletHome(),
  ];

  void _toggleDrawer(bool isExpanded) {
    setState(() {
      _isDrawerExpanded = isExpanded;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = Platform.isWindows;
    final mobileWidgetOptions = _widgetOptions.sublist(0, 3);
    if (isWindows) {
      return Scaffold(
        key: GlobalKey<ScaffoldState>(),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return const ProfileScreen();
                  },
                ));
              },
              icon: Icon(Icons.person, color: Theme.of(context).primaryColor),
            ),
            IconButton(
              onPressed: () {
                _refreshKeys[_selectedIndex].currentState?.refresh();
              },
              icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
            ),
            IconButton(
              onPressed: () {
                _showHotkeyDialog(context);
              },
              icon: Icon(Icons.keyboard, color: Theme.of(context).primaryColor),
              tooltip: 'View Keyboard Shortcuts',
            ),
          ],
          // title: Text('Accounts book'),
        ),
        body: Row(
          children: [
            AppDrawer(
              onToggleExpanded: _toggleDrawer,
              isExpanded: _isDrawerExpanded,
              onSaleAdded: () {
                Provider.of<DashboardProvider>(context, listen: false)
                    .refreshData();
              },
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              selectedIndex: _selectedIndex,
            ),
            Expanded(
              child: _widgetOptions[_selectedIndex],
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const ProfileScreen();
                    },
                  ),
                );
              },
              icon: Icon(Icons.person, color: Theme.of(context).primaryColor),
            ),
            IconButton(
              onPressed: () {
                _refreshKeys[_selectedIndex].currentState?.refresh();
              },
              icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
            ),
          ],
          title: Text(
            _selectedIndex == 0
                ? 'Accounts book'
                : (_selectedIndex == 1 ? 'Parties' : 'Items'),
          ),
        ),
        body: SizedBox.expand(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            physics: Platform.isWindows
                ? const ClampingScrollPhysics()
                : const BouncingScrollPhysics(),
            children: mobileWidgetOptions,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              activeIcon: Icon(Icons.group),
              label: 'Parties',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              activeIcon: Icon(Icons.inventory),
              label: 'Items',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: ListData().darkorWhite(context),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          backgroundColor: ListData().whiteOrDark(context),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          iconSize: 26,
        ),
      );
    }
  }

  void _showHotkeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keyboard Shortcuts'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                HotkeyRow(
                    keys: ['Ctrl+Shift+C', 'F9'],
                    description: 'Create Purchase'),
                HotkeyRow(
                    keys: ['Ctrl+Shift+S', 'F8'], description: 'Create Sale'),
                HotkeyRow(keys: ['P'], description: 'Profit & Loss Screen'),
                HotkeyRow(keys: ['B'], description: 'Balance Sheet Screen'),
                HotkeyRow(keys: ['I'], description: 'Inventory'),
                HotkeyRow(keys: ['F6'], description: 'YHome Screen'),
                HotkeyRow(keys: ['Esc'], description: 'Go Back'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
