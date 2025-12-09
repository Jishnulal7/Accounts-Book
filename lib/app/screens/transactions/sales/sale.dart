import 'package:account_book/app/data/helpers/enums/toast.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/providers/transaction_provider.dart';
import 'package:account_book/app/screens/transactions/components/edit_selected_item.dart';
import 'package:account_book/app/screens/transactions/export.dart';
import 'package:intl/intl.dart';

class SalesTransaction extends StatefulWidget {
  final SalesType salesType;
  final ItemSelectionModel? itemSelection;
  final VoidCallback? onItemAdded;
  final bool useNewProvider;
  final bool isDrawer;
  const SalesTransaction({
    super.key,
    required this.salesType,
    this.itemSelection,
    this.onItemAdded,
    this.useNewProvider = true,
    required this.isDrawer,
  });

  @override
  State<SalesTransaction> createState() => _SalesTransactionState();
}

class _SalesTransactionState extends State<SalesTransaction> {
  late TransactionProvider _transactionProvider;
  bool _showPreviousDataOption = false;
  @override
  void initState() {
    super.initState();
    if (widget.useNewProvider) {
      _transactionProvider = TransactionProvider();
      _transactionProvider.setTransactionType(TransactionType.sale);
      _transactionProvider.setSalesType(widget.salesType);

      // Wait for Hive to initialize and then reset
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _transactionProvider.initializeLastNumbers();
        _transactionProvider.resetForNewTransaction();
      });

