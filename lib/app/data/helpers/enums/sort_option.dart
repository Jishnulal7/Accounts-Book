import 'package:flutter/material.dart';

enum SortOption {
  dateAsc,
  dateDesc,
  amountAsc,
  amountDesc;

  String get label {
    switch (this) {
      case SortOption.dateAsc:
        return 'Oldest First';
      case SortOption.dateDesc:
        return 'Latest First';
      case SortOption.amountAsc:
        return 'Lowest Amount First';
      case SortOption.amountDesc:
        return 'Highest Amount First';
    }
  }

  IconData get icon {
    switch (this) {
      case SortOption.dateAsc:
        return Icons.arrow_upward;
      case SortOption.dateDesc:
        return Icons.arrow_downward;
      case SortOption.amountAsc:
        return Icons.trending_down;
      case SortOption.amountDesc:
        return Icons.trending_up;
    }
  }
}
