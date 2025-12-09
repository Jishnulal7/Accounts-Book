import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/providers/edit_transaction_provider.dart';
import 'package:account_book/app/screens/transactions/components/edit_selected_item.dart';
import 'package:account_book/app/screens/transactions/export.dart';
import 'package:intl/intl.dart';

class EditSaleTransaction extends StatefulWidget {
  final SaleModel sale;
  final VoidCallback onSaleDeleted;
  final VoidCallback onSaleUpdated;
  const EditSaleTransaction({
    super.key,
    required this.sale,
    required this.onSaleDeleted,
    required this.onSaleUpdated,
  });

  @override
  State<EditSaleTransaction> createState() => _EditSaleTransactionState();
}

class _EditSaleTransactionState extends State<EditSaleTransaction>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    final isLargeScreen = MediaQuery.of(context).size.width >= 1200;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return FutureBuilder(
      future: Future.microtask(
          () => EditTransactionProvider(widget.sale, TransactionType.sale)),
      builder: (context, snapshot) {
        return ChangeNotifierProvider(
          create: (_) =>
              EditTransactionProvider(widget.sale, TransactionType.sale),
          child: Consumer<EditTransactionProvider>(
            builder: (context, provider, _) {
              final itemProvider = Provider.of<ItemProvider>(context);

              return Scaffold(
                appBar: AppBar(
                  title: Text('Edit ${_getSales(widget.sale.type)}'),
                ),
                bottomNavigationBar: BottomNavButtons(
                  onSaveAndNew: () => provider.onDelete(
                      context, widget.onSaleDeleted, itemProvider),
                  onSave: () => provider.onSave(
                      context, widget.onSaleUpdated, itemProvider),
                  saveText: 'Delete',
                ),
                body: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (isLargeScreen) {
                        return _buildWideLayout(
                            context, provider, currencySymbol, itemProvider);
                      } else if (isTablet) {
                        return _buildTabletLayout(
                            context, provider, currencySymbol, itemProvider);
                      } else {
                        return _buildMobileLayout(
                            context, provider, currencySymbol, itemProvider);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    EditTransactionProvider provider,
    String currencySymbol,
    ItemProvider itemProvider,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - Invoice and party info (non-scrollable)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildInvoiceSection(context, provider, currencySymbol),
              const SizedBox(height: 24),
              _buildPartySearchSection(context, provider),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right column - Items and details (scrollable)
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: provider.billKey,
              child: Column(
                children: [
                  _buildItemsSection(
                      context, provider, currencySymbol, itemProvider),
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
    EditTransactionProvider provider,
    String currencySymbol,
    ItemProvider itemProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: provider.billKey,
        child: Column(
          children: [
            _buildInvoiceSection(context, provider, currencySymbol),
            const SizedBox(height: 16),
            _buildPartySearchSection(context, provider),
            const SizedBox(height: 16),
            _buildItemsSection(context, provider, currencySymbol, itemProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    EditTransactionProvider provider,
    String currencySymbol,
    ItemProvider itemProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: provider.billKey,
        child: Column(
          children: [
            _buildInvoiceSection(context, provider, currencySymbol),
            const SizedBox(height: 12),
            _buildPartySearchSection(context, provider),
            const SizedBox(height: 12),
            _buildItemsSection(context, provider, currencySymbol, itemProvider),
          ],
        ),
      ),
    );
  }

// In _buildInvoiceSection method of edit_sale.dart
  Widget _buildInvoiceSection(BuildContext context,
      EditTransactionProvider provider, String currencySymbol) {
    return Column(
      children: [
        InvoiceInfo(
          invoiceNumber: provider.invoiceNumber,
          invoiceDate: provider.invoiceDate,
          onEditInvoice:
              (newInvoiceNumber, newInvoiceDate, prefixType, customPrefix) =>
                  _editInvoice(
            context,
            provider,
            prefixType,
            newInvoiceNumber,
            newInvoiceDate,
          ),
          transactionType: TransactionType.sale,
          transactionSubtype: widget.sale.type,
          prefixType: provider.prefixType,
          customPrefix: provider.customPrefix,
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildPartySearchSection(
    BuildContext context,
    EditTransactionProvider provider,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PartySearchField(
              controller: provider.controller,
              focusNode: provider.focusNode,
              onChanged: (value) {
                provider.textFieldFocusChange();
              },
              onEditingComplete: provider.textFieldFocusChange,
            ),
            if (provider.isTextFieldFocused || provider.controller.text.isEmpty)
              PartySearchResults(
                future: provider.controller.text.isEmpty
                    ? provider.getAllParties()
                    : provider.searchPartyByName(provider.controller.text),
                controller: provider.controller,
                onSelectParty: provider.selectParty,
                focusNode: provider.focusNode,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(
    BuildContext context,
    EditTransactionProvider provider,
    String currencySymbol,
    ItemProvider itemProvider,
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
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemSelectionDialog(
                            partyName: provider.controller.text,
                            selectedItems: List<ItemSelectionModel>.from(
                                provider.selectedItems),
                          ),
                        ),
                      );

                      if (result != null &&
                          result is List<ItemSelectionModel>) {
                        provider.updateSelectedItems(result);
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

  Widget _buildItemList(
      BuildContext context, EditTransactionProvider provider) {
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
            onTap: () =>
                _navigateToEditItemPage(context, item, index, provider),
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

  void _navigateToEditItemPage(BuildContext context, ItemSelectionModel item,
      int index, EditTransactionProvider provider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSelectedItemDialog(
          item: item,
          index: index,
        ),
      ),
    );

    if (result != null && result is ItemSelectionModel) {
      provider.updateSelectedItem(index, result);
    }
  }

  Widget _buildChargesSection(EditTransactionProvider provider) {
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
              onChargesUpdated: () => provider.updateTotalAmount(),
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
      EditTransactionProvider provider, double width, String currencySymbol) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TransactionAmountSection(
          width: width,
          totalController: provider.totalController,
          receivedAmountController: provider.amountController,
          balanceController: provider.balanceController,
          provider: provider,
          currencySymbol: currencySymbol,
        ),
      ),
    );
  }

  Widget _buildAdditionalDetailsSection(EditTransactionProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (provider.totalController.text.isNotEmpty) ...[
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
                  transportationDetails: provider.getTransportationDetails,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsSummary(
      EditTransactionProvider provider, String currencySymbol) {
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
      EditTransactionProvider provider,
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
        result['invoiceNumber'],
        result['invoiceDate'],
        result['prefixType'],
        result['customPrefix'],
      );
    }
  }
}

String _getSales(dynamic transactionSubtype) {
  switch (transactionSubtype) {
    case SalesType.sale:
      return 'Sales Invoice';
    case SalesType.salesReturn:
      return 'Sales Return';
    case SalesType.estimation:
      return 'Estimate';
    case SalesType.deliveryChallan:
      return 'Delivery Challan';
    case SalesType.proforma:
      return 'Proforma';
    case SalesType.salesOrder:
      return 'Sales Order';
    default:
      return 'Invoice';
  }
}
