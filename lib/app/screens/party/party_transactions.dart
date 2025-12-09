import 'package:account_book/app/data/model/payment_record.dart';
import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/providers/transaction_provider.dart';
import 'package:account_book/app/screens/party/exports.dart';
import 'package:intl/intl.dart';

class TransactionTypesList extends StatefulWidget {
  final List<dynamic> transactions;
  final Function(dynamic, double, DateTime, String, String?) onAddPayment;
  const TransactionTypesList({
    super.key,
    required this.transactions,
    required this.onAddPayment,
  });

  @override
  State<TransactionTypesList> createState() => _TransactionTypesListState();
}

class _TransactionTypesListState extends State<TransactionTypesList> {
  final Map<String, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.transactions.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final transaction = widget.transactions[index];
        final theme = Theme.of(context);
        final isExpanded = _expandedStates[transaction.id] ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            key: Key(transaction.id),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedStates[transaction.id] = expanded;
              });
            },
            leading: _buildTransactionIcon(transaction),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getTransactionLabel(transaction),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '#${transaction.invoiceNumber}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM, yyyy').format(transaction.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currencySymbol ${transaction.totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _getAmountColor(transaction),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      transaction is SaleModel ? 'Credit' : 'Debit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              _buildTransactionDetails(transaction, currencySymbol),
              if (transaction is SaleModel)
                _buildPaymentHistorySection(transaction, currencySymbol),
              if (transaction is PurchaseModel)
                _buildPaymentHistorySection(transaction, currencySymbol),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionIcon(dynamic transaction) {
    if (transaction is SaleModel) {
      switch (transaction.type) {
        case SalesType.sale:
          return Icon(
            Icons.arrow_upward,
            color: Colors.green[600],
            size: 24,
          );
        case SalesType.salesReturn:
          return Icon(
            Icons.refresh,
            color: Colors.orange[600],
            size: 24,
          );
        case SalesType.estimation:
          return Icon(
            Icons.calculate,
            color: Colors.purple[600],
            size: 24,
          );
        case SalesType.deliveryChallan:
          return Icon(
            Icons.local_shipping,
            color: Colors.indigo[600],
            size: 24,
          );
        case SalesType.proforma:
          return Icon(
            Icons.receipt,
            color: Colors.purple[600],
            size: 24,
          );
        case SalesType.salesOrder:
          return Icon(
            Icons.receipt,
            color: Colors.purple[600],
            size: 24,
          );
      }
    } else if (transaction is PurchaseModel) {
      switch (transaction.type) {
        case PurchaseType.purchase:
          return Icon(
            Icons.arrow_downward,
            color: Colors.red[600],
            size: 24,
          );
        case PurchaseType.purchaseReturn:
          return Icon(
            Icons.refresh,
            color: Colors.orange[600],
            size: 24,
          );
        case PurchaseType.purchaseOrder:
          return Icon(
            Icons.assignment,
            color: Colors.teal[600],
            size: 24,
          );
      }
    }
    return const Icon(Icons.receipt, color: Colors.grey);
  }

  String _getTransactionLabel(dynamic transaction) {
    if (transaction is SaleModel) {
      switch (transaction.type) {
        case SalesType.sale:
          return 'Sale';
        case SalesType.salesReturn:
          return 'Sales Return';
        case SalesType.estimation:
          return 'Estimation';
        case SalesType.deliveryChallan:
          return 'Delivery Challan';
        case SalesType.proforma:
          return 'Proforma Invoice';
        case SalesType.salesOrder:
          return 'Sale Order';
      }
    } else if (transaction is PurchaseModel) {
      switch (transaction.type) {
        case PurchaseType.purchase:
          return 'Purchase';
        case PurchaseType.purchaseReturn:
          return 'Purchase Return';
        case PurchaseType.purchaseOrder:
          return 'Purchase Order';
      }
    }
    return 'Transaction';
  }

  Color _getAmountColor(dynamic transaction) {
    if (transaction is SaleModel) {
      if (transaction.type == SalesType.salesReturn) {
        return Colors.orange[700]!;
      }
      return Colors.green[700]!;
    } else if (transaction is PurchaseModel) {
      if (transaction.type == PurchaseType.purchaseReturn) {
        return Colors.orange[700]!;
      }
      return Colors.red[700]!;
    }
    return Colors.grey[700]!;
  }

  Widget _buildTransactionDetails(dynamic transaction, String currencySymbol) {
    final theme = Theme.of(context);
    final totalAmount = transaction.totalAmount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Party:', style: theme.textTheme.bodyMedium),
              Text(transaction.partyName,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount:', style: theme.textTheme.bodyMedium),
              Text('$currencySymbol ${totalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          if (transaction.paymentType != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payment Method:', style: theme.textTheme.bodyMedium),
                Text(transaction.paymentType!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentHistorySection(
      dynamic transaction, String currencySymbol) {
    final theme = Theme.of(context);
    final payments =
        (transaction.paymentHistory as List?)?.cast<PaymentRecord>() ?? [];

    // Calculate total paid amount by summing all payment records
    final totalPaid =
        payments.fold(0.0, (sum, payment) => sum + payment.amount);
    final remainingBalance = transaction.totalAmount - totalPaid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PAYMENT HISTORY',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (remainingBalance > 0)
                TextButton.icon(
                  onPressed: () => _showAddPaymentDialog(transaction),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Payment'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (payments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.payment,
                      size: 40,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No payments recorded',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                ...payments.map((payment) =>
                    _buildPaymentItem(payment, currencySymbol, transaction)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Paid:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$currencySymbol ${totalPaid.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (remainingBalance > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[100]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining Balance:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  Text(
                    '$currencySymbol ${remainingBalance.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentItem(
      PaymentRecord payment, String currencySymbol, dynamic transaction) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getPaymentMethodColor(payment.method),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getPaymentMethodIcon(payment.method),
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.method.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(payment.date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$currencySymbol ${payment.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            if (payment.reference != null && payment.reference!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        payment.reference!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.attach_money;
      case 'bank transfer':
        return Icons.account_balance;
      case 'cheque':
        return Icons.description;
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.mobile_friendly;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'bank transfer':
        return Colors.blue;
      case 'cheque':
        return Colors.purple;
      case 'card':
        return Colors.orange;
      case 'upi':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showAddPaymentDialog(dynamic transaction) async {
    // Calculate remaining balance based on payment history
    final payments =
        (transaction.paymentHistory as List?)?.cast<PaymentRecord>() ?? [];
    final totalPaid =
        payments.fold(0.0, (sum, payment) => sum + payment.amount);
    final remainingBalance = transaction.totalAmount - totalPaid;

    final amountController = TextEditingController(
      text: remainingBalance > 0 ? remainingBalance.toStringAsFixed(2) : '0.00',
    );
    final referenceController = TextEditingController();
    String selectedMethod = 'Cash';
    String? selectedBankId;
    DateTime paymentDate = DateTime.now();

    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);

    await transactionProvider.loadBankDetails();
    final bankAccounts = transactionProvider.bankAccounts;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Record Payment',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Remaining Balance: $remainingBalance',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              prefixIcon: Icon(Icons.currency_rupee_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final amount = double.tryParse(value) ?? 0;
                              if (amount <= 0) return 'Must be greater than 0';
                              if (amount > remainingBalance) {
                                return 'Exceeds balance';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedMethod,
                            items: const [
                              DropdownMenuItem(
                                  value: 'Cash', child: Text('Cash')),
                              DropdownMenuItem(
                                  value: 'Bank Transfer',
                                  child: Text('Bank Transfer')),
                              DropdownMenuItem(
                                  value: 'Cheque', child: Text('Cheque')),
                              DropdownMenuItem(
                                  value: 'Card', child: Text('Card')),
                              DropdownMenuItem(
                                  value: 'UPI', child: Text('UPI')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Payment Method',
                              prefixIcon: Icon(Icons.payment),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                selectedMethod = value!;
                                if (value != 'Bank Transfer') {
                                  selectedBankId = null;
                                }
                              });
                            },
                          ),
                          if (selectedMethod == 'Bank Transfer') ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: selectedBankId,
                              hint: const Text('Select Bank Account'),
                              items: bankAccounts
                                  .map<DropdownMenuItem<String>>((account) {
                                return DropdownMenuItem<String>(
                                  value: account['accountNumber'],
                                  child: Text(
                                      '${account['bankName']} - ${account['accountNumber']}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedBankId = value;
                                });
                              },
                              validator: (value) {
                                if (selectedMethod == 'Bank Transfer' &&
                                    value == null) {
                                  return 'Please select a bank account';
                                }
                                return null;
                              },
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                // Navigate to add bank account screen
                                // Navigator.push(context, MaterialPageRoute(builder: (context) => AddBankAccountScreen()));
                              },
                              child: const Text('+ Add New Bank Account'),
                            ),
                            if (selectedBankId != null)
                              _buildSelectedBankDetails(
                                  selectedBankId!, bankAccounts),
                          ],
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: referenceController,
                            decoration: const InputDecoration(
                              labelText: 'Reference (Optional)',
                              prefixIcon: Icon(Icons.receipt),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: paymentDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() {
                                  paymentDate = date;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Payment Date',
                                prefixIcon: Icon(Icons.calendar_today),
                                border: OutlineInputBorder(),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(DateFormat('dd MMM yyyy')
                                      .format(paymentDate)),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () {
                              final amount =
                                  double.tryParse(amountController.text) ?? 0;
                              if (amount > 0 && amount <= remainingBalance) {
                                Navigator.pop(context, {
                                  'amount': amount,
                                  'method': selectedMethod,
                                  'reference': referenceController.text,
                                  'date': paymentDate,
                                  'bankId': selectedBankId,
                                });
                              }
                            },
                            child: const Text('Record Payment'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      try {
        final amount = result['amount'] as double;
        final paymentRecord = PaymentRecord(
          amount: amount,
          date: result['date'] as DateTime,
          method: result['method'] as String,
          reference: result['reference'] as String?,
        );

        // Update the transaction's payment history
        transaction.paymentHistory =
            (transaction.paymentHistory as List?)?.cast<PaymentRecord>() ?? [];
        transaction.paymentHistory!.add(paymentRecord);

        if (transaction is SaleModel) {
          transaction.receivedAmount =
              (transaction.receivedAmount ?? 0) + amount;
          transaction.balanceAmount =
              transaction.totalAmount - transaction.receivedAmount!;
        } else if (transaction is PurchaseModel) {
          transaction.paidAmount = (transaction.paidAmount ?? 0) + amount;
          transaction.balanceAmount =
              transaction.totalAmount - transaction.paidAmount!;
        }

        // Save the updated transaction
        await partyProvider.updateTransaction(transaction);
        // await transactionProvider.recordPayment(
        //   transactionId: transaction.id!,
        //   amount: amount,
        //   paymentDate: result['date'] as DateTime,
        //   paymentMethod: result['method'] as String,
        //   reference: result['reference'] as String?,
        // );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Payment of ${amount.toStringAsFixed(2)} recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );

        partyProvider.fetchPartyTransactions(transaction.partyName);
        partyProvider.updatePartyBalance(transaction.partyId ?? '');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSelectedBankDetails(
      String accountNumber, List<Map<String, dynamic>> bankAccounts) {
    final account = bankAccounts.firstWhere(
      (acc) => acc['accountNumber'] == accountNumber,
      orElse: () => <String, String>{},
    );

    if (account.isEmpty) return const SizedBox();

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Bank Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            if (account['bankName'] != null)
              Text('Bank: ${account['bankName']}'),
            if (account['accountNumber'] != null)
              Text('Account: ${account['accountNumber']}'),
            if (account['ifscCode'] != null)
              Text('IFSC: ${account['ifscCode']}'),
            if (account['bankBranch'] != null)
              Text('Branch: ${account['bankBranch']}'),
          ],
        ),
      ),
    );
  }
}
