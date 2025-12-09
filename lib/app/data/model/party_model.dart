import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
part 'party_model.g.dart';

@HiveType(typeId: 11)
class PartyModel extends HiveObject {
  @HiveField(0)
  String? id = const Uuid().v4();

  @HiveField(1)
  String? name;

  @HiveField(2)
  String? category;

  @HiveField(3)
  String? contactNumber;

  @HiveField(4)
  bool? isCustomer;

  @HiveField(5)
  String? gstNumber;

  @HiveField(6)
  String? panNumber;

  @HiveField(7)
  double? openingBalance;

  @HiveField(8)
  bool? isPayment;

  @HiveField(9)
  String? creditPeriod;

  @HiveField(10)
  double? creditAmount;

  @HiveField(11)
  DateTime? date;

  @HiveField(12)
  String? email;

  @HiveField(13)
  String? billingStreet;

  @HiveField(14)
  String? billingCity;

  @HiveField(15)
  String? billingState;

  @HiveField(16)
  String? billingPincode;

  @HiveField(17)
  String? shippingStreet;

  @HiveField(18)
  String? shippingCity;

  @HiveField(19)
  String? shippingState;

  @HiveField(20)
  String? shippingPincode;

  PartyModel({
    this.name,
    this.id,
    this.category,
    this.contactNumber,
    this.isCustomer,
    this.gstNumber,
    this.panNumber,
    this.openingBalance,
    this.isPayment,
    this.creditPeriod,
    this.creditAmount,
    this.date,
    this.email,
    this.billingStreet,
    this.billingCity,
    this.billingState,
    this.billingPincode,
    this.shippingStreet,
    this.shippingCity,
    this.shippingState,
    this.shippingPincode,
  });

  factory PartyModel.fromJson(Map<String, dynamic> json) {
    return PartyModel(
      name: json['name'] ?? '',
      id: json['id'] ?? const Uuid().v4(),
      category: json['category'],
      contactNumber: json['contactNumber'],
      isCustomer: json['isCustomer'],
      gstNumber: json['gstNumber'],
      panNumber: json['panNumber'],
      openingBalance: json['openingBalance']?.toDouble(),
      isPayment: json['isPayment'],
      creditPeriod: json['creditPeriod'],
      creditAmount: json['creditAmount']?.toDouble(),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      email: json['email'],
      billingStreet: json['billingAddress']?['street'],
      billingCity: json['billingAddress']?['city'],
      billingState: json['billingAddress']?['state'],
      billingPincode: json['billingAddress']?['pincode'],
      shippingStreet: json['shippingAddress']?['street'],
      shippingCity: json['shippingAddress']?['city'],
      shippingState: json['shippingAddress']?['state'],
      shippingPincode: json['shippingAddress']?['pincode'],
    );
  }
  String get billingAddress {
    return [billingStreet, billingCity, billingState, billingPincode]
        .where((part) => part?.isNotEmpty ?? false)
        .join(', ');
  }

  String get shippingAddress {
    return [shippingStreet, shippingCity, shippingState, shippingPincode]
        .where((part) => part?.isNotEmpty ?? false)
        .join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'contactNumber': contactNumber,
      'isCustomer': isCustomer,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'openingBalance': openingBalance,
      'isPayment': isPayment,
      'creditPeriod': creditPeriod,
      'creditAmount': creditAmount,
      'billingAddress': {
        'street': billingStreet,
        'city': billingCity,
        'state': billingState,
        'pincode': billingPincode,
      },
      'shippingAddress': {
        'street': shippingStreet,
        'city': shippingCity,
        'state': shippingState,
        'pincode': shippingPincode,
      },
      'date': date?.toIso8601String(),
      'email': email,
    };
  }

  @override
  String toString() {
    return 'PartyModel{name: $name, '
        'category: $category, '
        'contactNumber: $contactNumber, '
        'isCustomer: ${isCustomer.toString()}, '
        'gstNumber: $gstNumber, '
        'panNumber: $panNumber, '
        'openingBalance: $openingBalance, '
        'isPayment: ${isPayment.toString()}, '
        'creditPeriod: $creditPeriod, '
        'creditAmount: $creditAmount, '
        'billingAddress: $billingAddress, '
        'date: $date, '
        'email: $email, '
        'id: $id, '
        'shippingAddress: $shippingAddress,}';
  }
}
