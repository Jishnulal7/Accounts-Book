import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
part 'hive_color.g.dart';

@HiveType(typeId: 7)
class HiveColor {
  @HiveField(0, defaultValue: 0)
  final int value;

  HiveColor(this.value);

  Color toColor() => Color(value);
  static HiveColor fromColor(Color color) => HiveColor(color.value);
}
