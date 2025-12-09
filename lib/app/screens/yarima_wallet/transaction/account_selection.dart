import 'package:account_book/app/data/helpers/icon_helper.dart';
import 'package:account_book/app/screens/yarima_wallet/account/account_screen.dart';
import 'package:account_book/app/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSelection extends StatefulWidget {
  const AccountSelection({
    super.key,
    required this.accounts,
    this.previouslySelectedAccount,
    required this.selectedDate,
    this.onAccountAdded,
    required this.onCategorySelected,
  });

  final List<Map<String, dynamic>> accounts;
  final String? previouslySelectedAccount;
  final DateTime selectedDate;
  final VoidCallback? onAccountAdded;
  final Function(String, String?, String) onCategorySelected;
  @override
  State<AccountSelection> createState() => _AccountSelectionState();
}

class _AccountSelectionState extends State<AccountSelection> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allAccounts = [];
  List<Map<String, dynamic>> filteredAccounts = [];
  String? lastSelectedAccount;
  String? lastSelectedSubAccount;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadLastSelectedAccounts();
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredAccounts = List.from(allAccounts);
      } else {
        filteredAccounts = allAccounts.where((account) {
          return account['name'].toString().toLowerCase().contains(query);
        }).toList();
      }
      _sortAccounts(filteredAccounts);
    });
  }

  void _loadAccounts() {
    final accountBox = GetStorage('accounts');
    final accountKeys = accountBox.getKeys()?.cast<String>() ?? [];

    debugPrint('Loading accounts...');
    for (var key in accountKeys) {
      final data = accountBox.read(key);
      debugPrint('Account: $key, Data: $data');
    }

    setState(() {
      allAccounts = [
        ...widget.accounts,
        ..._convertKeysToAccountList(accountKeys),
      ];

      // Remove duplicates while preserving sub-accounts
      allAccounts =
          allAccounts.fold<List<Map<String, dynamic>>>([], (prev, element) {
        final existingIndex =
            prev.indexWhere((e) => e['name'] == element['name']);
        if (existingIndex == -1) {
          prev.add(element);
        } else {
          // Merge sub-accounts if both have them
          final existing = prev[existingIndex];
          final existingSubAccounts =
              List<dynamic>.from(existing['subAccount'] ?? []);
          final newSubAccounts =
              List<dynamic>.from(element['subAccount'] ?? []);
          prev[existingIndex]['subAccount'] =
              <dynamic>{...existingSubAccounts, ...newSubAccounts}.toList();
        }
        return prev;
      });

      filteredAccounts = List.from(allAccounts);
      _sortAccounts(filteredAccounts);

      // Debug output
      debugPrint(
          'Loaded accounts: ${allAccounts.map((a) => '${a['name']}: ${a['subAccount']}').join(', ')}');
    });
  }

  List<Map<String, dynamic>> _convertKeysToAccountList(Iterable<String>? keys) {
    if (keys == null) return [];
    return keys.map((key) {
      final accountData = GetStorage('accounts').read(key);
      String imagePath = accountData?['imagePath'] ??
          CustomIcons().getImagePathForAccounts(key);

      // Ensure subAccount is properly extracted and converted
      List<dynamic> subAccount = [];
      if (accountData != null && accountData.containsKey('subAccount')) {
        if (accountData['subAccount'] is List) {
          subAccount = List<dynamic>.from(accountData['subAccount']);
        }
      }

      return {
        'name': key,
        'imagePath': imagePath,
        'initialAmount': accountData?['initialAmount'] ?? 0.0,
        'subAccount': subAccount
      };
    }).toList();
  }

  void _sortAccounts(List<Map<String, dynamic>> accounts) {
    accounts.sort((a, b) {
      if (a['name'] == lastSelectedAccount) return -1;
      if (b['name'] == lastSelectedAccount) return 1;
      return a['name'].toString().compareTo(b['name'].toString());
    });
  }

  Future<void> _loadLastSelectedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastSelectedAccount = prefs.getString('lastSelectedAccount');
      lastSelectedSubAccount = prefs.getString('lastSelectedSubAccount');
      _sortAccounts(filteredAccounts);
    });
  }

  Future<void> _saveLastSelectedAccounts(String account,
      [String? subAccount]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSelectedAccount', account);
    if (subAccount != null) {
      await prefs.setString('lastSelectedSubAccount', subAccount);
    } else {
      await prefs.remove('lastSelectedSubAccount');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Accounts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search accounts',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filteredAccounts.length,
              itemBuilder: (context, index) {
                return _buildAccountTile(filteredAccounts[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: CustomOutlineButton(
              onTap: () => _navigateToNewAccountsScreen(context),
              text: 'Add Account',
              iconData: Icons.add,
              height: 46,
              width: 150,
              borderRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(Map<String, dynamic> account) {
    final subAccounts = account['subAccount'] as List<dynamic>?;

    return ListTile(
      leading: Image.asset(
        account['imagePath'],
        height: 30,
        width: 30,
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
          return const Icon(Icons.account_balance_wallet);
        },
      ),
      title: Text(account['name'].toString()),
      trailing: subAccounts != null && subAccounts.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.expand_more),
              onPressed: () => _showSubcategoriesBottomSheet(context, account),
            )
          : null,
      onTap: () => _selectAccount(
          account['name'].toString(), null, account['imagePath']),
    );
  }

  void _showSubcategoriesBottomSheet(
      BuildContext context, Map<String, dynamic> account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.75,
        expand: false,
        builder: (_, scrollController) {
          return Column(
            children: [
              Container(
                height: 5,
                width: 40,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Text(
                account['name'].toString(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: (account['subAccount'] as List<dynamic>).length,
                  itemBuilder: (context, index) {
                    final subAccount = account['subAccount'][index];
                    return ListTile(
                      title: Text(subAccount.toString()),
                      onTap: () {
                        _selectAccount(
                          account['name'].toString(),
                          subAccount.toString(),
                          account['imagePath'],
                        );

                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _selectAccount(
      String accountName, String? subAccountName, String imagePath) {
    widget.onCategorySelected(accountName, subAccountName, imagePath);
    _saveLastSelectedAccounts(accountName, subAccountName);
    Navigator.pop(context);
  }

  void _navigateToNewAccountsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountScreen(
          onAccountAdded: _onAccountAdded,
          selectedDailyDate: widget.selectedDate,
        ),
      ),
    );
  }

  void _onAccountAdded() {
    _loadAccounts();
    widget.onAccountAdded?.call();
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
