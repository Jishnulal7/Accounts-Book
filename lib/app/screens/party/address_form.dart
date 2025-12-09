import 'package:account_book/app/screens/party/exports.dart';

class AddressForm extends StatelessWidget {
  final bool isBillingAddress;
  final Map<String, TextEditingController> controllers;
  final String selectedState;
  final Function(String) onStateChanged;
  final Function(String) onSave;

  const AddressForm({
    super.key,
    required this.isBillingAddress,
    required this.controllers,
    required this.selectedState,
    required this.onStateChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = isBillingAddress ? 'billing' : 'shipping';

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isBillingAddress ? 'Billing' : 'Shipping'} Address',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: controllers['${prefix}Street']!,
              hintText: 'Street Address',
              validator: (value) =>
                  value!.isEmpty ? 'Street address is required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    focusColor: Colors.transparent,
                    value: selectedState,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        onStateChanged(value);
                        controllers['${prefix}State']!.text = value;
                      }
                    },
                    items: ListData()
                        .states
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value,
                                  style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: controllers['${prefix}Pincode']!,
                    hintText: 'Pincode',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: controllers['${prefix}City']!,
              hintText: 'City',
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              onTap: () {
                final address = '${controllers['${prefix}Street']!.text}, '
                    '${controllers['${prefix}City']!.text}, '
                    '${controllers['${prefix}State']!.text}, '
                    '${controllers['${prefix}Pincode']!.text}';
                onSave(address);
              },
              text: 'Save',
              textColor: AppColor.kWhite,
              bgColor: AppColor.kPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class AddressDisplay extends StatelessWidget {
  final String title;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final VoidCallback onAddPress;
  final bool enabled;

  const AddressDisplay({
    super.key,
    required this.title,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    required this.onAddPress,
    required this.enabled,
  });

  String get fullAddress {
    return [street, city, state, pincode]
        .where((part) => part.isNotEmpty)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (street.isEmpty)
          PrimaryButton(
            onTap: onAddPress,
            text: 'Add $title',
            textColor: AppColor.kWhite,
            bgColor: enabled ? AppColor.kPrimary : Colors.grey,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullAddress,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onAddPress,
                child: const Text('Edit Address'),
              ),
            ],
          ),
      ],
    );
  }
}
