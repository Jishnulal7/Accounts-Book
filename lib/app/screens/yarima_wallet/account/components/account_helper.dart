import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/transaction_model.dart';

class AccountHelper {
  final String boxName = 'accounts';
  final GetStorage accountsBox = GetStorage('accounts');

  final allTransactionTypes = [
    TransactionType.payment,
    TransactionType.receipt,
    TransactionType.transfer,
  ];

  final List<Map<String, dynamic>> accountCategories = [
    {
      'name': 'Cash',
      'imagePath': 'assets/categories/cash-bill-dollar.png',
      'initialAmount': 0.0,
      'subAccount': [],
    },
    {
      'name': 'Card',
      'imagePath': 'assets/categories/credit-card.png',
      'initialAmount': 0.0,
      'subAccount': [],
    },
    {
      'name': 'Bank',
      'imagePath': 'assets/categories/bank.png',
      'initialAmount': 0.0,
      'subAccount': [],
    },
    {
      'name': 'Savings',
      'imagePath': 'assets/categories/piggy-bank.png',
      'initialAmount': 0.0,
      'subAccount': [],
    },
  ];

  void initializeDefaultAccounts() {
    for (var account in accountCategories) {
      if (!accountsBox.hasData(account['name'])) {
        accountsBox.write(account['name'], {
          'name': account['name'],
          'imagePath': account['imagePath'],
          'initialAmount': account['initialAmount'],
          'subAccount': List<dynamic>.from(account['subAccount'] ?? []),
        });
      } else {
        final existingData = accountsBox.read(account['name']);
        if (existingData != null && !existingData.containsKey('subAccount')) {
          existingData['subAccount'] =
              List<dynamic>.from(account['subAccount'] ?? []);
          accountsBox.write(account['name'], existingData);
        }
      }
    }
  }

  // Save a new account or update existing account
  Future<bool> saveAccount({
    required String accountName,
    required double initialAmount,
    required String icon,
    List<String>? subAccounts,
  }) async {
    try {
      if (accountName.isEmpty) {
        return false;
      }

      final accountData = {
        'name': accountName,
        'imagePath': icon,
        'initialAmount': initialAmount,
        'subAccount': subAccounts ?? [],
      };

      await accountsBox.write(accountName, accountData);
      debugPrint('Account saved: $accountName');
      debugPrint('Sub accounts saved: $subAccounts');
      return true;
    } catch (e) {
      debugPrint('Error saving account: $e');
      return false;
    }
  }

  // Edit existing account
  Future<bool> editAccount({
    required String oldAccountName,
    required String newAccountName,
    required double initialAmount,
    required String icon,
    List<String>? subAccounts,
  }) async {
    try {
      if (!accountsBox.hasData(oldAccountName)) {
        return false;
      }

      // If name is changing, we need to remove old entry and create new one
      if (oldAccountName != newAccountName) {
        await accountsBox.remove(oldAccountName);
      }

      final result = await saveAccount(
        accountName: newAccountName,
        initialAmount: initialAmount,
        icon: icon,
        subAccounts: subAccounts,
      );

      debugPrint('Account edited: $oldAccountName -> $newAccountName');
      return result;
    } catch (e) {
      debugPrint('Error editing account: $e');
      return false;
    }
  }

  // Remove account
  Future<bool> removeAccount(String accountName) async {
    try {
      if (!accountsBox.hasData(accountName)) {
        return false;
      }

      // Check if it's a default account
      if (accountCategories.any((account) => account['name'] == accountName)) {
        debugPrint('Cannot remove default account: $accountName');
        return false;
      }

      await accountsBox.remove(accountName);
      debugPrint('Account removed: $accountName');
      return true;
    } catch (e) {
      debugPrint('Error removing account: $e');
      return false;
    }
  }

  // Add a sub-account to an existing account
  Future<bool> addSubAccount({
    required String parentAccountName,
    required String subAccountName,
  }) async {
    try {
      if (!accountsBox.hasData(parentAccountName)) {
        return false;
      }

      final accountData =
          accountsBox.read(parentAccountName) as Map<String, dynamic>;
      final List<dynamic> subAccounts =
          List.from(accountData['subAccount'] ?? []);

      if (!subAccounts.contains(subAccountName)) {
        subAccounts.add(subAccountName);
        accountData['subAccount'] = subAccounts;
        await accountsBox.write(parentAccountName, accountData);
        debugPrint('Sub-account added: $subAccountName to $parentAccountName');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding sub-account: $e');
      return false;
    }
  }

  // Edit sub-account
  Future<bool> editSubAccount({
    required String parentAccountName,
    required String oldSubAccountName,
    required String newSubAccountName,
  }) async {
    try {
      if (!accountsBox.hasData(parentAccountName)) {
        return false;
      }

      final accountData =
          accountsBox.read(parentAccountName) as Map<String, dynamic>;
      final List<dynamic> subAccounts =
          List.from(accountData['subAccount'] ?? []);

      final index = subAccounts.indexOf(oldSubAccountName);
      if (index != -1) {
        subAccounts[index] = newSubAccountName;
        accountData['subAccount'] = subAccounts;
        await accountsBox.write(parentAccountName, accountData);
        debugPrint(
            'Sub-account edited: $oldSubAccountName -> $newSubAccountName in $parentAccountName');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error editing sub-account: $e');
      return false;
    }
  }

  // Remove a sub-account from an existing account
  Future<bool> removeSubAccount({
    required String parentAccountName,
    required String subAccountName,
  }) async {
    try {
      if (!accountsBox.hasData(parentAccountName)) {
        return false;
      }

      final accountData =
          accountsBox.read(parentAccountName) as Map<String, dynamic>;
      final List<dynamic> subAccounts =
          List.from(accountData['subAccount'] ?? []);

      if (subAccounts.contains(subAccountName)) {
        subAccounts.remove(subAccountName);
        accountData['subAccount'] = subAccounts;
        await accountsBox.write(parentAccountName, accountData);
        debugPrint(
            'Sub-account removed: $subAccountName from $parentAccountName');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing sub-account: $e');
      return false;
    }
  }

  // Get all accounts
  List<Map<String, dynamic>> getAllAccounts() {
    final accounts = <Map<String, dynamic>>[];
    final keys = accountsBox.getKeys();

    for (var key in keys) {
      final accountData = accountsBox.read(key);
      if (accountData != null && accountData is Map<String, dynamic>) {
        accounts.add(accountData);
      }
    }

    return accounts;
  }

  // Get account by name
  Map<String, dynamic>? getAccount(String accountName) {
    if (!accountsBox.hasData(accountName)) {
      return null;
    }
    return accountsBox.read(accountName) as Map<String, dynamic>;
  }

  // Check if account exists
  bool accountExists(String accountName) {
    return accountsBox.hasData(accountName);
  }

  // Check if sub-account exists
  bool subAccountExists({
    required String parentAccountName,
    required String subAccountName,
  }) {
    final accountData = getAccount(parentAccountName);
    if (accountData == null) return false;

    final subAccounts = List<String>.from(accountData['subAccount'] ?? []);
    return subAccounts.contains(subAccountName);
  }
}
