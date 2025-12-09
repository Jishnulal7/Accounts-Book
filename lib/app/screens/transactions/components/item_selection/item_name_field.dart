import 'package:account_book/app/screens/transactions/export.dart';

class ItemNameField extends StatelessWidget {
  const ItemNameField({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemSelectionProvider>(context);
    return CustomTextField(
      controller: provider.nameController,
      labelText: 'Item Name',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an item name';
        }
        return null;
      },
      onChanged: (value) {
        provider.filterItems(value);
      },
    );
  }
}
