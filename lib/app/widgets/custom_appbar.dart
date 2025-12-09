import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> sortedDates;
  final VoidCallback onBackPressed;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;
  final int selectedItemsCount;

  const CustomAppBar({
    super.key,
    required this.sortedDates,
    required this.onBackPressed,
    required this.onSelectAll,
    required this.onDelete,
    required this.selectedItemsCount,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed,
      ),
      actions: [
        Text('$selectedItemsCount Selected'),
        TextButton(
          onPressed: onSelectAll,
          child: const Text('Select All'),
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_forever),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}