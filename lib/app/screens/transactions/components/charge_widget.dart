import 'package:account_book/app/screens/transactions/export.dart';

class ChargesWidget extends StatefulWidget {
  final TextEditingController shippingChargeController;
  final TextEditingController packagingChargeController;
  final TextEditingController additionalChargeController;
  final TextEditingController discountController;
  final Function() onChargesUpdated;
  const ChargesWidget({
    super.key,
    required this.shippingChargeController,
    required this.additionalChargeController,
    required this.packagingChargeController,
    required this.discountController,
    required this.onChargesUpdated,
  });

  @override
  ChargesWidgetState createState() => ChargesWidgetState();
}

class ChargesWidgetState extends State<ChargesWidget> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Charges',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              // Wide screen layout - 2 columns
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ChargeRow(
                          label: 'Shipping',
                          textEditingController:
                              widget.shippingChargeController,
                          currentIndex: 0,
                          onChanged: widget.onChargesUpdated,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ChargeRow(
                          label: 'Packaging',
                          textEditingController:
                              widget.packagingChargeController,
                          currentIndex: 1,
                          onChanged: widget.onChargesUpdated,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ChargeRow(
                          label: 'Discounts',
                          textEditingController: widget.discountController,
                          currentIndex: 2,
                          onChanged: widget.onChargesUpdated,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ChargeRow(
                          label: 'Additional Charges',
                          textEditingController:
                              widget.additionalChargeController,
                          currentIndex: 3,
                          onChanged: widget.onChargesUpdated,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Narrow screen layout - single column
              return Column(
                children: [
                  ChargeRow(
                    label: 'Shipping',
                    textEditingController: widget.shippingChargeController,
                    currentIndex: 0,
                    onChanged: widget.onChargesUpdated,
                  ),
                  const SizedBox(height: 10),
                  ChargeRow(
                    label: 'Packaging',
                    textEditingController: widget.packagingChargeController,
                    currentIndex: 1,
                    onChanged: widget.onChargesUpdated,
                  ),
                  const SizedBox(height: 10),
                  ChargeRow(
                    label: 'Discounts',
                    textEditingController: widget.discountController,
                    currentIndex: 2,
                    onChanged: widget.onChargesUpdated,
                  ),
                  const SizedBox(height: 10),
                  ChargeRow(
                    label: 'Additional Charges',
                    textEditingController: widget.additionalChargeController,
                    currentIndex: 3,
                    onChanged: widget.onChargesUpdated,
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

class ChargeRow extends StatelessWidget {
  final String label;
  final int currentIndex;
  final Function() onChanged;
  final TextEditingController textEditingController;
  const ChargeRow({
    super.key,
    required this.label,
    required this.textEditingController,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        CustomTextField(
          onChanged: (_) => onChanged(),
          controller: textEditingController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.currency_rupee_outlined, size: 15),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
          ],
          style: const TextStyle(fontSize: 14),
          contentPadding: const EdgeInsets.all(12),
        ),
      ],
    );
  }
}
