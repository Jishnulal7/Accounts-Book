import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/widgets/info_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:account_book/app/providers/item_provider.dart';
import 'package:provider/provider.dart';
import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/screens/items/create_item.dart';
import 'package:account_book/app/screens/items/item_details.dart';
import 'package:account_book/app/data/model/item_model.dart';

class ItemScreen extends StatelessWidget {
  const ItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ItemProvider(),
      child: const ItemScreenContent(),
    );
  }
}

class ItemScreenContent extends StatefulWidget {
  const ItemScreenContent({super.key});

  @override
  ItemScreenContentState createState() => ItemScreenContentState();
}

class ItemScreenContentState extends State<ItemScreenContent> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh items when the screen receives focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().fetchItems();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().fetchItems();
    });
  }

  // Calculate number of grid columns based on screen width
  int _calculateColumnCount(double width) {
    if (width < 600) return 1; // Mobile
    if (width < 900) return 2; // Tablet
    if (width < 1200) return 3; // Desktop
    return 4; // Large Desktop
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory,
            color: Theme.of(context).primaryColor,
            size: 80,
          ),
          const SizedBox(height: 20),
          const Text(
            'No Items Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to create a new item',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<ItemModel> itemList, String currencySymbol) {
    return ListView.builder(
      itemCount: itemList.length,
      itemBuilder: (context, index) {
        final item = itemList[index];
        return _buildItemCard(context, item, isGrid: false, currencySymbol);
      },
    );
  }

  Widget _buildGridView(
      List<ItemModel> itemList, int columnCount, String currencySymbol) {
    // Calculate a responsive aspect ratio based on screen width
    double aspectRatio;
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      aspectRatio = 1.5;
    } else if (screenWidth < 900) {
      aspectRatio = 1.8;
    } else if (screenWidth < 1200) {
      aspectRatio = 2.0;
    } else {
      aspectRatio = 2.2;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        childAspectRatio: aspectRatio, // Using the responsive aspect ratio
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemList.length,
      itemBuilder: (context, index) {
        final item = itemList[index];
        return _buildItemCard(context, item, currencySymbol, isGrid: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      floatingActionButton: SpeedDial(
        label: const Text('Create an Item'),
        onPress: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateItem(),
            ),
          ).then((_) => context.read<ItemProvider>().fetchItems());
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<ItemProvider>(
        builder: (context, itemProvider, child) {
          if (itemProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final itemList = itemProvider.items;

          if (itemList.isEmpty) {
            return _buildEmptyState(context);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;

              // Use original list view for screens smaller than 600px
              if (isMobile) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildListView(itemList, currencySymbol),
                );
              }

              // Use grid view for larger screens
              final columnCount = _calculateColumnCount(screenWidth);
              return Padding(
                padding: const EdgeInsets.all(8),
                child: _buildGridView(itemList, columnCount, currencySymbol),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildItemCard(
      BuildContext context, ItemModel item, String currencySymbol,
      {required bool isGrid}) {
    final unitMatch = RegExp(r'\(([^)]+)\)').firstMatch(item.unit ?? '');
    final unitString = unitMatch != null ? unitMatch.group(1) ?? '' : '';
    final valueString = item.stockQuantity != null
        ? '${item.stockQuantity} $unitString'
        : 'N/A';
    final isGoods = item.itemType == 'Goods';

// Determine the color for the stock quantity
    final stockColor = (item.stockQuantity ?? 0) < 0
        ? Colors.red // Red for negative stock
        : AppColor.kGreen; // Green for positive stock

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: isGrid
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetails(
                itemId: item.id ?? '--',
                itemName: item.itemName ?? '--',
              ),
            ),
          );
          if (result == true && context.mounted) {
            context.read<ItemProvider>().fetchItems();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isGoods ? Colors.blue : Colors.orange,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.itemName ?? '--',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isGrid ? 16 : 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColor.kGrayscale40,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        item.unit ?? '--',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isGrid) const Spacer(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: InfoText(
                      title: 'Price',
                      value:
                          '$currencySymbol  ${item.amount?.toString() ?? '--'}',
                      titleStyle: TextStyle(
                        fontSize: 14,
                        color: AppColor.kGrayscale40,
                      ),
                      valueStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (item.itemType == 'Goods')
                    Expanded(
                      child: InfoText(
                        title: 'In Stock',
                        value: valueString.toString(),
                        titleStyle: TextStyle(
                          fontSize: 14,
                          color: AppColor.kGrayscale40,
                        ),
                        valueStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: stockColor, // Use the conditional color here
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
