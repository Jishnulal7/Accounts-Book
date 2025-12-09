
import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/category_text.dart';
import 'package:account_book/app/data/helpers/color_helper.dart';
import 'package:account_book/app/data/helpers/icon_helper.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransactionData extends StatelessWidget {
  final List<String> sortedDates;
  final Map<String, List<dynamic>> filteredItemsByMonth;
  final Function(DateTime) getReceiptsForDay;
  final Function(DateTime) getPaymentsForDay;
  final Function(DateTime) getTransfersForDay;
  final Function(DateTime) getAttendanceForDay;
  final Function(DateTime) calculateBalanceForDay;
  final void Function(DateTime) changeToDailyTab;
  final bool isSelectionModeActive;
  final void Function(String) onSelectItem;
  final void Function(String) onLongPressItem;

  const TransactionData({
    super.key,
    required this.sortedDates,
    required this.filteredItemsByMonth,
    required this.getReceiptsForDay,
    required this.getPaymentsForDay,
    required this.getTransfersForDay,
    required this.getAttendanceForDay,
    required this.calculateBalanceForDay,
    required this.changeToDailyTab,
    required this.isSelectionModeActive,
    required this.onSelectItem,
    required this.onLongPressItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: sortedDates.length,
      shrinkWrap: true,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final dayKey = sortedDates[index];
        final day = DateTime.parse(dayKey);
        final itemsForDay = filteredItemsByMonth[dayKey] ?? [];
        if (itemsForDay.isEmpty) return const SizedBox.shrink();

        return _buildDayCard(context, day, itemsForDay, dayKey);
      },
    );
  }

  Widget _buildDayCard(BuildContext context, DateTime day,
      List<dynamic> itemsForDay, String dayKey) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onLongPress: () => onLongPressItem(dayKey),
        onTap: () {
          if (isSelectionModeActive) {
            onSelectItem(dayKey);
          } else {
            // Ensure we pass the start of the day to avoid any time-related issues
            final selectedDate = DateTime(day.year, day.month, day.day);
            changeToDailyTab(selectedDate);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(context, day),
              const SizedBox(height: 8),
              _buildItemsSummary(itemsForDay, context),
              const SizedBox(height: 8),
              _buildBalanceRow(context, day),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsSummary(List<dynamic> itemsForDay, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: itemsForDay.map((item) {
        if (item is TransactionModel) {
          return _buildTransactionItem(item, context);
        } else if (item is AttendanceModel) {
          return _buildAttendanceItem(item, context);
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildTransactionItem(
    TransactionModel transactions,
    BuildContext context,
  ) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;

    try {
      if (transactions.transactionType == TransactionType.transfer) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Image.asset(
                      CustomIcons()
                          .getImagePathForAccounts(transactions.fromAccount),
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        transactions.fromAccount,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_right_alt_outlined,
                      size: 22,
                    ),
                    Image.asset(
                      CustomIcons()
                          .getImagePathForAccounts(transactions.toAccount),
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        transactions.toAccount,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$currencySymbol${transactions.amount.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Image.asset(
                transactions.iconData ?? '',
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  getCategoryText(transactions),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$currencySymbol${transactions.amount.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 12,
                  color: ColorHelper().selectColor(transactions),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error while getting transaction type: $e');
      return const Text('Unknown');
    }
  }

  Widget _buildAttendanceItem(
      AttendanceModel attendance, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Image.asset(
            'assets/categories/profile.png',
            width: 22,
            height: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              attendance.subName,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '- ${attendance.payment.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 12,
              color: AppColor.kRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, DateTime day) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          DateFormat('dd').format(day),
          style: textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM y').format(day),
              style: textTheme.titleMedium?.copyWith(fontSize: 14),
            ),
            Text(
              DateFormat('EEEE').format(day),
              style: textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceRow(BuildContext context, DateTime day) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    final balance = calculateBalanceForDay(day);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Balance: ',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12),
        ),
        Text(
          '$currencySymbol${balance.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: balance >= 0 ? Colors.green : Colors.red,
                fontSize: 14,
              ),
        ),
      ],
    );
  }
}
