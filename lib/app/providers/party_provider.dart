import 'package:account_book/app/data/constants/party_utils.dart';
import 'package:account_book/app/data/model/payment_record.dart';
import 'package:account_book/app/data/model/purchase_model.dart';
import 'package:account_book/app/data/model/sale_model.dart';
import 'package:flutter/material.dart';
import 'package:account_book/app/data/model/party_model.dart';
import 'package:hive_ce/hive.dart';

class PartyProvider extends ChangeNotifier {
  List<PartyModel> _partyList = [];
  Box<PartyModel>? _box;
  Box<PurchaseModel>? _purchaseBox;
  Box<SaleModel>? _saleBox;
  List<PartyModel> get partyList => _partyList;
  List<dynamic> transactions = [];

  Future<void> openBox() async {
    _box = await Hive.openBox<PartyModel>('partyBox');
    _purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
    _saleBox = await Hive.openBox<SaleModel>('saleBox');
    fetchParties();
  }

  fetchParties() {
    _partyList = _box?.values.toList() ?? [];
    notifyListeners();
  }

  Future<void> updateTransaction(dynamic transaction) async {
    if (transaction is SaleModel) {
      await _saleBox?.put(transaction.id, transaction);
    } else if (transaction is PurchaseModel) {
      await _purchaseBox?.put(transaction.id, transaction);
    }

    // Refresh the transactions if we know the party name
    if (transaction.partyName != null) {
      fetchPartyTransactions(transaction.partyName!);

      // Update the party balance after updating the transaction
      final party = getPartyByName(transaction.partyName!);
      if (party != null) {
        updatePartyBalance(party.id!);
      }
    }
  }

  Future<void> addParty(PartyModel party) async {
    // Make sure the ID is a valid UUID before putting it into the box
    final validId = PartyIdUtils.fetchPartyId(party);
    await _box?.put(validId, party);
    fetchParties();
  }

