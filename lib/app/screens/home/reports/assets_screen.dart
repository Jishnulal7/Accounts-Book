import 'package:account_book/app/data/model/asset_model.dart';
import 'package:account_book/app/data/model/party_model.dart';
import 'package:account_book/app/providers/assets_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  AssetsScreenState createState() => AssetsScreenState();
}

class AssetsScreenState extends State<AssetsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();

  // Form controllers
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _purchaseDateController = TextEditingController();
  final _purchaseValueController = TextEditingController();
  final _depreciationRateController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedSupplierId;
  String? _selectedInvoiceNumber;
  String? _selectedDepreciationMethod;
  DateTime? _selectedPurchaseDate;

  @override
  void initState() {
    super.initState();
    // Load assets when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetProvider>().loadAssets();
    });

    // Listen to search text changes
    _searchController.addListener(() {
      context.read<AssetProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    _purchaseDateController.dispose();
    _purchaseValueController.dispose();
    _depreciationRateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddAssetDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildSearchBar(),
          Expanded(
            child: _buildAssetList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Consumer<AssetProvider>(
      builder: (context, assetProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text('Filter:'),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('All'),
                selected: assetProvider.filter == 'All',
                onSelected: (selected) {
                  if (selected) {
                    assetProvider.setFilter('All');
                  }
                },
              ),
              const SizedBox(width: 5),
              ChoiceChip(
                label: const Text('Fixed'),
                selected: assetProvider.filter == 'Fixed',
                onSelected: (selected) {
                  if (selected) {
                    assetProvider.setFilter('Fixed');
                  }
                },
              ),
              const SizedBox(width: 5),
              ChoiceChip(
                label: const Text('Current'),
                selected: assetProvider.filter == 'Current',
                onSelected: (selected) {
                  if (selected) {
                    assetProvider.setFilter('Current');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search assets...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetList() {
    return Consumer<AssetProvider>(
      builder: (context, assetProvider, child) {
        final filteredAssets = assetProvider.filteredAssets;

        // If no assets exist yet, show a message
        if (assetProvider.assets.isEmpty) {
          return const Center(
            child: Text(
              'No assets added yet. Click the + button to add an asset.',
              textAlign: TextAlign.center,
            ),
          );
        }

        // If no assets match the current filter/search
        if (filteredAssets.isEmpty) {
          return const Center(
            child: Text(
              'No matching assets found.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredAssets.length,
          itemBuilder: (context, index) {
            final asset = filteredAssets[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(asset.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category: ${asset.category} - ${asset.subCategory}'),
                    Text(
                        'Purchase Value: ₹${asset.purchaseValue.toStringAsFixed(2)}'),
                    if (asset.currentValue != null)
                      Text(
                          'Current Value: ₹${asset.currentValue!.toStringAsFixed(2)}'),
                    if (asset.depreciationRate != null)
                      Text(
                          'Depreciation: ${asset.depreciationRate}% (${asset.depreciationMethod})'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showAssetActions(asset),
                ),
                onTap: () => _showAssetDetails(asset),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddAssetDialog() {
    _selectedPurchaseDate = DateTime.now();
    _purchaseDateController.text =
        _selectedPurchaseDate!.toLocal().toString().split(' ')[0];

    // Clear form fields
    _nameController.clear();
    _categoryController.clear();
    _subCategoryController.clear();
    _purchaseValueController.clear();
    _depreciationRateController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _selectedDepreciationMethod = null;
    _selectedSupplierId = null;
    _selectedInvoiceNumber = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Asset'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Asset Name'),
                        validator: (value) =>
                            value!.isEmpty ? 'Required' : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: _categoryController.text.isEmpty
                            ? null
                            : _categoryController.text,
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        items: ['Fixed', 'Current', 'Intangible', 'Investment']
                            .map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _categoryController.text = value!;
                          });
                        },
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: _subCategoryController,
                        decoration:
                            const InputDecoration(labelText: 'Sub Category'),
                      ),
                      TextFormField(
                        controller: _purchaseDateController,
                        decoration:
                            const InputDecoration(labelText: 'Purchase Date'),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                _selectedPurchaseDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _selectedPurchaseDate = date;
                              _purchaseDateController.text =
                                  date.toLocal().toString().split(' ')[0];
                            });
                          }
                        },
                      ),
                      TextFormField(
                        controller: _purchaseValueController,
                        decoration:
                            const InputDecoration(labelText: 'Purchase Value'),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'Required' : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedDepreciationMethod,
                        decoration: const InputDecoration(
                            labelText: 'Depreciation Method'),
                        items: ['Straight-line', 'Written Down Value', 'None']
                            .map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedDepreciationMethod = value;
                          });
                        },
                      ),
                      if (_selectedDepreciationMethod != null &&
                          _selectedDepreciationMethod != 'None')
                        TextFormField(
                          controller: _depreciationRateController,
                          decoration: const InputDecoration(
                              labelText: 'Depreciation Rate (%)'),
                          keyboardType: TextInputType.number,
                        ),
                      TextFormField(
                        controller: _locationController,
                        decoration:
                            const InputDecoration(labelText: 'Location'),
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _saveAsset,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      final newAsset = AssetModel(
        name: _nameController.text,
        category: _categoryController.text,
        subCategory: _subCategoryController.text,
        purchaseDate: _selectedPurchaseDate!,
        purchaseValue: double.parse(_purchaseValueController.text),
        depreciationRate: _depreciationRateController.text.isNotEmpty
            ? double.parse(_depreciationRateController.text)
            : null,
        depreciationMethod: _selectedDepreciationMethod,
        location: _locationController.text,
        description: _descriptionController.text,
        supplierId: _selectedSupplierId,
        invoiceNumber: _selectedInvoiceNumber,
      );

      // Use provider to add the asset
      await context.read<AssetProvider>().addAsset(newAsset);

      Navigator.pop(context);
    }
  }

  void _showAssetDetails(AssetModel asset) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(asset.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${asset.category}'),
                Text('Sub Category: ${asset.subCategory}'),
                Text(
                    'Purchase Date: ${asset.purchaseDate.toLocal().toString().split(' ')[0]}'),
                Text(
                    'Purchase Value: ₹${asset.purchaseValue.toStringAsFixed(2)}'),
                if (asset.currentValue != null)
                  Text(
                      'Current Value: ₹${asset.currentValue!.toStringAsFixed(2)}'),
                if (asset.depreciationRate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Depreciation Rate: ${asset.depreciationRate}%'),
                      Text('Depreciation Method: ${asset.depreciationMethod}'),
                    ],
                  ),
                if (asset.location != null) Text('Location: ${asset.location}'),
                if (asset.description != null)
                  Text('Description: ${asset.description}'),
                if (asset.supplierId != null)
                  FutureBuilder<PartyModel?>(
                    future: context
                        .read<AssetProvider>()
                        .getSupplierDetails(asset.supplierId!),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text('Supplier: ${snapshot.data!.name}');
                      }
                      return const Text('Supplier: Loading...');
                    },
                  ),
                if (asset.invoiceNumber != null)
                  Text('Invoice: ${asset.invoiceNumber}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAssetActions(AssetModel asset) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Asset'),
              onTap: () {
                Navigator.pop(context);
                _editAsset(asset);
              },
            ),
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text('Record Depreciation'),
              onTap: () {
                Navigator.pop(context);
                _recordDepreciation(asset);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Dispose Asset'),
              onTap: () {
                Navigator.pop(context);
                _disposeAsset(asset);
              },
            ),
          ],
        );
      },
    );
  }

  void _editAsset(AssetModel asset) {
    // Pre-fill form with existing asset data
    _nameController.text = asset.name;
    _categoryController.text = asset.category;
    _subCategoryController.text = asset.subCategory;
    _purchaseDateController.text =
        asset.purchaseDate.toLocal().toString().split(' ')[0];
    _purchaseValueController.text = asset.purchaseValue.toString();
    _depreciationRateController.text = asset.depreciationRate?.toString() ?? '';
    _locationController.text = asset.location ?? '';
    _descriptionController.text = asset.description ?? '';
    _selectedDepreciationMethod = asset.depreciationMethod;
    _selectedSupplierId = asset.supplierId;
    _selectedInvoiceNumber = asset.invoiceNumber;
    _selectedPurchaseDate = asset.purchaseDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Asset'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Asset Name'),
                        validator: (value) =>
                            value!.isEmpty ? 'Required' : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: asset.category,
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        items: ['Fixed', 'Current', 'Intangible', 'Investment']
                            .map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _categoryController.text = value!;
                          });
                        },
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: _subCategoryController,
                        decoration:
                            const InputDecoration(labelText: 'Sub Category'),
                      ),
                      TextFormField(
                        controller: _purchaseDateController,
                        decoration:
                            const InputDecoration(labelText: 'Purchase Date'),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                _selectedPurchaseDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _selectedPurchaseDate = date;
                              _purchaseDateController.text =
                                  date.toLocal().toString().split(' ')[0];
                            });
                          }
                        },
                      ),
                      TextFormField(
                        controller: _purchaseValueController,
                        decoration:
                            const InputDecoration(labelText: 'Purchase Value'),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'Required' : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedDepreciationMethod,
                        decoration: const InputDecoration(
                            labelText: 'Depreciation Method'),
                        items: ['Straight-line', 'Written Down Value', 'None']
                            .map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedDepreciationMethod = value;
                          });
                        },
                      ),
                      if (_selectedDepreciationMethod != null &&
                          _selectedDepreciationMethod != 'None')
                        TextFormField(
                          controller: _depreciationRateController,
                          decoration: const InputDecoration(
                              labelText: 'Depreciation Rate (%)'),
                          keyboardType: TextInputType.number,
                        ),
                      TextFormField(
                        controller: _locationController,
                        decoration:
                            const InputDecoration(labelText: 'Location'),
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Create the updated asset
                      final updatedAsset = asset.copyWith(
                        name: _nameController.text,
                        category: _categoryController.text,
                        subCategory: _subCategoryController.text,
                        purchaseDate: _selectedPurchaseDate!,
                        purchaseValue:
                            double.parse(_purchaseValueController.text),
                        depreciationRate:
                            _depreciationRateController.text.isNotEmpty
                                ? double.parse(_depreciationRateController.text)
                                : null,
                        depreciationMethod: _selectedDepreciationMethod,
                        location: _locationController.text,
                        description: _descriptionController.text,
                        supplierId: _selectedSupplierId,
                        invoiceNumber: _selectedInvoiceNumber,
                      );

                      // Use provider to update the asset
                      await context
                          .read<AssetProvider>()
                          .updateAsset(updatedAsset);

                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _recordDepreciation(AssetModel asset) {
    final currentDateController = TextEditingController(
      text: DateTime.now().toLocal().toString().split(' ')[0],
    );
    final depreciationAmountController = TextEditingController();
    final notesController = TextEditingController();

    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record Depreciation'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Asset: ${asset.name}'),
                    const SizedBox(height: 16),
                    Text(
                        'Current Value: ₹${asset.currentValue?.toStringAsFixed(2) ?? asset.purchaseValue.toStringAsFixed(2)}'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: currentDateController,
                      decoration:
                          const InputDecoration(labelText: 'Depreciation Date'),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: asset.purchaseDate,
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setDialogState(() {
                            selectedDate = date;
                            currentDateController.text =
                                date.toLocal().toString().split(' ')[0];
                          });
                        }
                      },
                    ),
                    TextFormField(
                      controller: depreciationAmountController,
                      decoration: const InputDecoration(
                          labelText: 'Depreciation Amount'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (depreciationAmountController.text.isNotEmpty) {
                      final depreciationAmount =
                          double.parse(depreciationAmountController.text);

                      // Use provider to record depreciation
                      await context.read<AssetProvider>().recordDepreciation(
                            asset,
                            depreciationAmount,
                            selectedDate,
                            notesController.text,
                          );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Depreciation recorded successfully')),
                      );

                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Record'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _disposeAsset(AssetModel asset) {
    final disposalDateController = TextEditingController(
      text: DateTime.now().toLocal().toString().split(' ')[0],
    );
    final disposalValueController = TextEditingController();
    final notesController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    String? disposalMethod;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Dispose Asset'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Asset: ${asset.name}'),
                    const SizedBox(height: 16),
                    Text(
                        'Current Value: ₹${asset.currentValue?.toStringAsFixed(2) ?? asset.purchaseValue.toStringAsFixed(2)}'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: disposalDateController,
                      decoration:
                          const InputDecoration(labelText: 'Disposal Date'),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: asset.purchaseDate,
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setDialogState(() {
                            selectedDate = date;
                            disposalDateController.text =
                                date.toLocal().toString().split(' ')[0];
                          });
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: disposalMethod,
                      decoration:
                          const InputDecoration(labelText: 'Disposal Method'),
                      items: ['Sold', 'Scrapped', 'Stolen', 'Donated']
                          .map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          disposalMethod = value;
                        });
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: disposalValueController,
                      decoration: const InputDecoration(
                          labelText: 'Disposal Value (if sold)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (disposalMethod != null) {
                      final disposalValue =
                          disposalValueController.text.isNotEmpty
                              ? double.parse(disposalValueController.text)
                              : 0.0;

                      // Use provider to dispose the asset
                      await context.read<AssetProvider>().disposeAsset(
                            asset,
                            selectedDate,
                            disposalMethod!,
                            disposalValue,
                            notesController.text,
                          );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Asset disposal recorded successfully')),
                      );

                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please select a disposal method')),
                      );
                    }
                  },
                  child: const Text('Dispose'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
