import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class RefreshableWidget extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const RefreshableWidget({
    required Key key,
    required this.child,
    required this.onRefresh,
  }) : super(key: key);

  @override
  RefreshableWidgetState createState() => RefreshableWidgetState();
}

class RefreshableWidgetState extends State<RefreshableWidget> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final ScrollController _scrollController = ScrollController();

  Future<void> refresh() async {
    try {
      double offset = _scrollController.offset;
      await widget.onRefresh();
      _refreshController.refreshCompleted();

      // Restore scroll position after refresh
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(offset);
        }
      });
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      enablePullDown: true,
      header: const WaterDropHeader(),
      controller: _refreshController,
      onRefresh: refresh,
      physics: Platform.isWindows ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
      child: widget.child, // Pass child normally
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}