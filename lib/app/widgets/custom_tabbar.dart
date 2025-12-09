import 'package:flutter/material.dart';

class CustomTabBar extends StatefulWidget {
  final List<String> tabTitles;
  final List<Widget> tabViews;
  final bool isScrollable;
  final EdgeInsetsGeometry? padding;
  final bool wrapInCard;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final double? fontSize;

  const CustomTabBar({
    super.key,
    required this.tabTitles,
    required this.tabViews,
    this.isScrollable = true,
    this.padding,
    this.wrapInCard = false,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.fontSize,
  }) : assert(tabTitles.length == tabViews.length,
            'Tab titles and views must have the same length');

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.tabTitles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTabBarContent() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            tabAlignment: TabAlignment.start,
            controller: _tabController,
            isScrollable: widget.isScrollable,
            labelColor: widget.labelColor ?? Theme.of(context).primaryColor,
            unselectedLabelColor:
                widget.unselectedLabelColor ?? const Color(0xFF5E5E5E),
            labelStyle: TextStyle(
              fontSize: widget.fontSize ?? 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: widget.fontSize ?? 16,
              fontWeight: FontWeight.w600,
            ),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                width: 3,
                color: widget.indicatorColor ?? Theme.of(context).primaryColor,
              ),
            ),
            tabs: widget.tabTitles.map((title) {
              return Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(title),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.tabViews.map((view) {
              return SingleChildScrollView(
                padding: widget.padding,
                child: view,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _buildTabBarContent();

    if (widget.wrapInCard) {
      content = Card(child: content);
    }

    return content;
  }
}
