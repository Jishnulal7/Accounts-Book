import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.items,
  });

  final List<BottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ...items.take(2).map((item) => _buildNavBarItem(context, item)),
        const SizedBox(width: 60),
        ...items.skip(2).map((item) => _buildNavBarItem(context, item)),
      ],
    );
  }

  Widget _buildNavBarItem(BuildContext context, BottomNavItem item) {
    return Expanded(
      child: InkWell(
        onTap: () => _navigateToScreen(context, item.screen),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              item.icon,
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}

class BottomNavItem {
  final String icon;
  final String label;
  final Widget screen;

  BottomNavItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}