import 'package:account_book/app/data/helpers/quick_link.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/home/exports.dart';
import 'package:account_book/app/screens/transactions/sales/sale_order.dart';

class QuickLinksCard extends StatefulWidget {
  final VoidCallback onSaleAdded;

  const QuickLinksCard({
    super.key,
    required this.onSaleAdded,
  });

  @override
  State<QuickLinksCard> createState() => _QuickLinksCardState();
}

class _QuickLinksCardState extends State<QuickLinksCard> {
  bool _showAllLinks = false;

  Color _getCardColor(BuildContext context, MaterialColor baseColor) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? baseColor.shade700.withOpacity(0.2)
        : baseColor.shade50;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWindows = Platform.isWindows;
    final padding = isWindows ? 20.0 : 16.0;
    double width = MediaQuery.of(context).size.width;
    return Card(
      elevation: isWindows ? 4 : 0,
      color: isDark ? Colors.black12 : Colors.white,
      margin: EdgeInsets.all(isWindows ? 8 : 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Links',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Frequently used actions',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isWindows)
                  IconButton.filledTonal(
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () {
                      setState(() {
                        _showAllLinks = !_showAllLinks;
                      });
                    },
                    icon: Icon(
                        _showAllLinks ? Icons.expand_less : Icons.more_horiz,
                        size: width < 350 ? 16 : 24),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildQuickLinkGrid(context),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget destination,
      {TransactionType? transactionType}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => destination,
      settings: RouteSettings(arguments: transactionType),
    ));
  }

  Widget _buildQuickLinkGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600 && screenWidth < 1200;
    // final isLargeScreen = screenWidth >= 1200;
    bool isWindows = Platform.isWindows;
    int crossAxisCount;

    if (isWindows) {
      crossAxisCount = screenWidth < 650 ? 3 : 5;
    } else if (isTablet) {
      crossAxisCount = screenWidth < 650 ? 3 : 4;
    } else if (screenWidth < 360) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }

    // Adjust aspect ratio based on screen size
    double childAspectRatio;
    if (screenWidth < 400) {
      childAspectRatio = 1.1; // More square for very small screens
    } else if (screenWidth < 650) {
      childAspectRatio = 1.2; // More square for small screens
    } else if (isWindows || isTablet) {
      childAspectRatio = 1.6; // Wider than tall for larger screens
    } else {
      childAspectRatio = 1.4; // Default
    }

    final allItems = [
      QuickLinkData(
        icon: Icons.receipt_outlined,
        label: 'Sale',
        color: _getCardColor(context, Colors.green),
        onTap: () => _navigateTo(
          context,
          CreateSale(onItemAdded: widget.onSaleAdded),
        ),
      ),
      QuickLinkData(
        icon: Icons.shopping_cart_outlined,
        label: 'Purchase',
        color: _getCardColor(context, Colors.blue),
        onTap: () => _navigateTo(
          context,
          CreatePurchase(onItemAdded: widget.onSaleAdded),
        ),
      ),
      QuickLinkData(
        icon: Icons.calculate_outlined,
        label: 'Quotation',
        color: _getCardColor(context, Colors.green),
        onTap: () => _navigateTo(
          context,
          Estimate(onItemAdded: widget.onSaleAdded),
        ),
      ),
      QuickLinkData(
        icon: Icons.receipt_long_outlined,
        label: 'Sale Order',
        color: _getCardColor(context, Colors.blue),
        onTap: () => _navigateTo(
          context,
          SaleOrder(onItemAdded: widget.onSaleAdded),
        ),
      ),
      QuickLinkData(
        icon: Icons.article_outlined,
        label: 'Purchase Order',
        color: _getCardColor(context, Colors.green),
        onTap: () => _navigateTo(context, const PurchaseOrder()),
      ),
      QuickLinkData(
        icon: Icons.local_shipping_outlined,
        label: 'Delivery Challan',
        color: _getCardColor(context, Colors.blue),
        onTap: () => _navigateTo(
          context,
          DeliveryChallan(onItemAdded: widget.onSaleAdded),
        ),
      ),
      QuickLinkData(
        icon: Icons.assignment_return_outlined,
        label: 'Purchase Return',
        color: _getCardColor(context, Colors.green),
        onTap: () => _navigateTo(context, const PurchaseReturn()),
      ),
      QuickLinkData(
        icon: Icons.assignment_return_outlined,
        label: 'Sales Return',
        color: _getCardColor(context, Colors.blue),
        onTap: () => _navigateTo(context, const SalesReturn()),
      ),
      QuickLinkData(
        icon: Icons.assignment_return_outlined,
        label: 'Proforma',
        color: _getCardColor(context, Colors.green),
        onTap: () => _navigateTo(context, const ProformaInvoice()),
      ),
      QuickLinkData(
        icon: Icons.currency_rupee_outlined,
        label: 'Receipt',
        color: _getCardColor(context, Colors.blue),
        onTap: () => _navigateTo(context, const YarimaWalletHome(),
            transactionType: TransactionType.receipt),
      ),
      QuickLinkData(
        icon: Icons.payments_outlined,
        label: 'Payment',
        color: _getCardColor(context, Colors.green),
        onTap: () => _navigateTo(context, const YarimaWalletHome(),
            transactionType: TransactionType.payment),
      ),
    ];

    // For Windows, always show all items
    final items = isWindows
        ? allItems
        : (_showAllLinks ? allItems : allItems.sublist(0, 3));

    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _QuickLinkButton(
                icon: item.icon,
                label: item.label,
                color: item.color,
                onTap: item.onTap,
              );
            },
          );
        },
      ),
    );
  }
}

class _QuickLinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickLinkButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 300;
    final isLargeScreen = screenWidth >= 1200;

    final containerPadding = isLargeScreen
        ? 6.0
        : isSmallScreen
            ? 3.0 // Even smaller padding
            : 5.0;

    final iconSize = isLargeScreen
        ? 30.0
        : isSmallScreen
            ? 16.0 // Smaller icon for small screens
            : 20.0;

    final iconPadding = isLargeScreen
        ? 4.0
        : isSmallScreen
            ? 2.0 // Reduce padding for small screens
            : 4.0;

    // Make text even smaller on very small screens
    final fontSize = isVerySmallScreen
        ? 9.0
        : isSmallScreen
            ? 10.0
            : isLargeScreen
                ? 15.0
                : 11.0;

    return Card(
      elevation: 2,
      color: color,
      margin: EdgeInsets.all(isSmallScreen ? 1 : 2), // Smaller margins
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(containerPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: isSmallScreen ? 1 : 3),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: fontSize,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
