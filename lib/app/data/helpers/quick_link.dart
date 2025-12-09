import 'package:flutter/material.dart';

class QuickLinkData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickLinkData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
