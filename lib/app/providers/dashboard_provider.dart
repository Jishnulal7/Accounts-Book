import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/item_model.dart';
import 'package:account_book/app/data/model/party_model.dart';
import 'package:account_book/app/data/model/task_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:account_book/app/data/model/purchase_model.dart';
import 'package:account_book/app/data/model/sale_model.dart';
import 'package:hive_ce/hive.dart';

class DashboardProvider extends ChangeNotifier {
  late Future<Box<SaleModel>> _saleBoxFuture;
  late Future<Box<PurchaseModel>> _purchaseBoxFuture;
  late Future<Box<TransactionModel>> _transactionBoxFuture;
  late Future<Box<AttendanceModel>> _attendanceBoxFuture;
  late Future<Box<TaskModel>> _taskBoxFuture;
  late Future<Box<PartyModel>> _partyBoxFuture;
  late Future<Box<ItemModel>> _itemBoxFuture;

  DashboardProvider() {
    _saleBoxFuture = Hive.openBox<SaleModel>('saleBox');
    _purchaseBoxFuture = Hive.openBox<PurchaseModel>('purchaseBox');
    _transactionBoxFuture = Hive.openBox<TransactionModel>('transactions');
    _attendanceBoxFuture = Hive.openBox<AttendanceModel>('attendanceBox');
    _taskBoxFuture = Hive.openBox<TaskModel>('tasks');
    _partyBoxFuture = Hive.openBox<PartyModel>('partyBox');
    _itemBoxFuture = Hive.openBox<ItemModel>('itemBox');
  }

  Future<List<Box<dynamic>>> getBoxes() async {
    return await Future.wait([
      _saleBoxFuture,
      _purchaseBoxFuture,
      _taskBoxFuture,
      _transactionBoxFuture,
      _attendanceBoxFuture,
      _partyBoxFuture,
      _itemBoxFuture
    ]);
  }

  Future<List<SaleModel>> getSales() async {
    final box = await _saleBoxFuture;
    return box.values.toList(); 
  }

  Future<List<PurchaseModel>> getPurchases() async {
    final box = await _purchaseBoxFuture;
    return box.values.toList(); 
  }

  Future<void> addSale(SaleModel sale) async {
    final box = await _saleBoxFuture;
    await box.add(sale);
    notifyListeners();
  }

  Future<void> addPurchase(PurchaseModel purchase) async {
    final box = await _purchaseBoxFuture;
    await box.add(purchase);
    notifyListeners();
  }

  void refreshData() {
    notifyListeners();
  }

  Future<List<PartyModel>> getParties() async {
    final box = await _partyBoxFuture;
    return box.values.toList();
  }
  Future<List<ItemModel>> getItems() async {
    final box = await _itemBoxFuture;
    return box.values.toList();
  }

  Future<PartyModel> getPartyById(String partyId) async {
    final box = await _partyBoxFuture;
    try {
      return box.values.firstWhere(
        (party) => party.id == partyId,
      );
    } catch (e) {
    
      return PartyModel();
    }
  }
  Future<ItemModel> getItemByyId(String partyId) async {
    final box = await _itemBoxFuture;
    try {
      return box.values.firstWhere(
        (party) => party.id == partyId,
      );
    } catch (e) {

      return ItemModel();
    }
  }
}
