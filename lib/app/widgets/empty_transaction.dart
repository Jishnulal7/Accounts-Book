import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EmptyTransactionState extends StatelessWidget {
  final DateTime date;
  final int index;
  const EmptyTransactionState({
    super.key,
    required this.date,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (index == 0)
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ),
          if (index == 1)
            Icon(
              Icons.swap_horiz_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ),
          if (index == 2)
            Icon(
              Icons.account_box_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ),
          Text(
            'No transactions on ${DateFormat('MMM d, yyyy').format(date)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ],
      ),
    );
  }
}
