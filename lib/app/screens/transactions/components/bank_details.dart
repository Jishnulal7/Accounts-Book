import 'package:account_book/app/screens/transactions/export.dart';

class BankDetailsBottomSheet extends StatefulWidget {
  final Map<String, String>? existingDetails;
  final Function(Map<String, String>) onSave;

  const BankDetailsBottomSheet({
    super.key,
    this.existingDetails,
    required this.onSave,
  });

  @override
  BankDetailsBottomSheetState createState() => BankDetailsBottomSheetState();
}

class BankDetailsBottomSheetState extends State<BankDetailsBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bankNameController;
  late TextEditingController _accountHolderController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscCodeController;
  late TextEditingController _bankBranchController;

  @override
  void initState() {
    super.initState();
    _bankNameController =
        TextEditingController(text: widget.existingDetails?['bankName'] ?? '');
    _accountHolderController = TextEditingController(
        text: widget.existingDetails?['accountHolder'] ?? '');
    _accountNumberController = TextEditingController(
        text: widget.existingDetails?['accountNumber'] ?? '');
    _ifscCodeController =
        TextEditingController(text: widget.existingDetails?['ifscCode'] ?? '');
    _bankBranchController = TextEditingController(
        text: widget.existingDetails?['bankBranch'] ?? '');
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _bankBranchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bank Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 5),
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(labelText: 'Bank Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter bank name' : null,
              ),
              TextFormField(
                controller: _accountHolderController,
                decoration: InputDecoration(labelText: 'Account Holder Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter account holder name' : null,
              ),
              TextFormField(
                controller: _accountNumberController,
                inputFormatters: [LengthLimitingTextInputFormatter(14)],
                decoration: InputDecoration(labelText: 'Account Number'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter account number' : null,
              ),
              TextFormField(
                controller: _ifscCodeController,
                decoration: InputDecoration(labelText: 'IFSC Code'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter IFSC Code';
                  }
                  final regex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
                  if (!regex.hasMatch(value)) {
                    return 'Invalid IFSC Code. Must be 11 characters long.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _bankBranchController,
                decoration: InputDecoration(labelText: 'Bank Branch'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter bank branch' : null,
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSave({
                      'bankName': _bankNameController.text,
                      'accountHolder': _accountHolderController.text,
                      'accountNumber': _accountNumberController.text,
                      'ifscCode': _ifscCodeController.text,
                      'bankBranch': _bankBranchController.text,
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text('Save Bank Details'),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
