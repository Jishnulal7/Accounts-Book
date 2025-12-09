import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/items/exports.dart';

class ItemDetails extends StatefulWidget {
  const ItemDetails({
    super.key,
    required this.itemId,
    required this.itemName,
  });

  final String itemId;
  final String itemName;

  @override
  ItemDetailsState createState() => ItemDetailsState();
}

class ItemDetailsState extends State<ItemDetails> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().fetchItemDetails(widget.itemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        final item = itemProvider.item;
        final isWideScreen = MediaQuery.of(context).size.width > 900;
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: Text(
              'Item Details',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            actions: [
              _buildActionButton(
                icon: Icons.picture_as_pdf,
                label: 'Export',
                onTap: () => _navigateToPDF(context, item, itemProvider),
              ),
              _buildActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () => _navigateToEdit(context, item, itemProvider),
              ),
              _buildActionButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                onTap: () => _showDeleteDialog(context, itemProvider, item),
                isDestructive: true,
              ),
            ],
          ),
          body: itemProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : isWideScreen
                  ? _buildWideScreenLayout(
                      context, item, itemProvider, currencySymbol)
                  : _buildMobileLayout(context, item, currencySymbol),
          floatingActionButton: SpeedDial(
            onPress: () => _navigateToAdjustStock(context, item, itemProvider),
            backgroundColor: Theme.of(context).primaryColor,
            label: Text(
              'Adjust Stock',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideScreenLayout(BuildContext context, ItemModel item,
      ItemProvider itemProvider, String currencySymbol) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel with item details
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(context, item),
                const SizedBox(height: 16),
                _buildStatusBar(context, item),
                const SizedBox(height: 16),
                _buildMetricsGrid(context, item, currencySymbol),
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
                tabTitles: const ['Timeline', 'Details'],
                tabViews: [
                  ItemTransactions(
                    itemId: widget.itemId,
                    itemName: widget.itemName,
                  ),
                  ItemTimeline(
                    itemId: widget.itemId,
                    itemName: widget.itemName,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, ItemModel item, String currencySymbol) {
    return Column(
      children: [
        Column(
          children: [
            _buildHeader(context, item),
            _buildStatusBar(context, item),
            _buildMetricsGrid(context, item, currencySymbol),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomTabBar(
              tabTitles: const ['Timeline', 'Details'],
              tabViews: [
                ItemTransactions(
                  itemId: widget.itemId,
                  itemName: widget.itemName,
                ),
                ItemTimeline(
                  itemId: widget.itemId,
                  itemName: widget.itemName,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ItemModel item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.itemName ?? '--',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              item.subCategory ?? '--',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, ItemModel item) {
    final stockStatus = _getStockStatus(item);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12), // Reduced from 16
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12), // Reduced from 20,16
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10), // Reduced from 12
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8, // Reduced from 10
            offset: const Offset(0, 3), // Reduced from 4
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatusIndicator(stockStatus),
          const SizedBox(width: 12), // Reduced from 16
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stockStatus,
                  style: const TextStyle(
                    fontSize: 16, // Reduced from 18
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${item.stockQuantity?.toStringAsFixed(1) ?? '0.0'} ${item.unit ?? ''} available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13, // Reduced from 14
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4), // Reduced from 12,6
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16), // Reduced from 20
            ),
            child: Text(
              item.itemType.toString(),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12, // Reduced from 13
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
      BuildContext context, ItemModel item, String currencySymbol) {
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
          title: 'Unit Price',
          value: '$currencySymbol ${item.amount?.toStringAsFixed(2) ?? '0.00'}',
          subtitle: 'per ${item.unit ?? 'unit'}',
          icon: Icons.paid_outlined,
          color: Colors.blue,
        ),
        _buildMetricCard(
          context,
          title: 'Stock Value',
          value:
              '$currencySymbol ${(calculateStockValue(item))?.toStringAsFixed(2) ?? '0.00'}',
          subtitle: 'Total inventory value',
          icon: Icons.assessment_outlined,
          color: Colors.green,
        ),
        _buildMetricCard(
          context,
          title: 'Low Stock Alert',
          value: '${item.lowStockQuantity ?? 0} ${item.unit ?? ''}',
          subtitle: 'Minimum threshold',
          icon: Icons.warning_amber_outlined,
          color: Colors.orange,
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
      padding: const EdgeInsets.all(10), // Reduced padding
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
        mainAxisAlignment:
            MainAxisAlignment.center, // Center content vertically
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14), // Reduced icon size
              const SizedBox(width: 4), // Reduced spacing
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
          const SizedBox(height: 2), // Minimal spacing
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

  Widget _buildStatusIndicator(String status) {
    final color = _getStockStatusColor(status);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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

  String _getStockStatus(ItemModel item) {
    final stockQty = item.stockQuantity ?? 0;
    final lowStockQty = item.lowStockQuantity ?? 0;

    if (stockQty < 0) return 'Negative Stock'; // New case for negative stock
    if (stockQty <= 0) return 'Out of Stock';
    if (stockQty <= lowStockQty) return 'Low Stock';
    return 'In Stock';
  }

  Color _getStockStatusColor(String status) {
    switch (status) {
      case 'Negative Stock':
        return Colors.red[800]!; // Darker red for negative stock
      case 'Out of Stock':
        return Colors.red;
      case 'Low Stock':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  double? calculateStockValue(ItemModel item) {
    if (item.amount != null && item.stockQuantity != null) {
      return item.amount! * item.stockQuantity!.toDouble();
    }
    return null;
  }

  // Navigation and Dialog Methods
  void _navigateToEdit(
      BuildContext context, ItemModel item, ItemProvider itemProvider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditItem(itemId: item.id!),
      ),
    );
    if (result == true) {
      itemProvider.fetchItemDetails(widget.itemId);
      if (!context.mounted) return;
      Navigator.pop(context, true);
    }
  }

  void _navigateToAdjustStock(
      BuildContext context, ItemModel item, ItemProvider itemProvider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdjustStock(item: item),
      ),
    );
    if (result == true) {
      if (!context.mounted) return;
      itemProvider.fetchItemDetails(widget.itemId);
      Navigator.pop(context, true);
    }
  }

  void _navigateToPDF(
      BuildContext context, ItemModel item, ItemProvider itemProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemStatementPDF(
          itemId: item.id!,
          item: item,
          transactions: itemProvider.allTransactions,
        ),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, ItemProvider itemProvider, ItemModel item) async {
    // First check if deletion is allowed
    bool hasTransactions = await itemProvider.hasTransactions(item.id!);

    if (hasTransactions) {
      // Show warning dialog that item cannot be deleted
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete Item'),
          content: const Text(
            'This item cannot be deleted because it has associated sale or purchase transactions. '
            'Deleting it would affect the integrity of your transaction records.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Original delete confirmation dialog
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        cancelButtonText: 'Cancel',
        confirmButtonText: 'Delete',
        content: 'Are you sure you want to delete this Item?',
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          bool success = await itemProvider.deleteItem(item.id!);
          Navigator.pop(context);
          if (success) {
            Navigator.pop(context, true);
          }
        },
        title: 'Delete Item',
      ),
    );
  }
}
