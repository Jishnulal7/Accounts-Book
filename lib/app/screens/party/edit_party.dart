import 'package:account_book/app/data/helpers/enums/toast.dart';
import 'package:account_book/app/screens/party/exports.dart';

class EditParty extends StatefulWidget {
  final PartyModel party;
  final VoidCallback onPartyEdit;

  const EditParty({super.key, required this.party, required this.onPartyEdit});

  @override
  State<EditParty> createState() => _EditPartyState();
}

class _EditPartyState extends State<EditParty> {
  final formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isSameAddress = false;
  late String _selectedState;

  late bool isCustomer;
  late bool isPayment;
  late String selectedCreditPeriod;
  DateTime selectMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedState = widget.party.billingState ?? ListData().states[0];
    _initializeControllers();
    isCustomer = widget.party.isCustomer!;
    isPayment = widget.party.isPayment ?? false;
    selectedCreditPeriod = widget.party.creditPeriod!;
    _isSameAddress =
        widget.party.billingAddress == widget.party.shippingAddress;
  }

  void _initializeControllers() {
    _controllers['name'] = TextEditingController(text: widget.party.name);
    _controllers['category'] =
        TextEditingController(text: widget.party.category);
    _controllers['phone'] =
        TextEditingController(text: widget.party.contactNumber);
    _controllers['gst'] = TextEditingController(text: widget.party.gstNumber);
    _controllers['pan'] = TextEditingController(text: widget.party.panNumber);
    _controllers['email'] = TextEditingController(text: widget.party.email);
    _controllers['openingBalance'] = TextEditingController(
        text: widget.party.openingBalance?.toString() ?? '0.0');
    _controllers['creditAmount'] = TextEditingController(
        text: widget.party.creditAmount?.toString() ?? '0.0');

    // Billing address controllers
    _controllers['billingStreet'] =
        TextEditingController(text: widget.party.billingStreet);
    _controllers['billingCity'] =
        TextEditingController(text: widget.party.billingCity);
    _controllers['billingState'] =
        TextEditingController(text: widget.party.billingState);
    _controllers['billingPincode'] =
        TextEditingController(text: widget.party.billingPincode);

    // Shipping address controllers
    _controllers['shippingStreet'] = TextEditingController(
        text: _isSameAddress
            ? widget.party.billingStreet
            : widget.party.shippingStreet);
    _controllers['shippingCity'] = TextEditingController(
        text: _isSameAddress
            ? widget.party.billingCity
            : widget.party.shippingCity);
    _controllers['shippingState'] = TextEditingController(
        text: _isSameAddress
            ? widget.party.billingState
            : widget.party.shippingState);
    _controllers['shippingPincode'] = TextEditingController(
        text: _isSameAddress
            ? widget.party.billingPincode
            : widget.party.shippingPincode);
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showAddressBottomSheet(bool isBillingAddress) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddressForm(
        isBillingAddress: isBillingAddress,
        controllers: _controllers,
        selectedState: _selectedState,
        onStateChanged: (value) => setState(() => _selectedState = value),
        onSave: (address) {
          setState(() {
            if (isBillingAddress && _isSameAddress) {
              // Copy billing address to shipping fields if "same address" is checked
              _controllers['shippingStreet']!.text =
                  _controllers['billingStreet']!.text;
              _controllers['shippingCity']!.text =
                  _controllers['billingCity']!.text;
              _controllers['shippingState']!.text =
                  _controllers['billingState']!.text;
              _controllers['shippingPincode']!.text =
                  _controllers['billingPincode']!.text;
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void updatePartyInformation() async {
    if (formKey.currentState!.validate()) {
      if (_controllers['name']!.text.isNotEmpty) {
        try {
          final openingBalance =
              double.tryParse(_controllers['openingBalance']!.text) ?? 0.0;
          final creditAmount =
              double.tryParse(_controllers['creditAmount']!.text) ?? 0.0;

          PartyModel updatedParty = PartyModel(
            id: widget.party.id,
            date: widget.party.date,
            name: _controllers['name']!.text,
            category: _controllers['category']!.text,
            contactNumber: _controllers['phone']!.text,
            isCustomer: isCustomer,
            gstNumber: _controllers['gst']!.text,
            panNumber: _controllers['pan']!.text,
            email: _controllers['email']!.text,
            openingBalance: openingBalance,
            isPayment: isPayment,
            creditPeriod: selectedCreditPeriod,
            creditAmount: creditAmount,
            billingStreet: _controllers['billingStreet']!.text,
            billingCity: _controllers['billingCity']!.text,
            billingState: _controllers['billingState']!.text,
            billingPincode: _controllers['billingPincode']!.text,
            shippingStreet: _isSameAddress
                ? _controllers['billingStreet']!.text
                : _controllers['shippingStreet']!.text,
            shippingCity: _isSameAddress
                ? _controllers['billingCity']!.text
                : _controllers['shippingCity']!.text,
            shippingState: _isSameAddress
                ? _controllers['billingState']!.text
                : _controllers['shippingState']!.text,
            shippingPincode: _isSameAddress
                ? _controllers['billingPincode']!.text
                : _controllers['shippingPincode']!.text,
          );

          await Provider.of<PartyProvider>(context, listen: false)
              .updateParty(updatedParty);
          widget.onPartyEdit.call();
          if (!mounted) return;
          Navigator.pop(context, updatedParty);
        } catch (e) {
          debugPrint('Error updating party: $e');
        }
      }
    } else {
      if (_controllers['name']!.text.isEmpty) {
        ToastService.show(
          context,
          message: 'Party name cannot be empty.',
          type: ToastType.warning,
        );
      }
    }
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AddressDisplay(
          title: 'Billing Address',
          street: _controllers['billingStreet']!.text,
          city: _controllers['billingCity']!.text,
          state: _controllers['billingState']!.text,
          pincode: _controllers['billingPincode']!.text,
          onAddPress: () => _showAddressBottomSheet(true),
          enabled: true,
        ),
        const SizedBox(height: 16),
        if (_controllers['billingStreet']!.text.isNotEmpty)
          Row(
            children: [
              Checkbox(
                value: _isSameAddress,
                onChanged: (value) {
                  setState(() {
                    _isSameAddress = value!;
                    if (_isSameAddress) {
                      // Copy billing address to shipping fields
                      _controllers['shippingStreet']!.text =
                          _controllers['billingStreet']!.text;
                      _controllers['shippingCity']!.text =
                          _controllers['billingCity']!.text;
                      _controllers['shippingState']!.text =
                          _controllers['billingState']!.text;
                      _controllers['shippingPincode']!.text =
                          _controllers['billingPincode']!.text;
                    }
                  });
                },
              ),
              const Text('Shipping address same as billing'),
            ],
          ),
        const SizedBox(height: 16),
        if (!_isSameAddress || _controllers['billingStreet']!.text.isEmpty)
          AddressDisplay(
            title: 'Shipping Address',
            street: _controllers['shippingStreet']!.text,
            city: _controllers['shippingCity']!.text,
            state: _controllers['shippingState']!.text,
            pincode: _controllers['shippingPincode']!.text,
            onAddPress: () => _showAddressBottomSheet(false),
            enabled: !_isSameAddress,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Party'),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        child: PrimaryButton(
          onTap: updatePartyInformation,
          text: 'Save',
          textColor: AppColor.kWhite,
          bgColor: AppColor.kPrimary,
          height: width / 2,
          width: width,
          borderRadius: 20,
        ),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: Column(
                    children: [
                      _buildTextFieldSection(
                        'Party Name',
                        _controllers['name']!,
                        'Tom',
                        context,
                        TextInputType.name,
                        validator: (value) =>
                            value!.isEmpty ? "Party Name can't be empty" : null,
                      ),
                      _buildTextFieldSection(
                        'Category Name',
                        _controllers['category']!,
                        'Category',
                        context,
                        TextInputType.name,
                      ),
                      _buildTextFieldSection(
                        'Email',
                        _controllers['email']!,
                        'Ex: test@gmail.com',
                        context,
                        TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      _buildContactAndPartyTypeSection(width),
                      const Divider(),
                      _buildTextFieldSection(
                        'GST Number',
                        _controllers['gst']!,
                        '24AAACC1206D1ZM',
                        context,
                        TextInputType.text,
                        maxLength: 15,
                        validator: (value) {
                          if (value!.isNotEmpty) {
                            final regExp = RegExp(
                                r'^[0-9]{2}[A-Z]{3}[ABCFGHLJPTF]{1}[A-Z]{1}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                            return regExp.hasMatch(value)
                                ? null
                                : 'Please enter a valid GST number';
                          }
                          return null;
                        },
                      ),
                      _buildTextFieldSection(
                        'PAN Number',
                        _controllers['pan']!,
                        'AAACC1206D',
                        context,
                        TextInputType.text,
                        maxLength: 10,
                        validator: (value) {
                          if (value!.isNotEmpty) {
                            final regExp =
                                RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                            return regExp.hasMatch(value)
                                ? null
                                : 'Please enter a valid Pan number';
                          }
                          return null;
                        },
                      ),
                      _buildOpeningBalanceAndPaymentSection(width),
                      _buildCreditPeriodSection(),
                      _buildTextFieldSection(
                        'Credit Limit',
                        _controllers['creditAmount']!,
                        '1000.0',
                        context,
                        TextInputType.number,
                      ),
                      _buildAddressSection(),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldSection(
    String title,
    TextEditingController controller,
    String hintText,
    BuildContext context,
    TextInputType keyboardType, {
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          CustomTextField(
            controller: controller,
            hintText: hintText,
            keyboardType: keyboardType,
            maxLength: maxLength,
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildContactAndPartyTypeSection(double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: width / 2.5,
          child: _buildTextFieldSection(
            'Contact Number',
            _controllers['phone']!,
            'Ex: 9876543210',
            context,
            TextInputType.phone,
            maxLength: 10,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Party Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                CustomToggleButton(
                  text: 'Customer',
                  isSelected: isCustomer,
                  onTap: () {
                    setState(() {
                      isCustomer = true;
                    });
                  },
                ),
                const SizedBox(width: 10),
                CustomToggleButton(
                  text: 'Supplier',
                  isSelected: !isCustomer,
                  onTap: () {
                    setState(() {
                      isCustomer = false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpeningBalanceAndPaymentSection(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldSection(
          'Opening Balance',
          _controllers['openingBalance']!,
          '0.0',
          context,
          TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildCreditPeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Credit Period',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select Due Date',
          ),
          value: selectedCreditPeriod,
          onChanged: (String? newValue) {
            setState(() {
              selectedCreditPeriod = newValue!;
            });
          },
          items: ListData().days.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}
