import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyNotifier extends ChangeNotifier {
  String _currencyName = 'INR';
  String _currencySymbol = '₹';
  final List<Map<String, String>> _availableCurrencies = [
    {'name': 'USD', 'symbol': '\$'},
    {'name': 'EUR', 'symbol': '€'},
    {'name': 'JPY', 'symbol': '¥'},
    {'name': 'GBP', 'symbol': '£'},
    {'name': 'AUD', 'symbol': 'A\$'},
    {'name': 'CAD', 'symbol': 'C\$'},
    {'name': 'CNY', 'symbol': '¥'},
    {'name': 'HKD', 'symbol': 'HK\$'},
    {'name': 'NZD', 'symbol': 'NZ\$'},
    {'name': 'SGD', 'symbol': 'S\$'},
    {'name': 'ZAR', 'symbol': 'R'},
    {'name': 'MXN', 'symbol': '\$'},
    {'name': 'BRL', 'symbol': 'R\$'},
    {'name': 'TRY', 'symbol': '₺'},
    {'name': 'RUB', 'symbol': '₽'},
    {'name': 'INR', 'symbol': '₹'},
    {'name': 'KRW', 'symbol': '₩'},
    {'name': 'MYR', 'symbol': 'RM'},
    {'name': 'PHP', 'symbol': '₱'},
    {'name': 'THB', 'symbol': '฿'},
    {'name': 'IDR', 'symbol': 'Rp'},
  ];

  CurrencyNotifier() {
    _loadSavedCurrency();
  }

  List<Map<String, String>> get availableCurrencies => _availableCurrencies;
  String get currencyName => _currencyName;
  String get currencySymbol => _currencySymbol;

  Future<void> _loadSavedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currencyName = prefs.getString('currency_name') ?? 'INR';
    _currencySymbol = prefs.getString('currency_symbol') ?? '₹';
    notifyListeners();
  }

  Future<void> updateCurrency(String name, String symbol) async {
    _currencyName = name;
    _currencySymbol = symbol;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_name', name);
    await prefs.setString('currency_symbol', symbol);

    notifyListeners();
  }
}
