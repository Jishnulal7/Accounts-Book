import 'package:flutter/material.dart';

class AddSubcategoryBottomSheet extends StatefulWidget {
  final String? initialName;
  final double? initialBalance;
  final double? wage;
  final String? position;

  const AddSubcategoryBottomSheet({
    super.key,
    this.initialName,
    this.initialBalance,
    this.wage,
    this.position,
  });

  @override
  AddSubcategoryBottomSheetState createState() =>
      AddSubcategoryBottomSheetState();
}

class AddSubcategoryBottomSheetState extends State<AddSubcategoryBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _initialBalanceController =
      TextEditingController();
  final TextEditingController _wageController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _initialBalanceController.text =
        widget.initialBalance?.toStringAsFixed(1) ?? '';
    _wageController.text = widget.wage?.toStringAsFixed(1) ?? '';
    _positionController.text = widget.position ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        spacing: 16,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initialName == null ? 'Add Subcategory' : 'Edit Subcategory',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _initialBalanceController,
            decoration: const InputDecoration(labelText: 'Opening Balance'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _wageController,
            decoration: const InputDecoration(labelText: 'Wage'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _positionController,
            decoration: const InputDecoration(labelText: 'Position'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              OutlinedButton(
                child: Text(widget.initialName == null ? 'Add' : 'Save'),
                onPressed: () {
                  Navigator.of(context).pop({
                    'name': _nameController.text,
                    'initialBalance':
                        double.tryParse(_initialBalanceController.text) ?? 0.0,
                    'wage': double.tryParse(_wageController.text) ?? 0.0,
                    'position': _positionController.text,
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
