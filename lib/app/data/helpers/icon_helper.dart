class CustomIcons {
  final Map<String, String> _categoryIcons = {
    'Food': 'assets/categories/fast-food.png',
    'Shopping': 'assets/categories/shopping.png',
    'Transport': 'assets/categories/taxi(2).png',
    'Bills': 'assets/categories/bill.png',
    'Fuel': 'assets/categories/fuel.png',
    'Gadgets': 'assets/categories/smartphone.png',
    'Dining': 'assets/categories/noodles.png',
    'Education': 'assets/categories/graduation.png',
    'EMI': 'assets/categories/loan.png',
    'Groceries': 'assets/categories/groceries.png',
    'Grooming': 'assets/categories/haircut.png',
    'Health': 'assets/categories/healthcare-and-medical.png',
    'Household': 'assets/categories/house.png',
    'Rent': 'assets/categories/rent.png',
    'Invest': 'assets/categories/investment.png',
    'Kids': 'assets/categories/feeding-bottle.png',
    'Leisure': 'assets/categories/sports.png',
    'Office': 'assets/categories/briefcase.png',
    'Travel': 'assets/categories/plane.png',
    'Salary': 'assets/categories/money-bag.png',
    'Rewards': 'assets/categories/gift.png',
    'Bonus': 'assets/categories/gift-card.png',
    'Subscription': 'assets/categories/subscription.png',
    'Entertainment': 'assets/categories/tickets.png',
    'Water': 'assets/categories/water-tap.png',
    'Tea': 'assets/categories/tea.png',
    'Clothing': 'assets/categories/tshirt.png',
    'Electricity': 'assets/categories/lightning-bolt.png',
  };

  final Map<String, String> _accountIcons = {
    'Bank': 'assets/categories/bank.png',
    'Savings': 'assets/categories/piggy-bank.png',
    'Card': 'assets/categories/credit-card.png',
    'Cash': 'assets/categories/cash-bill-dollar.png',
  };

  String getImagePathForCategory(String categoryName) {
    return _categoryIcons[categoryName] ?? 'assets/categories/category.png';
  }

  String getImagePathForAccounts(String accountName) {
    return _accountIcons[accountName] ?? 'assets/categories/wallet.png';
  }

  getImagePathForAttendance(String key) {}
}
