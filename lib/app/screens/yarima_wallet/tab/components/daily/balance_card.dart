import 'package:account_book/app/providers/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountBalanceWidget extends StatefulWidget {
  final Map<String, double> accountBalances;
  final Function(String) onAccountChanged;

  const AccountBalanceWidget({
    super.key,
    required this.accountBalances,
    required this.onAccountChanged,
  });

  @override
  AccountBalanceWidgetState createState() => AccountBalanceWidgetState();
}

class AccountBalanceWidgetState extends State<AccountBalanceWidget>
    with SingleTickerProviderStateMixin {
  late String _selectedAccount;
  bool _expanded = false;
  static const int _initialDisplayCount = 2;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.accountBalances.keys.first;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getChipBackgroundColor(BuildContext context, bool isSelected) {
    final brightness = Theme.of(context).brightness;
    if (isSelected) {
      return Theme.of(context).colorScheme.primary;
    }
    return brightness == Brightness.dark
        ? Colors.grey[800]!
        : Colors.grey[100]!;
  }

  Color _getChipTextColor(BuildContext context, bool isSelected) {
    final brightness = Theme.of(context).brightness;
    if (isSelected) {
      return Theme.of(context).colorScheme.onPrimary;
    }
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    final accountCount = widget.accountBalances.keys.length;
    final shouldShowExpandCollapse = accountCount > 2;

    final displayedAccounts = shouldShowExpandCollapse
        ? (_expanded
            ? widget.accountBalances.keys.toList()
            : widget.accountBalances.keys.take(_initialDisplayCount).toList())
        : widget.accountBalances.keys.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 54,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) => ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount:
                  displayedAccounts.length + (shouldShowExpandCollapse ? 1 : 0),
              itemBuilder: (context, index) {
                if (shouldShowExpandCollapse &&
                    index == displayedAccounts.length) {
                  return _expanded
                      ? _buildCollapseButton()
                      : _buildExpandButton();
                }
                return _buildAccountChip(displayedAccounts[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountChip(String account) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    final balance = widget.accountBalances[account]!;
    final isSelected = _selectedAccount == account;
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
      builder: (context, value, child) {
        final backgroundColor = Color.lerp(
          _getChipBackgroundColor(context, false),
          _getChipBackgroundColor(context, true),
          value,
        )!;
        final textColor = Color.lerp(
          _getChipTextColor(context, false),
          _getChipTextColor(context, true),
          value,
        )!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            elevation: 1 + (value * 2),
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            color: backgroundColor,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedAccount = account;
                });
                widget.onAccountChanged(account);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$currencySymbol${balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onPressed) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(16),
        color:
            brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100],
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return _buildActionChip(
      Icons.keyboard_arrow_down_rounded,
      'More',
      () {
        setState(() {
          _expanded = true;
          _controller.forward();
        });
      },
    );
  }

  Widget _buildCollapseButton() {
    return _buildActionChip(
      Icons.keyboard_arrow_up_rounded,
      'Less',
      () {
        setState(() {
          _expanded = false;
          _controller.reverse();
        });
      },
    );
  }
}
