import 'package:account_book/app/data/model/asset_model.dart';
import 'package:account_book/app/data/model/party_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

class AssetProvider extends ChangeNotifier {
  List<AssetModel> _assets = [];
  String _filter = 'All';
  String _searchQuery = '';

  List<AssetModel> get assets => _assets;
  String get filter => _filter;
  String get searchQuery => _searchQuery;

  List<AssetModel> get filteredAssets {
    return _assets.where((asset) {
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Fixed' && asset.category == 'Fixed') ||
          (_filter == 'Current' && asset.category == 'Current');
      final matchesSearch = _searchQuery.isEmpty ||
          asset.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  // Set filter
  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Load assets from Hive
  Future<void> loadAssets() async {
    final assetBox = Hive.box<AssetModel>('assets');
    _assets = assetBox.values.toList();
    notifyListeners();
  }

  // Add a new asset
  Future<void> addAsset(AssetModel asset) async {
    final assetBox = Hive.box<AssetModel>('assets');
    await assetBox.add(asset);
    await loadAssets(); // Reload to update the list
  }

  // Update an existing asset
  Future<void> updateAsset(AssetModel asset) async {
    final assetBox = Hive.box<AssetModel>('assets');
    final assetIndex = _assets.indexWhere((a) => a.id == asset.id);

    if (assetIndex != -1) {
      await assetBox.putAt(assetIndex, asset);
      await loadAssets(); // Reload to update the list
    }
  }

  // Record depreciation for an asset
  Future<void> recordDepreciation(AssetModel asset, double depreciationAmount,
      DateTime depreciationDate, String notes) async {
    // Calculate new value
    final newCurrentValue =
        (asset.currentValue ?? asset.purchaseValue) - depreciationAmount;

    // Update asset
    asset.currentValue = newCurrentValue;
    await asset.save();

    // Create transaction record
    final transactionBox = Hive.box<TransactionModel>('transactions');
    await transactionBox.add(TransactionModel(
      id: const Uuid().v4(),
      amount: depreciationAmount,
      description: 'Depreciation for ${asset.name}',
      categoryName: 'Depreciation',
      date: depreciationDate,
      transactionType: TransactionType.payment,
      iconData: 'assets/icons/depreciation.png',
      fromAccount: 'Fixed Assets',
      fromAccountImagePath: 'assets/icons/fixed_assets.png',
      toAccount: 'Depreciation Expense',
      toAccountImagePath: 'assets/icons/expense.png',
      subCategory: asset.subCategory,
      generalCategory: 'Assets',
      generalSubCategory: asset.category,
      fromSubAccount: '',
      toSubAccount: '',
    ));

    await loadAssets(); // Reload to update the list
  }

  // Dispose an asset
  Future<void> disposeAsset(AssetModel asset, DateTime disposalDate,
      String disposalMethod, double disposalValue, String notes) async {
    // Calculate profit/loss
    final bookValue = asset.currentValue ?? asset.purchaseValue;
    final profitLoss = disposalValue - bookValue;

    // Update asset
    asset.disposalDate = disposalDate;
    asset.disposalValue = disposalValue;
    asset.isActive = false;
    await asset.save();

    // Create transaction record for disposal
    final transactionBox = Hive.box<TransactionModel>('transactions');
    await transactionBox.add(TransactionModel(
      id: const Uuid().v4(),
      amount: disposalValue,
      description: 'Disposal of ${asset.name} ($disposalMethod)',
      categoryName: 'Asset Disposal',
      date: disposalDate,
      transactionType:
          disposalValue > 0 ? TransactionType.receipt : TransactionType.payment,
      iconData: 'assets/icons/asset_disposal.png',
      fromAccount: disposalValue > 0 ? 'Cash/Bank' : 'Loss on Disposal',
      fromAccountImagePath:
          disposalValue > 0 ? 'assets/icons/cash.png' : 'assets/icons/loss.png',
      toAccount: 'Fixed Assets',
      toAccountImagePath: 'assets/icons/fixed_assets.png',
      subCategory: asset.subCategory,
      generalCategory: 'Assets',
      generalSubCategory: asset.category,
      fromSubAccount: '',
      toSubAccount: '',
    ));

    // Create transaction record for profit/loss on disposal if applicable
    if (profitLoss != 0) {
      await transactionBox.add(TransactionModel(
        id: const Uuid().v4(),
        amount: profitLoss.abs(),
        description:
            '${profitLoss > 0 ? 'Profit' : 'Loss'} on disposal of ${asset.name}',
        categoryName:
            profitLoss > 0 ? 'Profit on Disposal' : 'Loss on Disposal',
        date: disposalDate,
        transactionType:
            profitLoss > 0 ? TransactionType.receipt : TransactionType.payment,
        iconData: profitLoss > 0
            ? 'assets/icons/profit.png'
            : 'assets/icons/loss.png',
        fromAccount: profitLoss > 0 ? 'Asset Disposal' : 'Loss on Disposal',
        fromAccountImagePath: profitLoss > 0
            ? 'assets/icons/asset_disposal.png'
            : 'assets/icons/loss.png',
        toAccount: profitLoss > 0 ? 'Profit on Disposal' : 'Fixed Assets',
        toAccountImagePath: profitLoss > 0
            ? 'assets/icons/profit.png'
            : 'assets/icons/fixed_assets.png',
        subCategory: asset.subCategory,
        generalCategory: 'Assets',
        generalSubCategory: asset.category,
        fromSubAccount: '',
        toSubAccount: '',
      ));
    }

    await loadAssets(); // Reload to update the list
  }

  // Get supplier details
  Future<PartyModel?> getSupplierDetails(String supplierId) async {
    final partyBox = Hive.box<PartyModel>('parties');
    try {
      return partyBox.values.firstWhere((party) => party.id == supplierId);
    } catch (e) {
      return null;
    }
  }
}
