import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class DateSelectionRow extends StatelessWidget {
  final DateTime selectMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onSelectMonthYear;

  const DateSelectionRow({
    super.key,
    required this.selectMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectMonthYear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onPreviousMonth,
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                minWidth: 35,
                minHeight: 35,
              ),
            ),
            _buildMonthYearSelector(context),
            IconButton(
              onPressed: onNextMonth,
              icon: const Icon(Icons.arrow_forward_ios, size: 18),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                minWidth: 35,
                minHeight: 35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthYearSelector(BuildContext context) {
    DateTime now = DateTime.now();
    bool isCurrentMonth =
        selectMonth.month == now.month && selectMonth.year == now.year;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onSelectMonthYear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrentMonth
              ? Theme.of(context).primaryColor
              : (isDark ? Colors.grey[800] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('MMMM y').format(selectMonth),
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isCurrentMonth
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
