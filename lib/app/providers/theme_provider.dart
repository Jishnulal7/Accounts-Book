import 'package:flutter/material.dart';
import 'package:account_book/app/data/constants/colors.dart';
import 'package:hive_ce/hive.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _themeColor = AppColor.kPrimary;

  ThemeNotifier() {
    // Load the theme settings from Hive when the app starts
    final box = Hive.box('themeSettings');
    _themeMode = box.get('themeMode', defaultValue: ThemeMode.system);
    _themeColor =
        Color(box.get('themeColor', defaultValue: AppColor.kPrimary.value));
  }

  ThemeMode get themeMode => _themeMode;
  Color get themeColor => _themeColor;

  void setTheme(ThemeMode themeMode) {
    _themeMode = themeMode;
    Hive.box('themeSettings').put('themeMode', themeMode);
    notifyListeners();
  }

  void setThemeColor(Color color) {
    _themeColor = color;
    Hive.box('themeSettings').put('themeColor', color.value);
    notifyListeners();
  }
}
