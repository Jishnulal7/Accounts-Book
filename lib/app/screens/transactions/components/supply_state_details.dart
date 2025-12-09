import 'package:account_book/app/screens/transactions/export.dart';

class SupplyStateDetails extends StatelessWidget {
  final ValueChanged<String?> onStateChange;
  final String stateOfSupply;

  const SupplyStateDetails({
    super.key,
    required this.onStateChange,
    required this.stateOfSupply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'State of Supply',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          DropdownButton<String>(
            focusColor: Colors.transparent,
            hint: const Text('Select State'),
            value: stateOfSupply,
            onChanged: onStateChange,
            items:
                ListData().states.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
