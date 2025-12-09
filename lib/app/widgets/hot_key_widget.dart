import 'package:account_book/app/screens/home/exports.dart';

class HotkeyRow extends StatelessWidget {
  final List<String> keys;
  final String description;

  const HotkeyRow({
    super.key,
    required this.keys,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      // color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 7,
            child: Text(description),
          ),
        ],
      ),
    );
  }
}
