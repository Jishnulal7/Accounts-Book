import 'dart:convert';
import 'package:account_book/app/screens/yarima_wallet/attendance/components/attendance_model.dart';
import 'package:get_storage/get_storage.dart';

class CategoryService {
  final box = GetStorage();
  final String key = 'attendance_categories';

  List<AttendanceCategory> getCategories() {
    final String? categoriesJson = box.read(key);
    if (categoriesJson == null) return [];

    List<dynamic> categoriesList = json.decode(categoriesJson);
    return categoriesList
        .map((category) => AttendanceCategory.fromJson(category))
        .toList();
  }

  Future<void> saveCategories(List<AttendanceCategory> categories) async {
    final String categoriesJson =
        json.encode(categories.map((category) => category.toJson()).toList());
    await box.write(key, categoriesJson);
  }
}
