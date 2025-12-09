import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_helper.dart';
import 'package:account_book/app/screens/yarima_wallet/account/components/account_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive_ce/hive.dart';


class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    this.onAccountAdded,
    required this.selectedDailyDate,
  });

  final VoidCallback? onAccountAdded;
  final DateTime selectedDailyDate;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AccountHelper accountModel = AccountHelper();
  String newAccountName = '';
  final boxName = 'accounts';
  final Box<TransactionModel> transactionBox =
      Hive.box<TransactionModel>('transactions');
  final Box<AttendanceModel> attendanceBox =
      Hive.box<AttendanceModel>('attendanceBox');
  double initialAmount = 0;
  String selectedIcon = '';
  List<String> subAccounts = [];
  // Add TextEditingController
  final TextEditingController subAccountController = TextEditingController();

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed
    subAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: SpeedDial(
        label: const Text('Add Account'),
        onPress: () {
          _addAccount();
        },
        child: const Icon(Icons.account_balance_wallet_outlined),
      ),
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              AccountSection(
                transactionBox: transactionBox,
                selectedMonth: widget.selectedDailyDate,
                onAccountAdded: () {
                  setState(() {});
                },
                attendanceBox: attendanceBox,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addAccount() {
    final categoryFormKey = GlobalKey<FormState>();
    selectedIcon = '';
    bool showSubACcounts = false;
    final List<String> accountIcons = [
      'assets/categories/wallet.png',
      'assets/categories/piggy-bank.png',
      'assets/categories/bank.png',
      'assets/categories/dollar-coin.png',
      'assets/categories/rent.png',
      'assets/categories/investment.png',
      'assets/categories/cash-bill-dollar.png',
    ];
    selectedIcon = accountIcons[0];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, StateSetter setState) {
          return SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: categoryFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create New Account',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter an Account name';
                        }
                        return null;
                      },
                      decoration:
                          const InputDecoration(labelText: 'Account Name'),
                      onChanged: (value) {
                        newAccountName = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      maxLength: 9,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Opening Balance',
                        counterText: '',
                      ),
                      onChanged: (value) {
                        initialAmount = double.tryParse(value) ?? 0;
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Enable Sub Accounts'),
                        Switch(
                          value: showSubACcounts,
                          onChanged: (value) {
                            setState(() {
                              showSubACcounts = value;
                              if (!value) {
                                subAccounts.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (showSubACcounts) ...[
                      const SizedBox(height: 10),
                      ...subAccounts.map((subcategory) => ListTile(
                            title: Text(subcategory),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  subAccounts.remove(subcategory);
                                });
                              },
                            ),
                          )),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: subAccountController,
                              decoration: InputDecoration(
                                labelText: 'Add Sub Account',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    if (subAccountController.text.isNotEmpty) {
                                      setState(() {
                                        subAccounts
                                            .add(subAccountController.text);
                                        subAccountController.clear();
                                      });
                                    }
                                  },
                                ),
                              ),
                              onFieldSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  setState(() {
                                    subAccounts.add(value);
                                    subAccountController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () {
                          if (subAccountController.text.isNotEmpty) {
                            setState(() {
                              subAccounts.add(subAccountController.text);
                              subAccountController.clear();
                            });
                          }
                        },
                        child: const Text('Add Sub Accounts'),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text('Select an icon for your account:'),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: accountIcons.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedIcon = accountIcons[index];
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedIcon == accountIcons[index]
                                      ? AppColor.kPurple
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset(
                                accountIcons[index],
                                width: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            if (categoryFormKey.currentState?.validate() ??
                                false) {
                              _saveAccount(
                                newAccountName,
                                initialAmount,
                                selectedIcon,
                                subAccounts: subAccounts,
                              );
                              Navigator.of(context).pop();
                              setState(() {});
                              widget.onAccountAdded?.call();
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void _saveAccount(String accountName, double initialAmount, String icon,
      {List<String>? subAccounts}) async {
    final result = await accountModel.saveAccount(
      accountName: accountName,
      initialAmount: initialAmount,
      icon: icon,
      subAccounts: subAccounts,
    );

    if (result) {
      if (mounted) {
        setState(() {});
        widget.onAccountAdded?.call();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save account. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
