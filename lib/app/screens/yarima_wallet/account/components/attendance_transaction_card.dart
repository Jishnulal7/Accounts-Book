import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/icon_helper.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AttendanceTransactionCard extends StatelessWidget {
  const AttendanceTransactionCard({
    super.key,
    required this.attendance,
    required this.color,
    this.onEdit,
    this.onDelete,
    required this.isEditable,
  });

  final AttendanceModel attendance;
  final Color color;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildAmount(context),
              const SizedBox(height: 8),
              _buildDate(),
              const SizedBox(height: 16),
              Divider(color: color),
              const SizedBox(height: 16),
              _buildAttendanceDetails(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Attendance',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Row(
          children: [
            if (isEditable) ...[
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
            ],
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmount(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Text(
      '$currencySymbol${attendance.payment.toStringAsFixed(1)}',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColor.kRed,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDate() {
    return Text(
      DateFormat('dd MMM yyyy').format(attendance.date),
      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAttendanceDetails(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return Column(
      spacing: 12,
      children: [
        _buildDetailRow(label: 'Name', value: attendance.name),
        _buildDetailRow(label: 'Sub Name', value: attendance.subName),
        _buildDetailRow(
          label: 'Status',
          value: attendance.isPresent ? 'Present' : 'Absent',
        ),
        _buildDetailRow(
            label: 'Wage',
            value: '$currencySymbol${attendance.wage.toStringAsFixed(1)}'),
        _buildDetailRow(label: 'Site Name', value: attendance.siteName),
        _buildDetailRow(
          label: 'Extra Charges',
          value: '$currencySymbol${attendance.extraCharges.toStringAsFixed(1)}',
        ),
        _buildDetailRow(label: 'Description', value: attendance.description),
        _buildDetailRow(
          label: 'Balance',
          value: '$currencySymbol${attendance.balance.toStringAsFixed(1)}',
        ),
        _buildDetailRow(
          label: 'Opening Balance',
          value:
              '$currencySymbol${attendance.openingBalance.toStringAsFixed(1)}',
        ),
        _buildDetailRow(
          label: 'Account',
          value: attendance.account,
          iconPath: CustomIcons().getImagePathForAccounts(attendance.account),
        ),
        _buildDetailRow(
          label: 'Category',
          value:
              attendance.generalCategoryName ?? attendance.categoryName ?? '',
          iconPath: CustomIcons().getImagePathForCategory(
              attendance.generalCategoryName ?? attendance.categoryName ?? ''),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    String? iconPath,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Row(
            children: [
              if (iconPath != null) ...[
                Image.asset(iconPath, width: 24, height: 24),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(value, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
