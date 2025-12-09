import 'package:account_book/app/providers/assets_provider.dart';
import 'package:account_book/app/providers/business_provider.dart';
import 'package:account_book/app/providers/dashboard_provider.dart';
import 'package:account_book/app/providers/day_book_provider.dart';
import 'package:account_book/app/providers/edit_transaction_provider.dart';
import 'package:account_book/app/providers/item_provider.dart';
import 'package:account_book/app/providers/party_provider.dart';
import 'package:account_book/app/providers/theme_provider.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/providers/transaction_provider.dart';
import 'package:account_book/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class MyAppWrapper extends StatelessWidget {
  const MyAppWrapper({super.key, required this.initialScreen});
  final Widget initialScreen;
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyNotifier()),
        ChangeNotifierProvider(create: (_) => PartyProvider()..openBox()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => AssetProvider()),
        ChangeNotifierProvider(create: (_) => DayBookProvider()),
        ChangeNotifierProvider(create: (_) => EditTransactionProvider()),
      ],
      child: MyApp(
        initialScreen: initialScreen,
      ),
    );
  }
}