  PartyModel? getPartyByName(String name) {
    if (name.isEmpty) return null;

    try {
      final cleanName = name.trim().toLowerCase();

      // Check in memory cache first
      for (final party in _partyList) {
        if (party.name?.trim().toLowerCase() == cleanName) {
          return party;
        }
      }

      // If not in memory, check Hive box
      if (_box != null) {
        for (final party in _box!.values) {
          if (party.name?.trim().toLowerCase() == cleanName) {
            return party;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error finding party by name: $e');
      return null;
    }
  }

  Future<void> updateParty(PartyModel party) async {
    // First, check if the party name has changed
    final oldParty = getPartyById(party.id!);

    // Update the party in the party box
    await _box?.put(party.id, party);

    // If the party name has changed, update related transactions
    if (oldParty != null && oldParty.name != party.name) {
      // Update purchases
      final purchasesToUpdate = _purchaseBox?.values
          .where((purchase) => purchase.partyName == oldParty.name)
          .toList();

      purchasesToUpdate?.forEach((purchase) {
        purchase.partyName = party.name ?? '';
        _purchaseBox?.put(purchase.key, purchase);
      });

      // Update sales
      final salesToUpdate = _saleBox?.values
          .where((sale) => sale.partyName == oldParty.name)
          .toList();

      salesToUpdate?.forEach((sale) {
        sale.partyName = party.name ?? '';
        _saleBox?.put(sale.key, sale);
      });
    }

    fetchParties();
  }

  // New method to check if party has transactions
  bool hasPartyTransactions(String partyName) {
    // Check for purchase transactions
    final hasPurchases = _purchaseBox?.values
            .any((purchase) => purchase.partyName == partyName) ??
        false;

    // Check for sale transactions
    final hasSales =
        _saleBox?.values.any((sale) => sale.partyName == partyName) ?? false;

    return hasPurchases || hasSales;
  }

  // Updated deleteParty method with transaction check
  Future<bool> deleteParty(String partyId) async {
    final party = getPartyById(partyId);
    if (party == null) return true; // Party not found, consider it deleted

    // Check if party has transactions
    if (hasPartyTransactions(party.name ?? '')) {
      return false; // Cannot delete party with transactions
    }

    // Proceed with deletion if no transactions exist
    await _box?.delete(partyId);
    fetchParties();
    return true;
  }

  PartyModel? getPartyById(String id) {
    try {
      return _partyList.firstWhere((party) => party.id == id);
    } catch (e) {
      return null;
    }
  }

  fetchPartyTransactions(String partyName) {
    // Combine all relevant transactions in one query
    final allPurchases = _purchaseBox?.values
            .where((purchase) => purchase.partyName == partyName)
            .toList() ??
        [];

    final allSales = _saleBox?.values
            .where((sale) => sale.partyName == partyName)
            .toList() ??
        [];

    transactions = [...allPurchases, ...allSales]
      ..sort((a, b) => b.date.compareTo(a.date));

    notifyListeners();
  }

  double calculatePartyBalance(String partyName) {
    double balance = 0;

    final purchases = _purchaseBox?.values
            .where((purchase) =>
                purchase.partyName == partyName &&
                purchase.type == PurchaseType.purchase)
            .toList() ??
        [];

    final sales = _saleBox?.values
            .where((sale) =>
                sale.partyName == partyName && sale.type == SalesType.sale)
            .toList() ??
        [];

    // Calculate purchase balances
    for (var purchase in purchases) {
      balance -= purchase.totalAmount;

      // Use paymentHistory if available, otherwise fall back to paidAmount
      if (purchase.paymentHistory != null &&
          purchase.paymentHistory!.isNotEmpty) {
        for (var payment in purchase.paymentHistory!) {
          balance += payment.amount;
        }
      } else if (purchase.paidAmount != null) {
        balance += purchase.paidAmount!;
      }
    }

    // Calculate sale balances
    for (var sale in sales) {
      balance += sale.totalAmount;

      // Use paymentHistory if available, otherwise fall back to receivedAmount
      if (sale.paymentHistory != null && sale.paymentHistory!.isNotEmpty) {
        for (var payment in sale.paymentHistory!) {
          balance -= payment.amount;
        }
      } else if (sale.receivedAmount != null) {
        balance -= sale.receivedAmount!;
      }
    }

    // Consider purchase returns
    final purchaseReturns = _purchaseBox?.values
            .where((purchase) =>
                purchase.partyName == partyName &&
                purchase.type == PurchaseType.purchaseReturn)
            .toList() ??
        [];

    for (var purchaseReturn in purchaseReturns) {
      balance += purchaseReturn.totalAmount;

      if (purchaseReturn.paymentHistory != null &&
          purchaseReturn.paymentHistory!.isNotEmpty) {
        for (var payment in purchaseReturn.paymentHistory!) {
          balance -= payment.amount;
        }
      } else if (purchaseReturn.paidAmount != null) {
        balance -= purchaseReturn.paidAmount!;
      }
    }

    // Consider sale returns
    final saleReturns = _saleBox?.values
            .where((sale) =>
                sale.partyName == partyName &&
                sale.type == SalesType.salesReturn)
            .toList() ??
        [];

    for (var saleReturn in saleReturns) {
      balance -= saleReturn.totalAmount;

      if (saleReturn.paymentHistory != null &&
          saleReturn.paymentHistory!.isNotEmpty) {
        for (var payment in saleReturn.paymentHistory!) {
          balance += payment.amount;
        }
      } else if (saleReturn.receivedAmount != null) {
        balance += saleReturn.receivedAmount!;
      }
    }

    return balance;
  }

  Future<void> updatePartyBalance(String partyId) async {
    final party = getPartyById(partyId);
    if (party != null) {
      final balance = calculatePartyBalance(party.name ?? '');
      party.openingBalance = balance;
      await updateParty(party);
    }
  }

  Future<void> recordPaymentAndUpdateBalance({
    required String partyName,
    required double amount,
    required bool isReceived,
    required String transactionId,
    required DateTime paymentDate,
    required String paymentMethod,
    String? reference,
  }) async {
    try {
      // Create payment record
      final paymentRecord = PaymentRecord(
        amount: amount,
        date: paymentDate,
        method: paymentMethod,
        reference: reference ?? 'Payment ${isReceived ? "received" : "paid"}',
      );

      // Find and update the transaction
      if (transactionId.contains('sale')) {
        final sale = _saleBox?.get(transactionId);
        if (sale != null) {
          // Update sale with new payment record
          final newReceived = (sale.receivedAmount ?? 0) + amount;
          final newBalance = sale.totalAmount - newReceived;

          // Add to payment history
          List<PaymentRecord> paymentHistory = [...(sale.paymentHistory ?? [])];
          paymentHistory.add(paymentRecord);

          final updatedSale = sale.copyWith(
            receivedAmount: newReceived,
            balanceAmount: newBalance,
            paymentHistory: paymentHistory,
          );

          await _saleBox?.put(transactionId, updatedSale);
        }
      } else if (transactionId.contains('purchase')) {
        final purchase = _purchaseBox?.get(transactionId);
        if (purchase != null) {
          // Update purchase with new payment record
          final newPaid = (purchase.paidAmount ?? 0) + amount;
          final newBalance = purchase.totalAmount - newPaid;

          // Add to payment history
          List<PaymentRecord> paymentHistory = [
            ...(purchase.paymentHistory ?? [])
          ];
          paymentHistory.add(paymentRecord);

          final updatedPurchase = purchase.copyWith(
            paidAmount: newPaid,
            balanceAmount: newBalance,
            paymentHistory: paymentHistory,
          );

          await _purchaseBox?.put(transactionId, updatedPurchase);
        }
      }

      // Update party balance
      final party = getPartyByName(partyName);
      if (party != null) {
        await updatePartyBalance(party.id!);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error recording payment: $e');
      rethrow;
    }
  }
}