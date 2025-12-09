import 'dart:io';
import 'package:account_book/app/data/helpers/category_text.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/widgets/empty_transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AttendanceSectionInDailyTab extends StatelessWidget {
  final List<AttendanceModel> attendanceRecords;
  final Function(AttendanceModel) editAttendance;
  final Function(AttendanceModel) deleteAttendance;
  final DateTime date;

  const AttendanceSectionInDailyTab({
    super.key,
    required this.attendanceRecords,
    required this.editAttendance,
    required this.deleteAttendance,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to determine screen size and adjust layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 360;
    final isWide = screenWidth > 600;

    if (attendanceRecords.isEmpty) {
      return EmptyTransactionState(
        date: date,
        index: 2,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      // physics: const NeverScrollableScrollPhysics(),
      itemCount: attendanceRecords.length,
      itemBuilder: (context, index) => _buildAttendanceCard(
        context,
        attendanceRecords[index],
        isNarrow: isNarrow,
        isWide: isWide,
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, AttendanceModel record,
      {bool isNarrow = false, bool isWide = false}) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context, listen: false).currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust card padding based on screen width
        final cardPadding = screenWidth < 360
            ? const EdgeInsets.all(8)
            : const EdgeInsets.all(16);

        return Card(
          margin:
              EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 16, vertical: 8),
          child: InkWell(
            onTap: () => _showAttendanceDetails(context, record),
            child: Padding(
              padding: cardPadding,
              child: Column(
                children: [
                  // Responsive first row
                  _buildResponsiveFirstRow(
                    context,
                    record,
                    currencySymbol,
                    isDark,
                    isNarrow: isNarrow,
                  ),
                  Divider(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      height: 20),
                  // Responsive info row
                  _buildResponsiveInfoRow(
                    context,
                    record,
                    currencySymbol,
                    isNarrow: isNarrow,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveFirstRow(BuildContext context, AttendanceModel record,
      String currencySymbol, bool isDark,
      {bool isNarrow = false}) {
    final theme = Theme.of(context);

    return isNarrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusIndicator(record.isPresent, isDark),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.name,
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis),
                        Text(record.subName,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  _buildPaymentChip(currencySymbol, record.payment, isDark),
                ],
              ),
            ],
          )
        : Row(
            children: [
              _buildStatusIndicator(record.isPresent, isDark),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.name, style: theme.textTheme.titleMedium),
                      Text(record.subName, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              _buildPaymentChip(currencySymbol, record.payment, isDark),
            ],
          );
  }

  Widget _buildResponsiveInfoRow(
      BuildContext context, AttendanceModel record, String currencySymbol,
      {bool isNarrow = false}) {
    final theme = Theme.of(context);

    // For very narrow screens, use a single column layout
    if (isNarrow) {
      return Column(
        spacing: 8,
        children: [
          _buildInfoColumn('Site', record.siteName, Icons.location_on_outlined,
              theme, context),
          _buildInfoColumn(
              'Wage',
              '$currencySymbol${record.wage.toStringAsFixed(1)}',
              Icons.payments_outlined,
              theme,
              context),
          _buildInfoColumn(
              'Balance',
              '$currencySymbol${record.balance.toStringAsFixed(1)}',
              Icons.account_balance_outlined,
              theme,
              context),
        ],
      );
    }

    // For wider screens, use the original row layout
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoColumn('Site', record.siteName, Icons.location_on_outlined,
            theme, context),
        _buildInfoColumn(
            'Wage',
            '$currencySymbol${record.wage.toStringAsFixed(1)}',
            Icons.payments_outlined,
            theme,
            context),
        _buildInfoColumn(
            'Balance',
            '$currencySymbol${record.balance.toStringAsFixed(1)}',
            Icons.account_balance_outlined,
            theme,
            context),
      ],
    );
  }

  Widget _buildStatusIndicator(bool isPresent, bool isDark) {
    final bgColor = isPresent
        ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green[50])
        : (isDark ? Colors.red.withOpacity(0.2) : Colors.red[50]);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPresent ? Icons.check_circle : Icons.cancel,
            color: isPresent ? Colors.green[400] : Colors.red[400],
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isPresent ? 'Present' : 'Absent',
            style: TextStyle(
              color: isPresent ? Colors.green[400] : Colors.red[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChip(String currencySymbol, double payment, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$currencySymbol${payment.toStringAsFixed(1)}',
        style: TextStyle(
          color: isDark ? Colors.blue[300] : Colors.blue[700],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon,
      ThemeData theme, BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showAttendanceDetails(BuildContext context, AttendanceModel record) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context, listen: false).currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attendance Details',
                    style: theme.textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Divider(
                height: 24,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              _buildDetailGrid(context, record, currencySymbol),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        editAttendance(record);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        deleteAttendance(record);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailGrid(
      BuildContext context, AttendanceModel record, String currencySymbol) {
    Theme.of(context);
    final isWindows = Platform.isWindows;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: isWindows ? 2 : 1.2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildDetailItem(context, 'Date',
            DateFormat('yyyy-MM-dd').format(record.date), Icons.calendar_today),
        _buildDetailItem(context, 'Name', record.subName, Icons.person),
        _buildDetailItem(context, 'Category', record.name, Icons.category),
        _buildDetailItem(context, 'Payment Category',
            getCategoryTextForAttendance(record), Icons.category),
        _buildDetailItem(
            context, 'Account', record.account, Icons.account_balance),
        _buildDetailItem(context, 'Site', record.siteName, Icons.location_on),
        _buildDetailItem(context, 'Wage',
            '$currencySymbol${record.wage.toStringAsFixed(1)}', Icons.payments),
        _buildDetailItem(
            context,
            'Extra Charges',
            '$currencySymbol${record.extraCharges.toStringAsFixed(1)}',
            Icons.add_circle),
        _buildDetailItem(
            context,
            'Payment',
            '$currencySymbol${record.payment.toStringAsFixed(1)}',
            Icons.payment),
        _buildDetailItem(
            context,
            'Balance',
            '$currencySymbol${record.balance.toStringAsFixed(1)}',
            Icons.account_balance_wallet),
      ],
    );
  }

  Widget _buildDetailItem(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).primaryColor,
                // color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
