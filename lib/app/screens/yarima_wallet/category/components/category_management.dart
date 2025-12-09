import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/category/components/category_helper.dart';
import 'package:flutter/material.dart';


mixin CategoryManagementMixin<T extends StatefulWidget> on State<T> {
  void showAddCategoryBottomSheet(
      BuildContext context, String title, String storageKey) {
    final categoryFormKey = GlobalKey<FormState>();
    bool showSubcategories = false;
    String newSubcategory = '';
    String newCategoryName = '';
    List<String> subcategories = [];
    String selectedIcon = '';

    final List<String> categoryIcons = [
      'assets/categories/bills.png',
      'assets/categories/candy.png',
      'assets/categories/coffee-cup.png',
      'assets/categories/cookies.png',
      'assets/categories/credit-card.png',
      'assets/categories/dress.png',
      'assets/categories/fast-food.png',
      'assets/categories/fruit.png',
      'assets/categories/gamepad.png',
      'assets/categories/gift.png',
      'assets/categories/graduation.png',
      'assets/categories/shopping-cart.png',
      'assets/categories/taxi(2).png',
      'assets/categories/tshirt.png',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                    spacing: 10,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Create New $title',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          )
                        ],
                      ),
          
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Category name is required';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                        ),
                        onChanged: (value) {
                          newCategoryName = value;
                        },
                      ),
       
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Enable Subcategories'),
                          Switch(
                            value: showSubcategories,
                            onChanged: (value) {
                              setState(() {
                                showSubcategories = value;
                                if (!value) {
                                  subcategories.clear();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (showSubcategories) ...[
                        const SizedBox(height: 10),
                        ...subcategories.map((subcategory) => ListTile(
                              title: Text(subcategory),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    subcategories.remove(subcategory);
                                  });
                                },
                              ),
                            )),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Add Subcategory',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      if (newSubcategory.isNotEmpty) {
                                        setState(() {
                                          subcategories.add(newSubcategory);
                                          newSubcategory = '';
                                        });
                                      }
                                    },
                                  ),
                                ),
                                onChanged: (value) {
                                  newSubcategory = value;
                                },
                                onFieldSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      subcategories.add(value);
                                      newSubcategory = '';
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                 
                        OutlinedButton(
                          onPressed: () {
                            if (newSubcategory.isNotEmpty) {
                              setState(() {
                                subcategories.add(newSubcategory);
                                newSubcategory = '';
                              });
                            }
                          },
                          child: const Text('Add Subcategory'),
                        ),
                      ],
              
                      ExpansionTile(
                        tilePadding: const EdgeInsets.all(0),
                        dense: true,
                        title: const Text('Select an icon for your category:'),
                        initiallyExpanded: false,
                        children: [
                          SizedBox(
                            height: 200,
                            child: GridView.builder(
                              shrinkWrap: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: categoryIcons.length,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedIcon = categoryIcons[index];
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            selectedIcon == categoryIcons[index]
                                                ? AppColor.kPurple
                                                : Colors.transparent,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        categoryIcons[index],
                                        width: 20,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                                saveCategory(newCategoryName, selectedIcon,
                                    subcategories, storageKey);
                                Navigator.of(context).pop();
                                onCategoryAdded();
                                setState(() {});
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void saveCategory(String categoryName, String icon,
      List<String> subcategories, String storageKey) {
    try {
      // Set a default icon if no icon is selected
      if (icon.isEmpty) {
        icon = 'assets/categories/category.png';
      }

      final categoryHelper = CategoryHelper();

      // Determine the transaction type based on the storageKey
      final transactionType = storageKey == 'payment_categories'
          ? TransactionType.payment
          : TransactionType.receipt;

      // Add the new category using CategoryHelper
      categoryHelper.addCategory(
        categoryName,
        icon,
        transactionType,
        subcategories: subcategories,
      );

      debugPrint(
          'Category saved: $categoryName with subcategories: $subcategories');

      // Print all categories for debugging
      final categories = transactionType == TransactionType.payment
          ? categoryHelper.paymentCategories
          : categoryHelper.receiptCategories;
      debugPrint('All categories in $storageKey: ${categories.toString()}');

      setState(() {});
    } catch (e) {
      debugPrint('Error saving category: $e');
    }
  }

  void onCategoryAdded();
}
