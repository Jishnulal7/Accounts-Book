import 'package:account_book/app/screens/transactions/export.dart';

class ItemListView extends StatelessWidget {
  const ItemListView({super.key, this.onItemCreated});
  final VoidCallback? onItemCreated;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemSelectionProvider>(context);
    return FutureBuilder<List<ItemModel>>(
      future: provider.filterItems(provider.nameController.text),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Text('Error loading items');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
              alignment: Alignment.topCenter,
              child: _buildNoItemsAvailable(context, provider));
        } else {
          return _buildItemList(snapshot.data!, provider);
        }
      },
    );
  }

  Widget _buildNoItemsAvailable(
      BuildContext context, ItemSelectionProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('No items available'),
          TextButton(
            onPressed: () {
              // Create a new controller with the current text
              final newNameController = TextEditingController(
                text: provider.nameController.text,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateItem(
                    nameController: newNameController,
                    onItemCreated: () {
                      // Dispose of the new controller after use
                      newNameController.dispose();

                      // Call the original onItemCreated callback if provided
                      onItemCreated?.call();
                    },
                  ),
                ),
              );
            },
            child: const Text('Add an Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(List<ItemModel> items, ItemSelectionProvider provider) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected =
            provider.selectedItems.any((selected) => selected.id == item.id);

        return InkWell(
          onTap: () => provider.selectItem(item),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Item icon/avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.stockQuantity} ${_formatUnit(item.unit)}',
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to format unit
  String _formatUnit(String? unit) {
    if (unit != null && unit.contains('(') && unit.contains(')')) {
      return unit.substring(unit.indexOf('(') + 1, unit.indexOf(')'));
    }
    return unit ?? '';
  }
}
