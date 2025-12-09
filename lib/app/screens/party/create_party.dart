import 'package:account_book/app/data/helpers/enums/toast.dart';
import 'package:account_book/app/screens/party/exports.dart';

class CreateParty extends StatefulWidget {
  final TextEditingController? nameController;
  final VoidCallback? onPartyCreated;

  const CreateParty({
    super.key,
    this.nameController,
    this.onPartyCreated,
  });

  @override
  State<CreateParty> createState() => _CreatePartyState();
}

class _CreatePartyState extends State<CreateParty> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  late String _id;
  late DateTime _date;
  String _selectedCreditPeriod = 'None';
  bool _isCustomerSelected = true;
  final bool _isPayment = true;
  bool _isSameAddress = false;
  late String _selectedState;

  @override
  void initState() {
    super.initState();
    _id = const Uuid().v1();
    _date = DateTime.now();
    _selectedState = ListData().states[0];
    _initializeControllers();
  }

  void _initializeControllers() {
    final controllerNames = [
      'name',
      'phone',
      'gst',
      'pan',
      'email',
      'openingBalance',
      'creditAmount',
      'category',
      'billingStreet',
      'billingState',
      'billingPincode',
      'billingCity',
      'shippingStreet',
      'shippingState',
      'shippingPincode',
      'shippingCity'
    ];

    for (var name in controllerNames) {
      _controllers[name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateGST(String? value) {
    if (value?.isEmpty ?? true) return null;
    final regExp = RegExp(
        r'^[0-9]{2}[A-Z]{3}[ABCFGHLJPTF]{1}[A-Z]{1}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    return regExp.hasMatch(value!) ? null : 'Please enter a valid GST number';
  }

  String? _validatePan(String? value) {
    if (value?.isEmpty ?? true) return null;
    final regExp = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    return regExp.hasMatch(value!) ? null : 'Please enter a valid Pan number';
  }

  Future<void> _savePartyInformation() async {
    if (!_formKey.currentState!.validate()) {
      if (_controllers['name']!.text.isEmpty) {
        ToastService.show(
          context,
          message: 'Party name cannot be empty.',
          type: ToastType.warning,
        );
      }
      return;
    }

    final partyName = widget.nameController?.text ?? _controllers['name']!.text;
    if (partyName.isEmpty) return;

    try {
      final openingBalance =
          double.tryParse(_controllers['openingBalance']!.text) ?? 0.0;
      final creditAmount =
          double.tryParse(_controllers['creditAmount']!.text) ?? 0.0;

      final partyInfo = PartyModel(
        date: _date,
        id: _id,
        name: partyName,
        category: _controllers['category']!.text,
        contactNumber: _controllers['phone']!.text,
        isCustomer: _isCustomerSelected,
        gstNumber: _controllers['gst']!.text,
        panNumber: _controllers['pan']!.text,
        email: _controllers['email']!.text,
        openingBalance: openingBalance,
        isPayment: _isPayment,
        creditPeriod: _selectedCreditPeriod,
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

      await context.read<PartyProvider>().addParty(partyInfo);
      widget.onPartyCreated?.call();
      if (mounted) Navigator.pop(context, partyInfo);
    } catch (e) {
      debugPrint('Error saving party: $e');
    }
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
            if (isBillingAddress) {
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
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _copyBillingToShipping() {
    final prefixes = ['Street', 'State', 'Pincode', 'City'];
    for (var prefix in prefixes) {
      _controllers['shipping$prefix']!.text =
          _controllers['billing$prefix']!.text;
    }
    setState(() => _selectedState = _controllers['billingState']!.text);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Party')),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBasicInfo(width),
                _buildBusinessInfo(),
                _buildFinancialInfo(width),
                _buildAddressSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        child: PrimaryButton(
          onTap: _savePartyInformation,
          text: 'Save',
          textColor: AppColor.kWhite,
          bgColor: AppColor.kPrimary,
          height: width / 2,
          width: width,
          borderRadius: 20,
        ),
      ),
    );
  }

  Widget _buildBasicInfo(double width) {
    return Column(
      children: [
        _buildTextField(
          controller: widget.nameController ?? _controllers['name']!,
          hintText: 'John Doe',
          label: 'Party Name',
          validator: (value) =>
              value?.isEmpty ?? true ? "Party Name can't be empty" : null,
          keyboardType: TextInputType.name,
        ),
        _buildTextField(
          controller: _controllers['category']!,
          hintText: 'Local Party',
          label: 'Category Name',
        ),
        _buildTextField(
          controller: _controllers['email']!,
          hintText: 'sample@gmail.com',
          label: 'Email',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: width / 2.8,
              child: _buildTextField(
                controller: _controllers['phone']!,
                hintText: '9123456780',
                label: 'Contact Number',
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
            ),
            Row(
              children: [
                CustomToggleButton(
                  text: 'Customer',
                  isSelected: _isCustomerSelected,
                  onTap: () => setState(() => _isCustomerSelected = true),
                ),
                const SizedBox(width: 10),
                CustomToggleButton(
                  text: 'Supplier',
                  isSelected: !_isCustomerSelected,
                  onTap: () => setState(() => _isCustomerSelected = false),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessInfo() {
    return Column(
      children: [
        _buildTextField(
          controller: _controllers['gst']!,
          hintText: '29ABCDE1234F1Z5',
          label: 'GST Number',
          maxLength: 15,
          validator: _validateGST,
        ),
        _buildTextField(
          controller: _controllers['pan']!,
          hintText: 'ABCDE1234F',
          label: 'PAN Number',
          maxLength: 10,
          validator: _validatePan,
        ),
      ],
    );
  }

  Widget _buildFinancialInfo(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: width / 2.5,
          child: _buildTextField(
            controller: _controllers['openingBalance']!,
            hintText: '10',
            label: 'Opening Balance',
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.currency_rupee_outlined),
          ),
        ),
        const SizedBox(height: 15),
        const Text('Credit Period',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select Due Date',
          ),
          value: _selectedCreditPeriod,
          onChanged: (value) => setState(() => _selectedCreditPeriod = value!),
          items: [
            'None',
            '7 Days',
            '15 Days',
            '30 Days',
            '45 Days',
            '60 Days',
          ]
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _controllers['creditAmount']!,
          hintText: '200',
          label: 'Credit Limit',
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.currency_rupee_outlined),
        ),
      ],
    );
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
                      _copyBillingToShipping();
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        CustomTextField(
          controller: controller,
          keyboardType: keyboardType,
          hintText: hintText,
          validator: validator,
          prefixIcon: prefixIcon,
          maxLength: maxLength,
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
