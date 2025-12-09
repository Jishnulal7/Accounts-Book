import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/color_helper.dart';
import 'package:account_book/app/screens/home/exports.dart';
import 'package:flutter/rendering.dart';

class AppDrawer extends StatefulWidget {
  final VoidCallback onSaleAdded;
  final bool isExpanded;
  final Function(bool) onToggleExpanded;
  final int selectedIndex;
  final Function(int) onItemSelected;
  const AppDrawer({
    super.key,
    required this.onSaleAdded,
    this.isExpanded = true,
    required this.onToggleExpanded,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isSaleExpanded = false;
  bool _isPurchaseExpanded = false;

  // Add scroll controllers
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _saleScrollController = ScrollController();
  final ScrollController _purchaseScrollController = ScrollController();

  // Map of GlobalKeys for each menu item
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _updateExpansionStates();

    // Initialize keys for all menu items
    for (int i = 0; i < 17; i++) {
      _itemKeys[i] = GlobalKey();
    }

    // Schedule a scroll to the selected item after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedItem();
    });
  }

  @override
  void didUpdateWidget(AppDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the selected index changed, update expansion state and scroll
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _updateExpansionStates();

      // Schedule a scroll to the newly selected item
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedItem();
      });
    }
  }

  void _scrollToSelectedItem() {
    final selectedKey = _itemKeys[widget.selectedIndex];
    if (selectedKey?.currentContext != null) {
      final RenderObject? renderObject =
          selectedKey!.currentContext!.findRenderObject();
      final RenderAbstractViewport viewport =
          RenderAbstractViewport.of(renderObject);

      // Get the position of the selected item within the viewport
      final position = viewport.getOffsetToReveal(renderObject!, 0.0);

      // Determine which scroll controller to use
      ScrollController? controllerToUse;
      if (widget.selectedIndex >= 4 && widget.selectedIndex <= 11) {
        controllerToUse = _saleScrollController;
      } else if (widget.selectedIndex >= 12 && widget.selectedIndex <= 16) {
        controllerToUse = _purchaseScrollController;
      } else {
        controllerToUse = _mainScrollController;
      }

      // Scroll to position if controller is attached
      if (controllerToUse.hasClients) {
        controllerToUse.animateTo(
          position.offset,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _updateExpansionStates() {
    final saleIndices = {4, 5, 6, 7, 8, 9, 10, 11};
    final purchaseIndices = {12, 13, 14, 15, 16};

    setState(() {
      _isSaleExpanded = saleIndices.contains(widget.selectedIndex);
      _isPurchaseExpanded = purchaseIndices.contains(widget.selectedIndex);
    });
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _saleScrollController.dispose();
    _purchaseScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = Platform.isWindows;
    final drawerWidth = isWindows ? (widget.isExpanded ? 280.0 : 70.0) : null;

    return Container(
      width: drawerWidth,
      decoration: BoxDecoration(
        border: isWindows
            ? Border(
                right: BorderSide(
                  width: 1,
                ),
              )
            : null,
      ),
      child: Column(
        children: [
          if (isWindows) _buildToggleButton(context),
          Expanded(
            child: SingleChildScrollView(
              controller: _mainScrollController,
              key: PageStorageKey<String>('drawer-list'),
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  if (widget.isExpanded)
                    _buildDrawerCategory(
                      context,
                      'Main',
                      Icons.home,
                    )
                  else
                    SizedBox(height: 16),

                  _buildDrawerItem(
                    context,
                    Icons.dashboard,
                    'Dashboard',
                    Theme.of(context).primaryColor,
                    () => widget.onItemSelected(0),
                    0,
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.people,
                    'Parties',
                    Theme.of(context).primaryColor,
                    () => widget.onItemSelected(1),
                    1,
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.inventory,
                    'Items',
                    Theme.of(context).primaryColor,
                    () => widget.onItemSelected(2),
                    2,
                  ),

                  if (widget.isExpanded)
                    _buildDrawerCategory(
                      context,
                      'Reports',
                      Icons.insert_chart,
                    )
                  else
                    SizedBox(height: 16),

                  _buildDrawerItem(
                    context,
                    Icons.table_chart_outlined,
                    'Reports',
                    Theme.of(context).primaryColor,
                    () => widget.onItemSelected(3),
                    3,
                  ),

                  // Sale expansion tile - now uses custom implementation
                  _buildCustomExpansionTile(
                    context,
                    Icons.receipt,
                    'Sale',
                    Theme.of(context).primaryColor,
                    _isSaleExpanded,
                    (isExpanded) {
                      setState(() {
                        _isSaleExpanded = isExpanded;
                      });
                      // If we're expanding and the selected item is in this section, scroll to it
                      if (isExpanded &&
                          widget.selectedIndex >= 4 &&
                          widget.selectedIndex <= 11) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToSelectedItem();
                        });
                      }
                    },
                    [
                      _buildSubItem(
                        context,
                        'Sale History',
                        () => _onSubItemSelected(4),
                        4,
                      ),
                      _buildSubItem(
                        context,
                        'Sale',
                        () => _onSubItemSelected(5),
                        5,
                      ),
                      _buildSubItem(
                        context,
                        'Sale Order',
                        () => _onSubItemSelected(6),
                        6,
                      ),
                      _buildSubItem(
                        context,
                        'Sale Return',
                        () => _onSubItemSelected(7),
                        7,
                      ),
                      _buildSubItem(
                        context,
                        'Estimate',
                        () => _onSubItemSelected(8),
                        8,
                      ),
                      _buildSubItem(
                        context,
                        'Proforma Invoice',
                        () => _onSubItemSelected(9),
                        9,
                      ),
                      _buildSubItem(
                        context,
                        'Delivery Challan',
                        () => _onSubItemSelected(10),
                        10,
                      ),
                      _buildSubItem(
                        context,
                        'Receipt',
                        () => _onSubItemSelected(11),
                        11,
                      ),
                    ],
                    _saleScrollController,
                  ),

                  // Purchase expansion tile - now uses custom implementation
                  _buildCustomExpansionTile(
                    context,
                    Icons.add_shopping_cart,
                    'Purchase',
                    Theme.of(context).primaryColor,
                    _isPurchaseExpanded,
                    (isExpanded) {
                      setState(() {
                        _isPurchaseExpanded = isExpanded;
                      });
                      // If we're expanding and the selected item is in this section, scroll to it
                      if (isExpanded &&
                          widget.selectedIndex >= 12 &&
                          widget.selectedIndex <= 16) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToSelectedItem();
                        });
                      }
                    },
                    [
                      _buildSubItem(
                        context,
                        'Purchase History',
                        () => _onSubItemSelected(12),
                        12,
                      ),
                      _buildSubItem(
                        context,
                        'Purchase',
                        () => _onSubItemSelected(13),
                        13,
                      ),
                      _buildSubItem(
                        context,
                        'Purchase Order',
                        () => _onSubItemSelected(14),
                        14,
                      ),
                      _buildSubItem(
                        context,
                        'Purchase Return',
                        () => _onSubItemSelected(15),
                        15,
                      ),
                      _buildSubItem(
                        context,
                        'Payment',
                        () => _onSubItemSelected(16),
                        16,
                      ),
                    ],
                    _purchaseScrollController,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSubItemSelected(int index) {
    if (widget.selectedIndex != index) {
      widget.onItemSelected(index);
    }
  }

  Widget _buildToggleButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      alignment: Alignment.centerRight,
      height: 48,
      child: IconButton(
        icon: Icon(
          widget.isExpanded ? Icons.chevron_left : Icons.chevron_right,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        onPressed: () {
          widget.onToggleExpanded(!widget.isExpanded);
        },
        tooltip: widget.isExpanded ? 'Collapse' : 'Expand',
      ),
    );
  }

  Widget _buildDrawerCategory(
      BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: ColorHelper().darkorWhite(context),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ColorHelper().darkorWhite(context),
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: ColorHelper().darkorWhite(context),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String label,
    Color iconColor,
    VoidCallback onTap,
    int index,
  ) {
    final isWindows = Platform.isWindows;
    final isSelected = widget.selectedIndex == index;

    if (isWindows && !widget.isExpanded) {
      return Tooltip(
        key: _itemKeys[index],
        message: label,
        preferBelow: false,
        verticalOffset: 20,
        child: Container(
          height: 50,
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? iconColor.withOpacity(0.3)
                : iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: iconColor,
            ),
            onPressed: onTap,
          ),
        ),
      );
    }

    return ListTile(
      key: _itemKeys[index],
      dense: true,
      leading: Icon(
        icon,
        color: isSelected ? AppColor.kPrimary : Theme.of(context).primaryColor,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? AppColor.kPrimary
              : ColorHelper().darkorWhite(context),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildCustomExpansionTile(
    BuildContext context,
    IconData icon,
    String label,
    Color iconColor,
    bool isExpanded,
    Function(bool) onExpandChanged,
    List<Widget> children,
    ScrollController scrollController,
  ) {
    final isWindows = Platform.isWindows;

    // For collapsed state in Windows, show only icon
    if (isWindows && !widget.isExpanded) {
      return Tooltip(
        message: label,
        preferBelow: false,
        verticalOffset: 20,
        child: Container(
          height: 50,
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: iconColor,
            ),
            onPressed: () {
              if (!widget.isExpanded) {
                widget.onToggleExpanded(true);
              } else {
                onExpandChanged(!isExpanded);
              }
            },
          ),
        ),
      );
    }

    // For expanded drawer state, use a custom expansion implementation
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row that acts as the expansion toggle
        ListTile(
          dense: true,
          leading: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: ColorHelper().darkorWhite(context),
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Theme.of(context).primaryColor,
          ),
          onTap: () {
            onExpandChanged(!isExpanded);
          },
        ),

        // Children displayed when expanded
        AnimatedCrossFade(
          duration: Duration(milliseconds: 200),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Container(), // Empty when collapsed
          secondChild: ListView(
            controller: scrollController,
            shrinkWrap: true,
            physics: AlwaysScrollableScrollPhysics(),
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSubItem(
    BuildContext context,
    String label,
    VoidCallback onTap,
    int index,
  ) {
    final isSelected = widget.selectedIndex == index;

    return ListTile(
      key: _itemKeys[index],
      dense: true,
      leading: Container(
        width: 5,
        color: isSelected ? AppColor.kBackground : Colors.transparent,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isSelected
              ? AppColor.kPrimary
              : ColorHelper().darkorWhite(context),
        ),
      ),
      onTap: onTap,
    );
  }
}
