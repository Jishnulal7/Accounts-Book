import 'package:get_storage/get_storage.dart';

class StorageService {
  static Future<void> initializeStorage() async {
    await GetStorage.init();
    
    GetStorage.init('receipt_categories');
    GetStorage.init('payment_categories');
    GetStorage.init('accounts');
    GetStorage.init('generalCategories');
    GetStorage.init('biometric_enabled');
  }
}
