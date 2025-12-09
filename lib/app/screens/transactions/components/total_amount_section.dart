import 'package:account_book/app/screens/transactions/components/payment_section.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionAmountSection<T> extends StatefulWidget {
  final double width;
  final TextEditingController totalController;
  final TextEditingController receivedAmountController;
  final TextEditingController balanceController;
  final T provider;
  final String currencySymbol;

  const TransactionAmountSection({
    super.key,
    required this.width,
    required this.totalController,
    required this.receivedAmountController,
    required this.balanceController,
    required this.provider,
    required this.currencySymbol,
  });

  @override
  TransactionAmountSectionState<T> createState() =>
      TransactionAmountSectionState<T>();
}

class TransactionAmountSectionState<T> extends State<TransactionAmountSection> {
  final _paymentFormKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();
  bool _showPaymentHistory = false;
  final List<Map<String, dynamic>> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    widget.totalController.addListener(_updateBalance);
    widget.receivedAmountController.addListener(_updateBalance);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus &&
          widget.receivedAmountController.text.isEmpty) {
        widget.receivedAmountController.text = "0.00";
        _updateBalance();
      }
    });
  }

  @override
  void dispose() {
    widget.totalController.removeListener(_updateBalance);
    widget.receivedAmountController.removeListener(_updateBalance);
    _focusNode.dispose();
    super.dispose();
  }

  void _updateBalance() {
    final totalAmount = double.tryParse(widget.totalController.text) ?? 0.0;
    final receivedAmount =
        double.tryParse(widget.receivedAmountController.text) ?? 0.0;
    final balanceAmount = totalAmount - receivedAmount;

    widget.balanceController.text = balanceAmount.toStringAsFixed(2);
    if (mounted) setState(() {});
  }

  void _handleFullyPaidChange(bool? value) {
    final provider = widget.provider as dynamic;
    provider.setFullyPaid(value ?? false);

    if (value ?? false) {
      widget.receivedAmountController.text = widget.totalController.text;
      widget.balanceController.text = "0.00";
    } else {
      if (widget.receivedAmountController.text == widget.totalController.text) {
        widget.receivedAmountController.text = "0.00";
      }
      _updateBalance();
    }
    if (mounted) setState(() {});
  }

  Widget _buildBankDetailsDisplay() {
    final provider = widget.provider as dynamic;

    // Get the selected bank account details
    final selectedBank = provider.selectedBankId != null
        ? provider.bankAccounts.firstWhere(
            (account) => account['accountNumber'] == provider.selectedBankId,
            orElse: () => <String, String>{}, // Explicitly type the empty map
          )
        : <String, String>{}; // Also type the fallback empty map

    if (provider.paymentType != 'Bank' || selectedBank.isEmpty) {
      return const SizedBox();
    }

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bank Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (selectedBank['bankName'] != null)
              Text('Bank: ${selectedBank['bankName']}'),
            if (selectedBank['accountNumber'] != null)
              Text('Account: ${selectedBank['accountNumber']}'),
            if (selectedBank['ifscCode'] != null)
              Text('IFSC: ${selectedBank['ifscCode']}'),
            if (selectedBank['bankBranch'] != null)
              Text('Branch: ${selectedBank['bankBranch']}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider as dynamic;
    final theme = Theme.of(context);
    final totalAmount = double.tryParse(widget.totalController.text) ?? 0.0;
    final receivedAmount =
        double.tryParse(widget.receivedAmountController.text) ?? 0.0;
    final balanceAmount = totalAmount - receivedAmount;
    final isFullyPaid = provider.isFullyPaid;
    final isPaid = receivedAmount > 0;

    return Column(
      children: [
        // Total Amount Section
        _buildAmountCard(
          title: 'Total Amount',
          amount: totalAmount,
          controller: widget.totalController,
          isEditable: true,
          validator: (value) {
            if (value == null || value.isEmpty) return "Required";
            if (double.tryParse(value) == null) return "Invalid amount";
            return null;
          },
        ),
        // const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              PaymentTypeSection(
                paymentType: provider.paymentType,
                onPaymentTypeChange: (value) {
                  provider.setPaymentType(value!);
                  if (value != 'Bank') {
                    provider.setSelectedBankId(null);
                  }
                },
              ),
              _buildBankDetailsDisplay(),
            ],
          ),
        ),
        // Payment Options Section
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Status Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Status',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isPaid)
                      IconButton(
                        icon: Icon(
                          _showPaymentHistory
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _showPaymentHistory = !_showPaymentHistory;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Payment Status Indicators
                Row(
                  children: [
                    _buildStatusIndicator(
                      'Pending',
                      balanceAmount > 0,
                      Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusIndicator(
                      'Paid',
                      isPaid,
                      Colors.green,
                    ),
                    // const SizedBox(width: 8),
                    // _buildStatusIndicator(
                    //   'Fully Paid',
                    //   isFullyPaid,
                    //   Colors.green.shade700,
                    // ),
                  ],
                ),
                const SizedBox(height: 12),

                // Payment Controls
                Row(
                  children: [
                    // Fully Paid Checkbox
                    Flexible(
                      child: FilterChip(
                        label: const Text('Paid'),
                        selected: isFullyPaid,
                        onSelected: _handleFullyPaidChange,
                        checkmarkColor: Colors.white,
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: isFullyPaid ? Colors.white : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Partial Payment Button
                    Flexible(
                      child: FilledButton.tonal(
                        onPressed: () => _showPaymentDialog(context),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Add Payment'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Received Amount Input
                _buildAmountInput(
                  label: 'Amount Received',
                  controller: widget.receivedAmountController,
                  focusNode: _focusNode,
                  onChanged: (value) {
                    if (provider.isFullyPaid) {
                      provider.setFullyPaid(false);
                    }
                    _updateBalance();
                  },
                ),
                const SizedBox(height: 8),

                // Balance Display
                _buildBalanceDisplay(balanceAmount),
              ],
            ),
          ),
        ),

        // Payment History Section
        if (_showPaymentHistory && _paymentHistory.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildPaymentHistory(),
          ),
      ],
    );
  }

  Widget _buildAmountCard({
    required String title,
    required double amount,
    required TextEditingController controller,
    bool isEditable = false,
    String? Function(String?)? validator,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  widget.currencySymbol,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: isEditable
                      ? TextFormField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: validator,
                        )
                      : Text(
                          NumberFormat.currency(
                            symbol: '',
                            decimalDigits: 2,
                          ).format(amount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive, Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? activeColor : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Icon(
              Icons.check_circle,
              size: 14,
              color: activeColor,
            ),
          if (isActive) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? activeColor : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.currency_rupee_outlined, size: 20),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildBalanceDisplay(double balance) {
    final isPositive = balance >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPositive ? Colors.blue.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPositive ? Colors.blue.shade100 : Colors.red.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.arrow_outward : Icons.arrow_downward,
            color: isPositive ? Colors.blue : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Balance ${isPositive ? 'Due' : 'Overpaid'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.blue : Colors.red,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.currencySymbol}${balance.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.blue : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment History',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (_paymentHistory.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No payments recorded yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._paymentHistory.map((payment) => _buildPaymentItem(payment)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payment, size: 20, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['method'] ?? 'Payment',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('MMM dd, yyyy')
                      .format(payment['date'] as DateTime),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (payment['reference'] != null)
                  Text(
                    payment['reference'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            '${widget.currencySymbol}${(payment['amount'] as double).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context) async {
    final totalAmount = double.tryParse(widget.totalController.text) ?? 0.0;
    final receivedAmount =
        double.tryParse(widget.receivedAmountController.text) ?? 0.0;
    final remainingBalance = totalAmount - receivedAmount;

    final amountController = TextEditingController(
      text: remainingBalance > 0 ? remainingBalance.toStringAsFixed(2) : '0.00',
    );

    String selectedMethod = 'Cash';
    String? selectedBankId;
    final referenceController = TextEditingController();
    final paymentDate = DateTime.now();
    final provider = widget.provider as dynamic;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Record Payment'),
              content: Form(
                key: _paymentFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPaymentSummary(
                          totalAmount, receivedAmount, remainingBalance),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(Icons.currency_rupee_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
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
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(
                              value: 'Cheque', child: Text('Cheque')),
                          DropdownMenuItem(value: 'Card', child: Text('Card')),
                          DropdownMenuItem(value: 'Upi', child: Text('UPI')),
                          DropdownMenuItem(
                              value: 'Bank', child: Text('Bank Transfer')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: Icon(Icons.payment),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedMethod = value!;
                          });
                        },
                      ),
                      if (selectedMethod == 'Bank') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedBankId,
                          hint: const Text('Select Bank Account'),
                          items: provider.bankAccounts
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
                            if (selectedMethod == 'Bank' && value == null) {
                              return 'Please select a bank account';
                            }
                            return null;
                          },
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showBankDetailsBottomSheet();
                          },
                          child: const Text('+ Add New Bank Account'),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Reference (Optional)',
                          prefixIcon: Icon(Icons.receipt),
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
                            // Update payment date
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Payment Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('MMM dd, yyyy')
                                  .format(paymentDate)),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
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
                FilledButton(
                  onPressed: () {
                    if (_paymentFormKey.currentState?.validate() ?? false) {
                      Navigator.pop(context, {
                        'amount': double.parse(amountController.text),
                        'method': selectedMethod,
                        'reference': referenceController.text,
                        'date': paymentDate,
                        'bankId':
                            selectedMethod == 'Bank' ? selectedBankId : null,
                      });
                    }
                  },
                  child: const Text('Record Payment'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      // Update the received amount
      final newReceived = receivedAmount + (result['amount'] as double);
      widget.receivedAmountController.text = newReceived.toStringAsFixed(2);
      _updateBalance();

      // Update the payment type in the main form if needed
      if (result['method'] == 'Cash') {
        provider.setPaymentType('Cash');
      } else if (result['method'] == 'Cheque') {
        provider.setPaymentType('Cheque');
      } else if (result['method'] == 'Upi') {
        provider.setPaymentType('Upi');
      } else if (result['method'] == 'Bank') {
        provider.setPaymentType('Bank');
        provider.setSelectedBankId(result['bankId']);
      }

      // Add to payment history
      setState(() {
        _paymentHistory.add({
          'amount': result['amount'],
          'date': result['date'],
          'method': result['method'],
          'reference': result['reference'],
          'bankId': result['bankId'],
        });
      });

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Payment of ${widget.currencySymbol}${result['amount']} recorded'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildPaymentSummary(double total, double received, double remaining) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildSummaryRow('Total Amount', total),
            _buildSummaryRow('Amount Received', received),
            const Divider(height: 16),
            _buildSummaryRow(
              'Remaining Balance',
              remaining,
              isBold: true,
              color: remaining > 0 ? Colors.orange : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.currencySymbol}${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _showBankDetailsBottomSheet() {
  return Container();
}
