import 'package:account_book/app/data/helpers/enums/sort_option.dart';
import 'package:flutter/material.dart';

class GlobalSortButton extends StatelessWidget {
  final SortOption currentSort;
  final Function(SortOption) onSortChanged;
  final Color? iconColor;
  final double? iconSize;
  final List<SortOption>? availableOptions;

  const GlobalSortButton({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    this.iconColor,
    this.iconSize,
    this.availableOptions,
  });

  @override
  Widget build(BuildContext context) {
    final options = availableOptions ?? SortOption.values;

    return PopupMenuButton<SortOption>(
      initialValue: currentSort,
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sort,
            color: iconColor,
            size: iconSize,
          ),
          const SizedBox(width: 4),
          Icon(
            currentSort.icon,
            color: iconColor,
            size: (iconSize ?? 24) - 4,
          ),
        ],
      ),
      onSelected: onSortChanged,
      itemBuilder: (BuildContext context) => options
          .map(
            (option) => PopupMenuItem<SortOption>(
              value: option,
              child: Row(
                children: [
                  Icon(
                    option.icon,
                    color: currentSort == option
                        ? Theme.of(context).primaryColor
                        : null,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    option.label,
                    style: TextStyle(
                      color: currentSort == option
                          ? Theme.of(context).primaryColor
                          : null,
                      fontWeight:
                          currentSort == option ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
