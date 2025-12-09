import 'package:account_book/app/screens/items/exports.dart';

class AddUnitDialog extends StatelessWidget {
  final TextEditingController newUnitController;
  final TextEditingController shortUnitController;
  final VoidCallback onSave;

  const AddUnitDialog({
    super.key,
    required this.newUnitController,
    required this.shortUnitController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add a Unit'),
          CustomTextFieldNoBorder(
            controller: newUnitController,
            labelText: 'Unit Name',
            hintText: 'Enter unit name',
          ),
          const SizedBox(height: 10),
          CustomTextFieldNoBorder(
            controller: shortUnitController,
            labelText: 'Short Form',
            hintText: 'Enter short form',
            maxLength: 3,
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: onSave,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
