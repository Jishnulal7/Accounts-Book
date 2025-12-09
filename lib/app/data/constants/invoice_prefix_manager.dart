import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedPrefix {
  final String code;

  SavedPrefix({required this.code});

  Map<String, dynamic> toJson() => {
        'code': code,
      };

  factory SavedPrefix.fromJson(Map<String, dynamic> json) => SavedPrefix(
        code: json['code'],
      );
}

class PrefixManager {
  static const String _prefixKey = 'saved_invoice_prefixes';

  static Future<List<SavedPrefix>> getSavedPrefixes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? prefixesJson = prefs.getString(_prefixKey);

    if (prefixesJson == null) return [];

    try {
      final List<dynamic> decodedList = jsonDecode(prefixesJson);

      return decodedList.map((item) => SavedPrefix.fromJson(item)).toList();
    } catch (e) {
      // Handle parsing errors
      debugPrint('Error parsing saved prefixes: $e');
      return [];
    }
  }

  static Future<void> savePrefix(SavedPrefix prefix) async {
    final prefs = await SharedPreferences.getInstance();
    final List<SavedPrefix> currentPrefixes = await getSavedPrefixes();

    // Check if prefix already exists
    if (!currentPrefixes.any((p) => p.code == prefix.code)) {
      currentPrefixes.add(prefix);

      final String encodedPrefixes =
          jsonEncode(currentPrefixes.map((p) => p.toJson()).toList());

      await prefs.setString(_prefixKey, encodedPrefixes);
    }
  }

  static Future<void> removePrefix(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final List<SavedPrefix> currentPrefixes = await getSavedPrefixes();

    final filteredPrefixes =
        currentPrefixes.where((p) => p.code != code).toList();

    final String encodedPrefixes =
        jsonEncode(filteredPrefixes.map((p) => p.toJson()).toList());

    await prefs.setString(_prefixKey, encodedPrefixes);
  }
}
