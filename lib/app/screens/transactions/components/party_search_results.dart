import 'package:account_book/app/screens/transactions/export.dart';

class PartySearchResults extends StatelessWidget {
  final Future<List<PartyModel>> future;
  final TextEditingController controller;
  final Function(PartyModel) onSelectParty;
  final FocusNode focusNode;

  const PartySearchResults({
    super.key,
    required this.future,
    required this.controller,
    required this.onSelectParty,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<PartyModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Error loading parties',
              style: TextStyle(
                color: isDark ? Colors.red[300] : Colors.red[700],
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return NoResultsFound(controller: controller);
        } else {
          final results = snapshot.data!;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              // color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(8), 
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: PartyList(
                parties: results,
                onSelectParty: (party) {
                  onSelectParty(party);
                  focusNode.unfocus();
                },
              ),
            ),
          );
        }
      },
    );
  }
}
