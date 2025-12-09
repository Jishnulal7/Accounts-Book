import 'package:account_book/app/data/model/asset_model.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/budget_model.dart';
import 'package:account_book/app/data/model/hive_color.dart';
import 'package:account_book/app/data/model/liability_model.dart';
import 'package:account_book/app/data/model/payment_record.dart';
import 'package:account_book/app/data/model/stock_adjustment_model.dart';
import 'package:account_book/app/data/model/task_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/data/model/theme_mode_adapetar.g.dart';
import 'package:account_book/app/data/model/item_selection_model.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:account_book/app/data/model/item_model.dart';
import 'package:account_book/app/data/model/party_model.dart';
import 'package:account_book/app/data/model/purchase_model.dart';
import 'package:account_book/app/data/model/sale_model.dart';
import 'dart:io';

class HiveService {
  static Future<void> initializeHive() async {
    // Get the document directory
    final appDocumentDirectory =
        await path_provider.getApplicationDocumentsDirectory();

    // Create a 'Hive' subdirectory
    final hivePath = '${appDocumentDirectory.path}/Hive';

    // Create the directory if it doesn't exist
    final hiveDir = Directory(hivePath);
    if (!hiveDir.existsSync()) {
      hiveDir.createSync(recursive: true);
    }

    // Initialize Hive with the custom path
    Hive.init(hivePath);

    // Register adapters
    Hive.registerAdapter(ItemModelAdapter());
    Hive.registerAdapter(PartyModelAdapter());
    Hive.registerAdapter(PurchaseModelAdapter());
    Hive.registerAdapter(PurchaseTypeAdapter());
    Hive.registerAdapter(SaleModelAdapter());
    Hive.registerAdapter(SalesTypeAdapter());
    Hive.registerAdapter(ItemSelectionModelAdapter());
    Hive.registerAdapter(ThemeModeAdapter());
    Hive.registerAdapter<TransactionModel>(TransactionModelAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(AttendanceModelAdapter());
    Hive.registerAdapter(HiveColorAdapter());
    Hive.registerAdapter(StockAdjustmentModelAdapter());
    Hive.registerAdapter(AdjustmentTypeAdapter());
    Hive.registerAdapter(AssetModelAdapter());
    Hive.registerAdapter(LiabilityModelAdapter());
    Hive.registerAdapter(PaymentRecordAdapter());
    Hive.registerAdapter(BudgetPeriodAdapter());

    // Open boxes
    await Hive.openBox('themeMode');
    await Hive.openBox('themeSettings');
    await Hive.openBox('themeColor');
    await Hive.openBox<PartyModel>('partyBox');
    await Hive.openBox<ItemModel>('itemBox');
    await Hive.openBox<StockAdjustmentModel>('stockAdjustmentBox');
    await Hive.openBox<TaskModel>('tasks');
    await Hive.openBox<TransactionModel>('transactions');
    await Hive.openBox<AttendanceModel>('attendanceBox');
    await Hive.openBox<SaleModel>('saleBox');
    await Hive.openBox<PurchaseModel>('purchaseBox');
    await Hive.openBox('openingStockBox');
    await Hive.openBox<AssetModel>('assets');
    await Hive.openBox<LiabilityModel>('liabilities');
    await Hive.openBox<BudgetModel>('budgets');
  }
}
