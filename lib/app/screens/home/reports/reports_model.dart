import 'package:account_book/app/screens/home/exports.dart';
import 'package:hive_ce/hive.dart';

class ReportsService {
  // Party Reports
  Future<Map<String, dynamic>> getPartyAnalytics(
      {DateTime? startDate, DateTime? endDate}) async {
    final partyBox = await Hive.openBox<PartyModel>('partyBox');
    final parties = partyBox.values.toList();

    return {
      'totalCustomers': parties.where((p) => p.isCustomer == true).length,
      'totalSuppliers': parties.where((p) => p.isCustomer == false).length,
      'totalCreditAmount':
          parties.fold(0.0, (sum, party) => sum + (party.creditAmount ?? 0)),
      'totalOpeningBalance':
          parties.fold(0.0, (sum, party) => sum + (party.openingBalance ?? 0)),
    };
  }

  // Inventory Reports
  Future<Map<String, dynamic>> getInventoryAnalytics() async {
    final itemBox = await Hive.openBox<ItemModel>('itemBox');
    final items = itemBox.values.toList();

    return {
      'totalItems': items.length,
      'lowStockItems': items
          .where((item) =>
              item.lowStockQuantityAlert == true &&
              (item.stockQuantity ?? 0) <= (item.lowStockQuantity ?? 0))
          .toList(),
      'totalStockValue': items.fold(
          0.0,
          (sum, item) =>
              sum + ((item.amount ?? 0) * (item.stockQuantity ?? 0))),
      'itemsByCategory': _groupItemsByCategory(items),
    };
  }

  Map<String, List<ItemModel>> _groupItemsByCategory(List<ItemModel> items) {
    return items.fold<Map<String, List<ItemModel>>>({}, (map, item) {
      final category = item.itemCategory ?? 'Uncategorized';
      if (!map.containsKey(category)) {
        map[category] = [];
      }
      map[category]!.add(item);
      return map;
    });
  }

  // Sales Reports
  Future<Map<String, dynamic>> getSalesAnalytics(
      {DateTime? startDate, DateTime? endDate, SalesType? type}) async {
    final salesBox = await Hive.openBox<SaleModel>('saleBox');
    var sales = salesBox.values.toList();

    if (startDate != null) {
      sales = sales.where((sale) => sale.date.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      sales = sales.where((sale) => sale.date.isBefore(endDate)).toList();
    }
    if (type != null) {
      sales = sales.where((sale) => sale.type == type).toList();
    }

    return {
      'totalSales': sales.length,
      'totalAmount': sales.fold(0.0, (sum, sale) => sum + sale.totalAmount),
      'receivedAmount':
          sales.fold(0.0, (sum, sale) => sum + (sale.receivedAmount ?? 0)),
      'pendingAmount': sales.fold(0.0, (sum, sale) => sum + sale.balanceAmount),
      'salesByDate': _groupSalesByDate(sales),
      'salesByParty': _groupSalesByParty(sales),
    };
  }

  // Purchase Reports
  Future<Map<String, dynamic>> getPurchaseAnalytics(
      {DateTime? startDate, DateTime? endDate, PurchaseType? type}) async {
    final purchaseBox = await Hive.openBox<PurchaseModel>('purchaseBox');
    var purchases = purchaseBox.values.toList();

    if (startDate != null) {
      purchases = purchases
          .where((purchase) => purchase.date.isAfter(startDate))
          .toList();
    }
    if (endDate != null) {
      purchases = purchases
          .where((purchase) => purchase.date.isBefore(endDate))
          .toList();
    }
    if (type != null) {
      purchases = purchases.where((purchase) => purchase.type == type).toList();
    }

    return {
      'totalPurchases': purchases.length,
      'totalAmount':
          purchases.fold(0.0, (sum, purchase) => sum + purchase.totalAmount),
      'paidAmount': purchases.fold(
          0.0, (sum, purchase) => sum + (purchase.paidAmount ?? 0)),
      'pendingAmount':
          purchases.fold(0.0, (sum, purchase) => sum + purchase.balanceAmount),
      'purchasesByDate': _groupPurchasesByDate(purchases),
      'purchasesByParty': _groupPurchasesByParty(purchases),
    };
  }

  Map<DateTime, List<SaleModel>> _groupSalesByDate(List<SaleModel> sales) {
    return sales.fold<Map<DateTime, List<SaleModel>>>({}, (map, sale) {
      final date = DateTime(sale.date.year, sale.date.month, sale.date.day);
      if (!map.containsKey(date)) {
        map[date] = [];
      }
      map[date]!.add(sale);
      return map;
    });
  }

  Map<String, List<SaleModel>> _groupSalesByParty(List<SaleModel> sales) {
    return sales.fold<Map<String, List<SaleModel>>>({}, (map, sale) {
      if (!map.containsKey(sale.partyName)) {
        map[sale.partyName] = [];
      }
      map[sale.partyName]!.add(sale);
      return map;
    });
  }

  Map<DateTime, List<PurchaseModel>> _groupPurchasesByDate(
      List<PurchaseModel> purchases) {
    return purchases.fold<Map<DateTime, List<PurchaseModel>>>({},
        (map, purchase) {
      final date =
          DateTime(purchase.date.year, purchase.date.month, purchase.date.day);
      if (!map.containsKey(date)) {
        map[date] = [];
      }
      map[date]!.add(purchase);
      return map;
    });
  }

  Map<String, List<PurchaseModel>> _groupPurchasesByParty(
      List<PurchaseModel> purchases) {
    return purchases.fold<Map<String, List<PurchaseModel>>>({},
        (map, purchase) {
      if (!map.containsKey(purchase.partyName)) {
        map[purchase.partyName] = [];
      }
      map[purchase.partyName]!.add(purchase);
      return map;
    });
  }

  // Combined Financial Reports
  Future<Map<String, dynamic>> getFinancialSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final salesAnalytics =
        await getSalesAnalytics(startDate: startDate, endDate: endDate);
    final purchaseAnalytics =
        await getPurchaseAnalytics(startDate: startDate, endDate: endDate);
    final partyAnalytics = await getPartyAnalytics();
    final inventoryAnalytics = await getInventoryAnalytics();

    return {
      'totalRevenue': salesAnalytics['totalAmount'],
      'totalExpenses': purchaseAnalytics['totalAmount'],
      'grossProfit':
          salesAnalytics['totalAmount'] - purchaseAnalytics['totalAmount'],
      'pendingReceivables': salesAnalytics['pendingAmount'],
      'pendingPayables': purchaseAnalytics['pendingAmount'],
      'inventoryValue': inventoryAnalytics['totalStockValue'],
      'totalCustomerCredit': partyAnalytics['totalCreditAmount'],
    };
  }
}
