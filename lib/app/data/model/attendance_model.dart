import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
part 'attendance_model.g.dart';

@HiveType(typeId: 3)
class AttendanceModel extends HiveObject {
  @HiveField(0)
  late DateTime date;

  @HiveField(1)
  late bool isPresent;

  @HiveField(2)
  late String name;

  @HiveField(3)
  late double wage;

  @HiveField(4)
  late String siteName;

  @HiveField(5)
  late double extraCharges;

  @HiveField(6)
  late String description;

  @HiveField(7)
  late double payment;

  @HiveField(8)
  late double balance;

  @HiveField(9)
  late double openingBalance;

  @HiveField(10)
  late String account;

  @HiveField(11)
  late String subName;

  @HiveField(12)
  late String id;

  @HiveField(13)
  late String? categoryName;

  @HiveField(14)
  late String categoryPath;

  @HiveField(15)
  late String accountPath;

  @HiveField(16)
  late String? generalCategoryName;

  @HiveField(17)
  late String? subCategory;

  @HiveField(18)
  late String? generalSubCategory;

  @HiveField(19)
  late String? subAccount;

  AttendanceModel({
    required this.date,
    required this.isPresent,
    required this.name,
    required this.wage,
    required this.siteName,
    required this.extraCharges,
    required this.description,
    required this.payment,
    required this.balance,
    required this.account,
    required this.openingBalance,
    required this.subName,
    required this.accountPath,
    required this.categoryPath,
    required this.generalCategoryName,
    required this.generalSubCategory,
    required this.subCategory,
    required this.subAccount,
    String? id,
    required this.categoryName,
  }) : id = id ?? const Uuid().v4();

  // Method to convert AttendanceModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'isPresent': isPresent,
      'name': name,
      'wage': wage,
      'siteName': siteName,
      'extraCharges': extraCharges,
      'description': description,
      'payment': payment,
      'balance': balance,
      'openingBalance': openingBalance,
      'account': account,
      'subName': subName,
      'id': id,
      'categoryName': categoryName,
      'categoryPath': categoryPath,
      'accountPath': accountPath,
      'generalCategoryName': generalCategoryName,
      'generalSubCategory': generalSubCategory,
      'subCategory': subCategory,
      'subAccount': subAccount
    };
  }

  // Factory constructor to create an AttendanceModel from JSON
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      date: DateTime.parse(json['date'] as String),
      isPresent: json['isPresent'] as bool,
      name: json['name'] as String,
      wage: json['wage'] as double,
      siteName: json['siteName'] as String,
      extraCharges: json['extraCharges'] as double,
      description: json['description'] as String,
      payment: json['payment'] as double,
      balance: json['balance'] as double,
      openingBalance: json['openingBalance'] as double,
      account: json['account'] as String,
      subName: json['subName'] as String,
      id: json['id'] as String,
      categoryName: json['categoryName'] as String,
      categoryPath: json['categoryPath'] as String,
      accountPath: json['accountPath'] as String,
      generalCategoryName: json['generalCategoryName'] as String,
      generalSubCategory: json['generalSubCategory'] as String,
      subAccount: json['subAccount'] as String,
      subCategory: json['subCategory'] as String,
    );
  }

  @override
  String toString() {
    return 'AttendanceModel(id: $id, amount: $payment, description: $description, subName : $subName ';
  }
}
