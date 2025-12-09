import 'package:account_book/app/screens/items/exports.dart';

class ItemTimeline extends StatelessWidget {
  final String itemId;
  final String itemName;

  const ItemTimeline({
    super.key,
    required this.itemId,
    required this.itemName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, _) {
        final item = itemProvider.item;

        if (item.id != itemId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            itemProvider.fetchItemDetails(itemId);
          });
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Define responsive layout breakpoints
            final isSmallScreen = constraints.maxWidth < 600;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isSmallScreen
                        ? Column(
                            children: [
                              _buildStockStatusCard(context, item),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildStockStatusCard(context, item),
                              ),
                            ],
                          ),

                    const SizedBox(height: 16),

                    // Details section with responsive grid layout
                    _buildDetailsSection(context, item, isSmallScreen),

                    if (item.itemDescription?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      _buildDescriptionCard(
                          context, item.itemDescription ?? '--'),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStockStatusCard(BuildContext context, ItemModel item) {
    final status = _getStockStatus(item);
    final color = _getStatusColor(status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Stock',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.stockQuantity ?? 0} ${item.unit ?? 'units'}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStockInfoItem(
                  context,
                  'Status',
                  status,
                  color,
                ),
                _buildStockInfoItem(
                  context,
                  'Alert At',
                  '${item.lowStockQuantity ?? 0} ${item.unit ?? 'units'}',
                  Colors.grey[700]!,
                ),
              ],
            ),

            // Stock level indicator
            const SizedBox(height: 16),
            Text(
              'Stock Level',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            _buildStockLevelIndicator(context, item),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfoItem(
      BuildContext context, String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildStockLevelIndicator(BuildContext context, ItemModel item) {
    final stockQty = item.stockQuantity ?? 0;
    final lowStockQty = item.lowStockQuantity ?? 0;

    // Determine stock status and color
    final status = _getStockStatus(item);
    final color = _getStatusColor(status);

    // Calculate percentage with special handling for negative stocks
    double percentage;
    Color progressColor;

    if (stockQty >= 0) {
      // Positive stock scenario
      if (lowStockQty == 0) {
        // If no low stock threshold is set, use a default scaling
        percentage = stockQty > 100 ? 1.0 : stockQty / 100;
      } else {
        // Scale the progress relative to the low stock threshold
        final maxValue = lowStockQty * 3;
        percentage = (stockQty / (maxValue > 0 ? maxValue : 1)).clamp(0.0, 1.0);
      }
      progressColor = color;
    } else {
      // Negative stock scenario
      percentage = 1.0; // Full width to highlight negative stock
      progressColor = Colors.deepPurple; // Distinct color for negative stock
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            // Background track
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Foreground progress
            Container(
              height: 10,
              width: percentage * MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current: $stockQty ${item.unit ?? 'units'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: stockQty < 0 ? Colors.deepPurple : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              'Alert Level: $lowStockQty ${item.unit ?? 'units'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  // Update _getStockStatus to handle negative stocks
  String _getStockStatus(ItemModel item) {
    final stockQty = item.stockQuantity ?? 0;
    final lowStockQty = item.lowStockQuantity ?? 0;

    if (stockQty < 0) {
      return 'Negative Stock';
    } else if (stockQty <= 0) {
      return 'Out of Stock';
    } else if (stockQty <= lowStockQty) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }

  // Update _getStatusColor to include color for negative stock
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Negative Stock':
        return Colors.deepPurple;
      case 'Out of Stock':
        return Colors.red;
      case 'Low Stock':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  // Update _getStatusIcon to include icon for negative stock
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Negative Stock':
        return Icons.error_outline;
      case 'Out of Stock':
        return Icons.inventory_2_outlined;
      case 'Low Stock':
        return Icons.warning_amber_rounded;
      default:
        return Icons.check_circle_outline;
    }
  }

  Widget _buildDetailsSection(
      BuildContext context, ItemModel item, bool isSmallScreen) {
    final details = [
      {'Category': item.itemCategory ?? '--'},
      {'Unit': item.unit ?? '--'},
      {'Type': item.itemType ?? '--'},
      {'HSN Code': item.hsn ?? '--'},
      {'GST Rate': _formatTaxRate(item.gst)},
      {'Sub Category': item.subCategory ?? '--'},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            isSmallScreen
                ? _buildVerticalDetails(context, details)
                : _buildGridDetails(context, details),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDetails(
      BuildContext context, List<Map<String, String>> details) {
    return Column(
      children: details.asMap().entries.map((entry) {
        final item = entry.value;
        final isLast = entry.key == details.length - 1;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.keys.first,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  Text(
                    item.values.first,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                color: Colors.grey[200],
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildGridDetails(
      BuildContext context, List<Map<String, String>> details) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: details.length,
      itemBuilder: (context, index) {
        final item = details[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.keys.first,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.values.first,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescriptionCard(BuildContext context, String description) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTaxRate(String? gst) {
    if (gst == 'Exempted' || gst == 'None') {
      return gst ?? '--';
    }
    return '${gst?.replaceAll(RegExp(r'[^\d.]+'), '')}%';
  }
}
