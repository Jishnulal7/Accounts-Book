class GstCalculator {
  final bool isSameState;
  final double subtotal;
  final double gstRate;

  GstCalculator({
    required this.isSameState,
    required this.subtotal,
    required this.gstRate,
  });

  Map<String, double> calculateTax() {
    if (isSameState) {
      double cgst = subtotal * (gstRate / 200); // Half of GST rate
      double sgst = cgst;
      return {
        'cgst': cgst,
        'sgst': sgst,
        'igst': 0.0,
      };
    } else {
      double igst = subtotal * (gstRate / 100);
      return {
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': igst,
      };
    }
  }
}
