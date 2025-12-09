import 'package:account_book/app/screens/items/exports.dart';

class HsnSearchScreen extends StatelessWidget {
  final Function(String) onSelectHsn;

  const HsnSearchScreen({super.key, required this.onSelectHsn});

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive sizes
            final double maxHeight = constraints.maxHeight;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.2,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: _HsnSearchContent(
                    onSelectHsn: onSelectHsn,
                    scrollController: scrollController,
                    maxHeight: maxHeight,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HsnSearchContent extends StatefulWidget {
  final Function(String) onSelectHsn;
  final ScrollController scrollController;
  final double maxHeight;

  const _HsnSearchContent({
    required this.onSelectHsn,
    required this.scrollController,
    required this.maxHeight,
  });

  @override
  State<_HsnSearchContent> createState() => _HsnSearchContentState();
}

class _HsnSearchContentState extends State<_HsnSearchContent> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> hsnList = [];
  List<Map<String, dynamic>> filteredList = [];

  bool isLoading = true;
  bool isFetchingMore = false;
  String? error;

  int pageSize = 50; // Number of items per page
  int currentPage = 0; // Current page index

  @override
  void initState() {
    super.initState();
    _loadHsnData();
  }

  Future<void> _loadHsnData() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/json/HSN_SAC.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      final List<dynamic> hsnArray = jsonData["HSN_MSTR"] ?? [];

      // Check if widget is still mounted before updating state
      if (mounted) {
        setState(() {
          hsnList = List<Map<String, dynamic>>.from(hsnArray);
          filteredList = hsnList.take(pageSize).toList(); // Load first page
          isLoading = false;
        });
      }
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (mounted) {
        setState(() {
          error = 'Error loading HSN data: ${e.toString()}';
          isLoading = false;
        });
      }
      debugPrint('Error loading HSN data: $e');
    }
  }

  void _loadMoreData() {
    if (isFetchingMore || !mounted) return;

    setState(() => isFetchingMore = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      // Check if widget is still mounted before proceeding
      if (!mounted) return;
      
      final nextPageStart = (currentPage + 1) * pageSize;
      final searchQuery = searchController.text.trim().toLowerCase();

      List<Map<String, dynamic>> newItems;

      if (searchQuery.isEmpty) {
        newItems = hsnList.skip(nextPageStart).take(pageSize).toList();
      } else {
        // For filtered results, we need to get the next page of filtered items
        final searchResults = hsnList.where((hsn) {
          final hsnCode = hsn["HSN_CD"]?.toString().toLowerCase() ?? '';
          final description =
              hsn["HSN_Description"]?.toString().toLowerCase() ?? '';
          return hsnCode.contains(searchQuery) ||
              description.contains(searchQuery);
        }).toList();

        newItems = searchResults.skip(nextPageStart).take(pageSize).toList();
      }

      // Check if widget is still mounted before updating state
      if (mounted) {
        setState(() {
          if (newItems.isNotEmpty) {
            filteredList.addAll(newItems);
            currentPage++;
          }
          isFetchingMore = false;
        });
      }
    });
  }

  void _filterList(String query) {
    if (!mounted) return;
    
    if (query.isEmpty) {
      setState(() {
        filteredList = hsnList.take(pageSize).toList(); // Reset to first page
        currentPage = 0;
      });
      return;
    }

    final searchLower = query.toLowerCase();
    final searchResults = hsnList.where((hsn) {
      final hsnCode = hsn["HSN_CD"]?.toString().toLowerCase() ?? '';
      final description =
          hsn["HSN_Description"]?.toString().toLowerCase() ?? '';

      return hsnCode.contains(searchLower) || description.contains(searchLower);
    }).toList();

    setState(() {
      filteredList = searchResults.take(pageSize).toList();
      currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    // Calculate responsive values
    final double horizontalPadding = screenSize.width * 0.04;
    final double verticalPadding = screenSize.height * 0.02;

    return SafeArea(
      child: Column(
        children: [
          // Handle bar - made responsive
          Container(
            margin: EdgeInsets.symmetric(vertical: verticalPadding * 0.6),
            height: 4,
            width: screenSize.width * 0.1, // Relative width based on screen
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding * 0.5,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search HSN Code',
                  style: TextStyle(
                    fontSize: 20 * textScaleFactor, // Responsive text size
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: verticalPadding), // Responsive spacing
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search by code or description",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding * 0.6,
                    ),
                  ),
                  onChanged: _filterList,
                ),
              ],
            ),
          ),
          SizedBox(height: verticalPadding * 0.8), // Responsive spacing
          Expanded(
            child: _buildContent(screenSize, textScaleFactor),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Size screenSize, double textScaleFactor) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(screenSize.width * 0.04),
          child: Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontSize: 16 * textScaleFactor, // Responsive text size
            ),
          ),
        ),
      );
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          'No HSN codes found',
          style:
              TextStyle(fontSize: 16 * textScaleFactor), // Responsive text size
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!isFetchingMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent * 0.9) {
          _loadMoreData();
        }
        return false;
      },
      child: ListView.builder(
        controller: widget.scrollController,
        itemCount: filteredList.length + (isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredList.length) {
            return Padding(
              padding: EdgeInsets.all(screenSize.width * 0.02),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final hsn = filteredList[index];
          // Calculate responsive padding for list items
          final double horizontalPadding = screenSize.width * 0.04;
          final double verticalPadding = screenSize.height * 0.01;

          return ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            title: Text(
              hsn["HSN_CD"]?.toString() ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16 * textScaleFactor, // Responsive text size
              ),
            ),
            subtitle: Text(
              hsn["HSN_Description"]?.toString() ?? '',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 14 * textScaleFactor, // Responsive text size
              ),
            ),
            onTap: () {
              widget.onSelectHsn(hsn["HSN_CD"]?.toString() ?? '');
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}