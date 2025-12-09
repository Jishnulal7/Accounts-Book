import 'package:account_book/app/screens/transactions/export.dart';

class ItemSelection extends StatelessWidget {
  final String partyName;
  final List<ItemSelectionModel> selectedItems;
  final VoidCallback? onItemCreated;

  const ItemSelection({
    super.key,
    required this.partyName,
    required this.selectedItems,
    this.onItemCreated,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ItemSelectionProvider(
        partyName: partyName,
        selectedItems: selectedItems,
      ),
      child: ItemSelectionContent(
        onItemCreated: onItemCreated,
      ),
    );
  }
}

class ItemSelectionContent extends StatelessWidget {
  const ItemSelectionContent({super.key, this.onItemCreated});
  final VoidCallback? onItemCreated;
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemSelectionProvider>(context);
    // final refreshData = provider.refreshData();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Selection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView(
              children: [
                const ItemNameField(),
                const SizedBox(height: 10),
                if (provider.isListViewVisible)
                  ItemListView(onItemCreated: onItemCreated),
                const SizedBox(height: 10),
                if (provider.isTextFieldFocused) ...[
                  const QuantityAndUnitFields(),
                  const SizedBox(height: 10),
                  const RateAndTaxFields(),
                  const SizedBox(height: 10),
                  const DiscountRow(),
                  const SizedBox(height: 10),
                  if (provider.isItemSelected)
                    const Card(child: TotalsAndTaxesSection()),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavButtons(
        onSave: () => _navigateToSalesPage(context),
        onSaveAndNew: () => _navigateToAddItemAgain(context),
        saveText: 'Save & New',
      ),
    );
  }

  void _navigateToSalesPage(BuildContext context) async {
    final provider = Provider.of<ItemSelectionProvider>(context, listen: false);
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    // Validate if an item is selected or created
    if (!provider.isItemSelected && provider.nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create an item first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await provider.createNewItem(context, itemProvider);
    provider.addItemToSelection();

    // Make sure to refresh the items list globally
    if (context.mounted) {
      // This ensures the item provider is updated globally
      await Provider.of<ItemProvider>(context, listen: false).fetchItems();
      Navigator.pop(context, provider.selectedItems);
    }
  }

  void _navigateToAddItemAgain(BuildContext context) async {
    final provider = Provider.of<ItemSelectionProvider>(context, listen: false);
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    // Validate if an item is selected or created
    if (!provider.isItemSelected && provider.nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create an item first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await provider.createNewItem(context, itemProvider);
    provider.addItemToSelection();

    // Make sure to refresh the items list globally
    if (context.mounted) {
      // This ensures the item provider is updated globally
      await Provider.of<ItemProvider>(context, listen: false).fetchItems();
    }
    provider.resetForm();
  }
}

class ItemSelectionDialog extends StatelessWidget {
  final String partyName;
  final List<ItemSelectionModel> selectedItems;
  final VoidCallback? onItemCreated;

  const ItemSelectionDialog({
    super.key,
    required this.partyName,
    required this.selectedItems,
    this.onItemCreated,
  });

  static Future<List<ItemSelectionModel>?> show(
    BuildContext context, {
    required String partyName,
    required List<ItemSelectionModel> selectedItems,
    VoidCallback? onItemCreated,
  }) {
    return showDialog<List<ItemSelectionModel>>(
      context: context,
      builder: (context) => ItemSelectionDialog(
        partyName: partyName,
        selectedItems: selectedItems,
        onItemCreated: onItemCreated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ItemSelectionProvider(
        partyName: partyName,
        selectedItems: selectedItems, 
      ),
      child: ItemSelectionDialogContent(
        onItemCreated: onItemCreated,
      ),
    );
  }
}

class ItemSelectionDialogContent extends StatelessWidget {
  const ItemSelectionDialogContent({super.key, this.onItemCreated});
  final VoidCallback? onItemCreated;
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemSelectionProvider>(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final orientation = mediaQuery.orientation;

    // Calculate dialog dimensions
    double calculateDialogWidth() {
      if (screenWidth > 1200) return screenWidth * 0.5;
      if (screenWidth > 600) return screenWidth * 0.75;
      return screenWidth * 0.95;
    }

    double calculateDialogHeight() {
      if (orientation == Orientation.landscape) {
        return screenHeight * 0.8;
      }
      return screenHeight * 0.6;
    }

    return AlertDialog(
      title: const Text('Item Selection'),
      content: SizedBox(
        width: calculateDialogWidth(),
        height: calculateDialogHeight(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ItemNameField(),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (provider.isListViewVisible)
                      ItemListView(onItemCreated: onItemCreated),
                    if (provider.isTextFieldFocused) ...[
                      const QuantityAndUnitFields(),
                      const SizedBox(height: 8),
                      const RateAndTaxFields(),
                      const SizedBox(height: 8),
                      const DiscountRow(),
                      const SizedBox(height: 8),
                      if (provider.isItemSelected)
                        const Card(child: TotalsAndTaxesSection()),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _navigateToSalesPage(context),
          child: const Text('Save'),
        ),
        TextButton(
          onPressed: () => _navigateToAddItemAgain(context),
          child: const Text('Save & New'),
        ),
      ],
    );
  }

  void _navigateToSalesPage(BuildContext context) async {
    final provider = Provider.of<ItemSelectionProvider>(context, listen: false);
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    // Validate if an item is selected or created
    if (!provider.isItemSelected && provider.nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create an item first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await provider.createNewItem(context, itemProvider);
    provider.addItemToSelection();

    // Make sure to refresh the items list globally
    if (context.mounted) {
      // This ensures the item provider is updated globally
      await Provider.of<ItemProvider>(context, listen: false).fetchItems();
      Navigator.pop(context, provider.selectedItems);
    }
  }

  void _navigateToAddItemAgain(BuildContext context) async {
    final provider = Provider.of<ItemSelectionProvider>(context, listen: false);
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    // Validate if an item is selected or created
    if (!provider.isItemSelected && provider.nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create an item first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await provider.createNewItem(context, itemProvider);
    provider.addItemToSelection();

    // Make sure to refresh the items list globally
    if (context.mounted) {
      // This ensures the item provider is updated globally
      await Provider.of<ItemProvider>(context, listen: false).fetchItems();
    }
    provider.resetForm();
  }
}
