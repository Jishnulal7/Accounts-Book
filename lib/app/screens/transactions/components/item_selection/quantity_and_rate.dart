import 'package:account_book/app/screens/transactions/export.dart';

class QuantityAndUnitFields extends StatefulWidget {
  const QuantityAndUnitFields({super.key});

  @override
  State<QuantityAndUnitFields> createState() => _QuantityAndUnitFieldsState();
}

class _QuantityAndUnitFieldsState extends State<QuantityAndUnitFields> {
  late List<String> _unitList = [];

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final prefs = await SharedPreferences.getInstance();
    final customUnits = prefs.getStringList('custom_units') ?? [];

    setState(() {
      _unitList = List.from(ListData().unitData)..addAll(customUnits);
    });
  }

  Future<void> _saveUnits() async {
    final prefs = await SharedPreferences.getInstance();
    final customUnits =
        _unitList.where((unit) => !ListData().unitData.contains(unit)).toList();
    await prefs.setStringList('custom_units', customUnits);
  }

  void _showAddUnitBottomSheet(BuildContext context) {
    final TextEditingController newUnitController = TextEditingController();
    final TextEditingController shortUnitController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) => AddUnitDialog(
        newUnitController: newUnitController,
        shortUnitController: shortUnitController,
        onSave: () {
          _handleNewUnit(
              context, newUnitController.text, shortUnitController.text);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _handleNewUnit(BuildContext context, String newUnit, String shortForm) {
    if (newUnit.isNotEmpty && shortForm.isNotEmpty) {
      final itemProvider =
          Provider.of<ItemSelectionProvider>(context, listen: false);

      String newUnitEntry = '$newUnit ($shortForm)';

      if (!_unitList.contains(newUnitEntry)) {
        setState(() {
          _unitList.insert(2, newUnitEntry);
        });

        // Update the unitDataMap in ListData
        ListData().unitDataMap[newUnit] = shortForm;

        // Set the newly added unit as the selected unit
        itemProvider.setUnit(newUnitEntry);

        // Save the updated unit list
        _saveUnits();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unit "$newUnitEntry" already exists!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemSelectionProvider>(context);
    double width = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            controller: provider.quantityController,
            labelText: 'Quantity',
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a quantity';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: provider.selectedUnit,
            onChanged: provider.isItemSelected
                ? null
                : (newValue) {
                    if (newValue == 'Add Unit') {
                      _showAddUnitBottomSheet(context);
                    } else {
                      provider.setUnit(newValue!);
                    }
                  },
            items: _unitList.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(fontSize: width < 500 ? 12 : 14),
                ),
              );
            }).toList(),
            decoration: const InputDecoration(
              labelText: 'Unit',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a unit';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
