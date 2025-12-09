import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddCategoryBottomSheet extends StatefulWidget {
  final String? initialName;
  final List<Map<String, Object>>? initialSubcategories;
  final VoidCallback? onNameAdded;

  const AddCategoryBottomSheet({
    super.key,
    this.initialName,
    this.initialSubcategories,
    this.onNameAdded,
  });

  @override
  AddCategoryBottomSheetState createState() => AddCategoryBottomSheetState();
}

class AddCategoryBottomSheetState extends State<AddCategoryBottomSheet> {
  late List<Map<String, Object>> _subcategories;

  late TextEditingController _nameController;
  final TextEditingController subNameController = TextEditingController();
  final TextEditingController subInitialBalanceController =
      TextEditingController();
  final TextEditingController subWageController = TextEditingController();
  final TextEditingController positionController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _subcategories =
        List<Map<String, Object>>.from(widget.initialSubcategories ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    positionController.dispose();
    subWageController.dispose();
    subNameController.dispose();
    subInitialBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initialName == null ? 'Add Category' : 'Edit Category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColor.kPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Subcategories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (_subcategories.isEmpty)
              const Text(
                'No subcategories added yet',
                style: TextStyle(fontStyle: FontStyle.italic),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subcategories.length,
                itemBuilder: (context, index) {
                  final sub = _subcategories[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(sub['name'] as String),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Opening Balance: $currencySymbol${sub['initialBalance']}'),
                          Text('Wage: $currencySymbol${sub['wage']}'),
                          Text('Position: ${sub['position']}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _subcategories.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _showAddSubcategoryDialog,
              child: const Text('Add Subcategory'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  child: const Text('Save'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onNameAdded?.call();
                      Navigator.of(context).pop({
                        'name': _nameController.text,
                        'subcategories': _subcategories,
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubcategoryDialog() {
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Subcategory'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: subNameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: subInitialBalanceController,
                    decoration:
                        const InputDecoration(labelText: 'Opening Balance'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  TextFormField(
                    controller: subWageController,
                    decoration: const InputDecoration(labelText: 'Wage'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a wage';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: positionController,
                    decoration: const InputDecoration(labelText: 'Position'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    _subcategories.add({
                      'name': subNameController.text,
                      'initialBalance':
                          double.tryParse(subInitialBalanceController.text) ??
                              0.0,
                      'wage': double.tryParse(subWageController.text) ?? 0.0,
                      'position': positionController.text,
                    });
                  });
                  subNameController.clear();
                  subInitialBalanceController.clear();
                  subWageController.clear();
                  positionController.clear();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
