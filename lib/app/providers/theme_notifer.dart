// import 'package:account_book/app/data/model/hive_color.dart';
// import 'package:flutter/material.dart';
// import 'package:hive_ce/hive.dart';

// class ThemeNotifier extends ChangeNotifier {
//   static const String _themeBoxName = 'themeSettings';
//   static const String _themeModeKey = 'themeMode';
//   static const String _primaryColorKey = 'primaryColor';

//   ThemeMode _themeMode = ThemeMode.system;
//   Color _primaryColor = Colors.blue;

//   ThemeNotifier() {
//     final box = Hive.box(_themeBoxName);

//     _themeMode = box.get(_themeModeKey, defaultValue: ThemeMode.system);

//     // Use HiveColor for storage
//     final storedColor =
//         box.get(_primaryColorKey, defaultValue: HiveColor(Colors.blue.value));
//     _primaryColor = storedColor.toColor();
//   }

//   ThemeMode get themeMode => _themeMode;
//   Color get primaryColor => _primaryColor;

//   void setTheme(ThemeMode themeMode) {
//     _themeMode = themeMode;
//     Hive.box(_themeBoxName).put(_themeModeKey, themeMode);
//     notifyListeners();
//   }

//   void setPrimaryColor(Color color) {
//     _primaryColor = color;
//     Hive.box(_themeBoxName).put(_primaryColorKey, HiveColor.fromColor(color));
//     notifyListeners();
//   }
// }
