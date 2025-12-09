import 'package:account_book/app/screens/transactions/export.dart';

// party_search_textfield.dart
class PartySearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final VoidCallback onEditingComplete;
  final bool showResultsImmediately;

  const PartySearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onEditingComplete,
    this.showResultsImmediately = true, // Changed default to true
  });

  @override
  PartySearchFieldState createState() => PartySearchFieldState();
}

class PartySearchFieldState extends State<PartySearchField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus && widget.showResultsImmediately) {
      widget.onChanged(''); // Trigger empty search to show all parties
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      focusNode: widget.focusNode,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter the party name';
        }
        return null;
      },
      onChanged: widget.onChanged,
      onTap: () {
        if (widget.showResultsImmediately && widget.controller.text.isEmpty) {
          widget.onChanged(''); // Show all parties when tapped
        }
      },
      onEditingComplete: widget.onEditingComplete,
      labelText: 'Party Name',
      hintText: 'Search/Create Party',
      controller: widget.controller,
      prefixIcon: Icon(
        Icons.person,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}
