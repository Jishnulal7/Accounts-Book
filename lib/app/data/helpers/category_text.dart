import 'package:account_book/app/data/model/attendance_model.dart';
import 'package:account_book/app/data/model/transaction_model.dart';

String getCategoryText(TransactionModel transaction) {
  final mainCategory = transaction.generalCategory?.isNotEmpty == true
      ? transaction.generalCategory!
      : transaction.categoryName ?? '';
  if (transaction.subCategory == null || transaction.subCategory!.isEmpty) {
    return mainCategory;
  }
  return '$mainCategory • ${transaction.subCategory}';
}

String getCategoryTextForAttendance(AttendanceModel attendance) {
  final mainCategory = attendance.generalCategoryName?.isNotEmpty == true
      ? attendance.generalCategoryName!
      : attendance.categoryName ?? '';
  if (attendance.subCategory == null || attendance.subCategory!.isEmpty) {
    return mainCategory;
  }
  return '$mainCategory • ${attendance.subCategory}';
}

String getAccountText(TransactionModel transaction) {
  final fromSubAccount = transaction.fromSubAccount;

  if (fromSubAccount == null || fromSubAccount.trim().isEmpty) {
    return transaction.fromAccount;
  }

  return '${transaction.fromAccount} • $fromSubAccount';
}
