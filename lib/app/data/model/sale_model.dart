import 'package:account_book/app/data/model/item_selection_model.dart';
import 'package:account_book/app/data/model/payment_record.dart';
import 'package:hive_ce/hive.dart';
part 'sale_model.g.dart';

@HiveType(typeId: 17)
class SaleModel extends HiveObject {
  @HiveField(0)
  final String invoiceNumber;

  @HiveField(1)
  String partyName;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final List<ItemSelectionModel> item;

  @HiveField(4)
  final double totalAmount;

  @HiveField(5)
  double? receivedAmount;

  @HiveField(6)
  double balanceAmount;

  @HiveField(7)
  final SalesType type;

  @HiveField(8)
  String? paymentType;

  @HiveField(9)
  String? id;

  @HiveField(10)
  String? stateOfSupply;

  @HiveField(11)
  List<String>? transportaionDetails;

  @HiveField(12)
  bool isRoundedOff;

  @HiveField(13)
  bool isFullyPaid;

  @HiveField(14)
  double? shippingCharges;

  @HiveField(15)
  double? packingCharges;

  @HiveField(16)
  double? discounts;

  @HiveField(17)
  double? additionalCharges;

  @HiveField(18)
  String? partyId;

  @HiveField(19)
  String? invoicePrefix;

  @HiveField(20)
  List<PaymentRecord>? paymentHistory;

  SaleModel({
    required this.invoiceNumber,
    required this.partyName,
    required this.date,
    required this.item,
    required this.totalAmount,
    this.receivedAmount,
    required this.balanceAmount,
    required this.type,
    this.paymentType,
    this.id,
    this.stateOfSupply,
    this.transportaionDetails,
    this.isRoundedOff = false,
    this.isFullyPaid = false,
    this.additionalCharges,
    this.shippingCharges,
    this.discounts,
    this.packingCharges,
    this.partyId,
    this.invoicePrefix,
    this.paymentHistory,
  });
  @override
  String toString() {
    return 'SaleModel('
        'invoiceNumber: $invoiceNumber, '
        'partyName: $partyName, '
        'date: $date, '
        'item: $item, '
        'totalAmount: $totalAmount, '
        'receivedAmount: $receivedAmount, '
        'balanceAmount: $balanceAmount, '
        'type: $type, '
        'paymentType: $paymentType, '
        'id: $id, '
        'stateOfSupply: $stateOfSupply, '
        'transportaionDetails: $transportaionDetails, '
        'isRoundedOff: $isRoundedOff, '
        'isFullyPaid: $isFullyPaid, '
        'shippingCharges: $shippingCharges, '
        'packingCharges: $packingCharges, '
        'discounts: $discounts, '
        'additionalCharges: $additionalCharges, '
        'partyId: $partyId)';
  }

  SaleModel copyWith({
    String? invoiceNumber,
    String? partyName,
    DateTime? date,
    List<ItemSelectionModel>? item,
    double? totalAmount,
    double? receivedAmount,
    double? balanceAmount,
    SalesType? type,
    String? paymentType,
    String? id,
    String? stateOfSupply,
    List<String>? transportaionDetails,
    bool? isRoundedOff,
    bool? isFullyPaid,
    double? shippingCharges,
    double? packingCharges,
    double? discounts,
    double? additionalCharges,
    String? partyId,
    String? invoicePrefix,
    List<PaymentRecord>? paymentHistory,
  }) {
    return SaleModel(
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      partyName: partyName ?? this.partyName,
      date: date ?? this.date,
      item: item ?? this.item,
      totalAmount: totalAmount ?? this.totalAmount,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      type: type ?? this.type,
      paymentType: paymentType ?? this.paymentType,
      id: id ?? this.id,
      stateOfSupply: stateOfSupply ?? this.stateOfSupply,
      transportaionDetails: transportaionDetails ?? this.transportaionDetails,
      isRoundedOff: isRoundedOff ?? this.isRoundedOff,
      isFullyPaid: isFullyPaid ?? this.isFullyPaid,
      shippingCharges: shippingCharges ?? this.shippingCharges,
      packingCharges: packingCharges ?? this.packingCharges,
      discounts: discounts ?? this.discounts,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      partyId: partyId ?? this.partyId,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }
}

@HiveType(typeId: 18)
enum SalesType {
  @HiveField(0)
  sale,

  @HiveField(1)
  salesReturn,

  @HiveField(2)
  estimation,

  @HiveField(3)
  deliveryChallan,

  @HiveField(4)
  proforma,

  @HiveField(5)
  salesOrder,
}