      _checkForPreviousTransactions();
    }
  }

  Future<void> _checkForPreviousTransactions() async {
    final recentSales = await _getRecentSales(widget.salesType);
    setState(() {
      _showPreviousDataOption = recentSales.isNotEmpty;
    });
  }

  Future<List<SaleModel>> _getRecentSales(SalesType salesType) async {
    final transactionProvider = TransactionProvider();
    final allSales = await transactionProvider.getAllSales();

    // Filter sales by the provided salesType
    final filteredSales =
        allSales.where((sale) => sale.type == salesType).toList();

    // Sort by date, most recent first
    filteredSales.sort((a, b) => b.date.compareTo(a.date));

    // Return up to 5 recent sales
    return filteredSales.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    final isLargeScreen = MediaQuery.of(context).size.width >= 1200;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return ChangeNotifierProvider(
      create: (_) => widget.useNewProvider
          ? _transactionProvider
          : Provider.of<TransactionProvider>(context, listen: false),
      child: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final partyProvider = Provider.of<PartyProvider>(context);

          return Scaffold(
            appBar: AppBar(
              title: Text(_getTitle(widget.salesType)),
              actions: [
                if (_showPreviousDataOption)
                  _buildPreviousDataButton(context, currencySymbol),
              ],
            ),
            bottomNavigationBar:
                _buildBottomNavBar(context, provider, widget.salesType),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (isLargeScreen) {
                    return _buildWideLayout(
                        context, provider, partyProvider, currencySymbol);
                  } else if (isTablet) {
                    return _buildTabletLayout(
                        context, provider, partyProvider, currencySymbol);
                  } else {
                    return _buildMobileLayout(
                        context, provider, partyProvider, currencySymbol);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    TransactionProvider provider,
    PartyProvider partyProvider,
    String currencySymbol,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildInvoiceSection(context, provider, partyProvider,
                  widget.salesType, currencySymbol),
              const SizedBox(height: 24),
              _buildPartySearchSection(context, provider),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: provider.saleKey,
              child: Column(
                children: [
                  _buildItemsSection(context, provider, currencySymbol),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    TransactionProvider provider,
    PartyProvider partyProvider,
    String currencySymbol,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: provider.saleKey,
        child: Column(
          children: [
            _buildInvoiceSection(context, provider, partyProvider,
                widget.salesType, currencySymbol),
            const SizedBox(height: 16),
            _buildPartySearchSection(context, provider),
            const SizedBox(height: 16),
            _buildItemsSection(context, provider, currencySymbol),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    TransactionProvider provider,
    PartyProvider partyProvider,
    String currencySymbol,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: provider.saleKey,
        child: Column(
          children: [
            _buildInvoiceSection(context, provider, partyProvider,
                widget.salesType, currencySymbol),
            const SizedBox(height: 12),
            _buildPartySearchSection(context, provider),
            const SizedBox(height: 12),
            _buildItemsSection(context, provider, currencySymbol),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousDataButton(BuildContext context, String currencySymbol) {
    return IconButton(
      icon: const Icon(Icons.history),
      tooltip: 'Use previous transaction data',
      onPressed: () => _showPreviousTransactionsDialog(context, currencySymbol),
    );
  }

  Future<void> _showPreviousTransactionsDialog(
      BuildContext context, String currencySymbol) async {
    final recentSales = await _getRecentSales(widget.salesType);

    if (!context.mounted) return;

    final result = await showDialog<SaleModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recent Transactions'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: recentSales.length,
            itemBuilder: (context, index) {
              final sale = recentSales[index];
              return ListTile(
                title: Text(sale.partyName),
                subtitle: Text(
                  '${_getTitle(sale.type)}: ${sale.invoiceNumber} - $currencySymbol ${sale.totalAmount.toStringAsFixed(2)}',
                ),
                trailing: Text(DateFormat('dd MMM y').format(sale.date)),
                onTap: () => Navigator.pop(context, sale),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      // Navigate to a new sales transaction with the selected data
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      _populateProviderWithSaleData(provider, result);

      // Show confirmation toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Loaded data from ${_getTitle(provider.salesType)} #${result.invoiceNumber}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToEditItemPage(
      BuildContext context, ItemSelectionModel item, int index) async {
    if (Platform.isAndroid) {
    } else {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: Provider.of<TransactionProvider>(context, listen: false),
            child: EditSelectedItemDialog(item: item, index: index),
          ),
        ),
      );
      if (result != null && result is ItemSelectionModel) {
        if (!context.mounted) return;
        Provider.of<TransactionProvider>(context, listen: false)
            .updateSelectedItem(index, result);
      }
    }
  }

  void _populateProviderWithSaleData(
      TransactionProvider provider, SaleModel sale) {
    // Clear current data first
    provider.clearAllFields();

    // Populate with selected sale data
    provider.partyNamecontroller.text = sale.partyName;
    provider.onSelectParty(PartyModel(
        name: sale.partyName, id: sale.partyId, date: DateTime.now()));
    provider.totalController.text = sale.totalAmount.toStringAsFixed(2);
    provider.receivedAmountController.text = '0.00';
    provider.balanceController.text = sale.totalAmount.toStringAsFixed(2);
    provider.addItems(sale.item);

    provider.setPaymentType(sale.paymentType!);
    provider.setStateOfSupply(sale.stateOfSupply!);

    // Populate charges
    provider.shippingChargeController.text =
        sale.shippingCharges!.toStringAsFixed(2);
    provider.packagingChargeController.text =
        sale.packingCharges!.toStringAsFixed(2);
    provider.additionalChargeController.text =
        sale.additionalCharges!.toStringAsFixed(2);
    provider.discountController.text = sale.discounts!.toStringAsFixed(2);

    // Update transportation details if available
    if (sale.transportaionDetails!.isNotEmpty) {
      provider.updateTransportationDetails(sale.transportaionDetails!);
    }

    // Update UI
    provider.refresh();
  }

  String _getTitle(SalesType salesType) {
    switch (salesType) {
      case SalesType.sale:
        return 'Sale';
      case SalesType.estimation:
        return 'Estimate / Quotation';
      case SalesType.proforma:
        return 'Proforma';
      case SalesType.salesReturn:
        return 'Sales Return';
      case SalesType.salesOrder:
        return 'Sales Order';
      default:
        return 'Sales';
    }
  }

  Widget _buildBottomNavBar(
      BuildContext context, TransactionProvider provider, SalesType salesType) {
    return BottomNavButtons(
      onSaveAndNew: () {
        final partyProvider =
            Provider.of<PartyProvider>(context, listen: false);
        final itemProvider = context.read<ItemProvider>();
        provider.onSaveAndNew(
          partyProvider: partyProvider,
          itemProvider: itemProvider,
          context: context,
        );
        provider.resetForNewTransaction();
        widget.onItemAdded?.call();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        if (salesType == SalesType.sale ||
            salesType == SalesType.salesReturn ||
            salesType == SalesType.salesOrder ||
            salesType == SalesType.proforma ||
            salesType == SalesType.estimation) {
          itemProvider.fetchItems();
        }
      },
      onSave: () async {
        try {
          final partyProvider =
              Provider.of<PartyProvider>(context, listen: false);
          final itemProvider =
              Provider.of<ItemProvider>(context, listen: false);

          final result =
              await _saveSale(provider, partyProvider, itemProvider, salesType);

          if (result != null) {
            provider.resetForNewTransaction();
            widget.onItemAdded?.call();

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction saved successfully'),
                duration: Duration(seconds: 2),
              ),
            );
            if (widget.isDrawer) {
            } else {
              Navigator.pop(context, result);
            }

            if (salesType == SalesType.sale ||
                salesType == SalesType.salesReturn ||
                salesType == SalesType.salesOrder ||
                salesType == SalesType.proforma ||
                salesType == SalesType.estimation) {
              itemProvider.fetchItems();
            }
          }
        } catch (e) {
          ToastService.show(
            context,
            message: e.toString(),
            type: ToastType.error,
          );
        }
      },
      saveText: 'Save & New',
    );
  }

  Future<SaleModel?> _saveSale(
      TransactionProvider provider,
      PartyProvider partyProvider,
      ItemProvider itemProvider,
      SalesType salesType) async {
    switch (salesType) {
      case SalesType.sale:
        return provider.onSaveSale(partyProvider, itemProvider);
      case SalesType.estimation:
        return provider.onSaveSalesEstimate(partyProvider, itemProvider);
      case SalesType.proforma:
        return provider.onSaveProforma(partyProvider, itemProvider);
      case SalesType.salesReturn:
        return provider.onSaveSalesReturn(partyProvider, itemProvider);
      case SalesType.salesOrder:
        return provider.onSaveSalesOrder(partyProvider, itemProvider);
      default:
        return null;
    }
  }

  Widget _buildInvoiceSection(
      BuildContext context,
      TransactionProvider provider,
      PartyProvider party,
      SalesType salesType,
      String currencySymbol) {
    final balance = party.calculatePartyBalance(provider.selectedPartyName);
    return Column(
      children: [
        InvoiceInfo(
          invoiceNumber: provider.invoiceNumber,
          invoiceDate: provider.invoiceDate,
          onEditInvoice:
              (newInvoiceNumber, newInvoiceDate, prefixType, customPrefix) =>
                  _editInvoice(context, provider, prefixType, newInvoiceNumber,
                      newInvoiceDate),
          transactionType: TransactionType.sale,
          transactionSubtype: salesType,
          prefixType: provider.prefixType,
          customPrefix: provider.customPrefix,
        ),
        const Divider(),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
              'Party Balance : $currencySymbol  ${balance.toStringAsFixed(2)}'),
        ),
      ],
    );
  }

  Widget _buildPartySearchSection(
    BuildContext context,
    TransactionProvider provider,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PartySearchField(
              controller: provider.partyNamecontroller,
              focusNode: provider.focusNode,
              onChanged: (value) {
                provider.textFieldFocusChange();
                // Trigger search when text changes
                provider.refresh();
              },
              onEditingComplete: provider.textFieldFocusChange,
              showResultsImmediately:
                  true, // This will show all parties when focused
            ),
            if (provider.isTextFieldFocused ||
                provider.partyNamecontroller.text.isEmpty)
              PartySearchResults(
                future: provider.partyNamecontroller.text.isEmpty
                    ? provider.getAllParties()
                    : provider
                        .searchPartyByName(provider.partyNamecontroller.text),
                controller: provider.partyNamecontroller,
                onSelectParty: provider.onSelectParty,
                focusNode: provider.focusNode,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(
    BuildContext context,
    TransactionProvider provider,
    String currencySymbol,
  ) {
    final width = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (provider.selectedItems.isNotEmpty) ...[
                  _buildItemList(context, provider),
                  const SizedBox(height: 16),
                  _buildTotalsSummary(provider, currencySymbol),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await ItemSelectionDialog.show(
                        context,
                        partyName: provider.partyNamecontroller.text,
                        selectedItems: List<ItemSelectionModel>.from(
                            provider.selectedItems),
                      );
                      if (result != null) {
                        provider.addItems(result);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Items'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (provider.selectedItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildChargesSection(provider),
          const SizedBox(height: 16),
          _buildTotalAmountSection(provider, width, currencySymbol),
          const SizedBox(height: 16),
          _buildAdditionalDetailsSection(provider),
        ],
      ],
    );
  }

  Widget _buildItemList(BuildContext context, TransactionProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.selectedItems.length,
      itemBuilder: (context, index) {
        final item = provider.selectedItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          child: InkWell(
            onTap: () => _navigateToEditItemPage(context, item, index),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(child: ItemCard(itemSelections: [item])),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => provider.removeSelectedItem(index),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChargesSection(TransactionProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ChargesWidget(
              shippingChargeController: provider.shippingChargeController,
              additionalChargeController: provider.additionalChargeController,
              packagingChargeController: provider.packagingChargeController,
              discountController: provider.discountController,
              onChargesUpdated: () {},
            ),
            Row(
              children: [
                Checkbox(
                  value: provider.isRoundedOff,
                  onChanged: (value) => provider.setRoundedOff(value!),
                ),
                const Text('Round Off'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAmountSection(
      TransactionProvider provider, double width, String currencySymbol) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TransactionAmountSection(
          width: width,
          totalController: provider.totalController,
          receivedAmountController: provider.receivedAmountController,
          balanceController: provider.balanceController,
          provider: provider,
          currencySymbol: currencySymbol,
        ),
      ),
    );
  }

  Widget _buildAdditionalDetailsSection(TransactionProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (provider.totalController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              SupplyStateDetails(
                onStateChange: (value) => provider.setStateOfSupply(value!),
                stateOfSupply: provider.stateOfSupply,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TransportationDetails(
                  transportationNameController:
                      provider.transportationNameController,
                  vehicleNumberController: provider.vehicleNumberController,
                  deliveryDateController: provider.deliveryDateController,
                  deliveryLocationController:
                      provider.deliveryLocationController,
                  transportationDetails: provider.transportationDetails,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsSummary(
      TransactionProvider provider, String currencySymbol) {
    final textStyle = const TextStyle(fontSize: 14);
    return Card(
      elevation: 1,
      color: Theme.of(context).cardColor.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Disc: $currencySymbol ${provider.calculateTotalDiscount().toStringAsFixed(2)}',
                  style: textStyle,
                ),
                Text(
                  'Total Tax Amount: $currencySymbol ${provider.calculateTotalTaxAmount().toStringAsFixed(2)}',
                  style: textStyle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Qty: ${provider.calculateTotalQuantity().toStringAsFixed(1)}',
                  style: textStyle,
                ),
                Text(
                  'Sub Total: $currencySymbol ${provider.calculateTotalSubTotal().toStringAsFixed(2)}',
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editInvoice(
      BuildContext context,
      TransactionProvider provider,
      PrefixType newPrefixType,
      String currentInvoiceNumber,
      DateTime currentInvoiceDate) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => InvoiceBottomSheet(
        dateController: provider.dateController,
        invoiceDate: currentInvoiceDate,
        initialInvoiceNumber: currentInvoiceNumber,
        initialPrefixType: provider.prefixType,
        initialCustomPrefix: provider.customPrefix,
        onSave: (updatedInvoiceNumber, updatedDate, prefixType, customPrefix) {
          provider.editInvoice(
            updatedInvoiceNumber,
            updatedDate,
            prefixType,
            customPrefix,
          );
        },
        onDateChanged: (updatedDate) {
          provider.dateController.text =
              DateFormat('dd MMM y').format(updatedDate);
        },
      ),
    );

    if (result != null) {
      provider.editInvoice(
        result['invoiceNumber'] ?? currentInvoiceNumber,
        result['invoiceDate'] ?? currentInvoiceDate,
        result['prefixType'] ?? newPrefixType,
        result['customPrefix'] ?? provider.customPrefix,
      );
    }
  }
}
