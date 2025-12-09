import 'package:flutter/material.dart';

class CountryDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> countries;
  final String? selectedCountry;
  final Function(String?) onCountryChanged;
  final String labelText;
  final Widget? prefixIcon;

  const CountryDropdown({
    super.key,
    required this.countries,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.labelText = 'Country',
    this.prefixIcon,
  });

  @override
  State<CountryDropdown> createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  late List<Map<String, dynamic>> _filteredCountries;
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _filteredCountries = List.from(widget.countries);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isDropdownOpen) {
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _searchFocusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = List.from(widget.countries);
      } else {
        _filteredCountries = widget.countries
            .where((country) => country['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });

    // Update overlay without rebuilding it to maintain focus
    if (_isDropdownOpen) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _showOverlay() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 300,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  // Search field inside dropdown
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search Country',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _filterCountries,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                    ),
                  ),

                  // Divider
                  const Divider(height: 1),

                  // List of countries
                  Flexible(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        return ListTile(
                          dense: true,
                          title: Text(country['name']),
                          onTap: () {
                            widget.onCountryChanged(country['name']);
                            _searchController.clear();
                            _filterCountries('');
                            _hideOverlay();
                          },
                          selected: country['name'] == widget.selectedCountry,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isDropdownOpen = true;
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isDropdownOpen = false;
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _hideOverlay();
    } else {
      _showOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Focus(
          focusNode: _focusNode,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: widget.labelText,
                prefixIcon: widget.prefixIcon,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                widget.selectedCountry ?? 'Select Country',
                style: widget.selectedCountry == null
                    ? TextStyle(color: Colors.grey.shade600)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
