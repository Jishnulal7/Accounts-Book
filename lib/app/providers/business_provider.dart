import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BusinessProvider extends ChangeNotifier {
  // Controllers
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController gstinController = TextEditingController();
  final TextEditingController panController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController streetAddressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();

  // State variables
  int currentPage = 0;
  String? selectedState;
  String? selectedCountry;
  String? selectedStateCode;
  File? logoImage;
  List<Map<String, dynamic>> countries = [];
  Map<String, String> states = {};
  bool isIndiaSelected = false;

  // Validation Regular Expressions
  final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
  final RegExp mobileRegex = RegExp(r'^[0-9]{10}$');

  // Initialize the states map
  void initializeStates() {
    states = {
      'Jammu and Kashmir': '01',
      'Himachal Pradesh': '02',
      'Punjab': '03',
      'Chandigarh': '04',
      'Uttarakhand': '05',
      'Haryana': '06',
      'Delhi': '07',
      'Rajasthan': '08',
      'Uttar Pradesh': '09',
      'Bihar': '10',
      'Sikkim': '11',
      'Arunachal Pradesh': '12',
      'Nagaland': '13',
      'Manipur': '14',
      'Mizoram': '15',
      'Tripura': '16',
      'Meghalaya': '17',
      'Assam': '18',
      'West Bengal': '19',
      'Jharkhand': '20',
      'Odisha': '21',
      'Chhattisgarh': '22',
      'Madhya Pradesh': '23',
      'Gujarat': '24',
      'Daman and Diu': '25',
      'Maharashtra': '27',
      'Karnataka': '29',
      'Goa': '30',
      'Lakshadweep': '31',
      'Kerala': '32',
      'Tamil Nadu': '33',
      'Puducherry': '34',
      'Telangana': '36',
      'Andhra Pradesh': '37',
      'Ladakh': '38'
    };
  }

  // Load countries from json asset
  Future<void> loadCountries(BuildContext context) async {
    try {
      final String response = await DefaultAssetBundle.of(context)
          .loadString('assets/json/world.json');
      final List<dynamic> decoded = json.decode(response);
      countries = List<Map<String, dynamic>>.from(decoded.map((country) => {
            'id': country['id'],
            'name': country['name'],
          }));
      notifyListeners();
      debugPrint('Countries Loaded: $countries');
    } catch (e) {
      debugPrint('Error loading countries: $e');
    }
  }

  // Get state code from state name
  String getStateCode(String stateName) {
    return states[stateName] ?? 'No Data';
  }

  // Handle country selection change
  void onCountryChanged(String? countryName) {
    selectedCountry = countryName;
    isIndiaSelected = countryName == 'India';

    // Reset state if country is not India
    if (!isIndiaSelected) {
      selectedState = null;
      selectedStateCode = null;
    }
    notifyListeners();
  }

  // Handle state selection change
  void onStateChanged(String? stateName) {
    selectedState = stateName;
    if (stateName != null) {
      selectedStateCode = getStateCode(stateName);
    } else {
      selectedStateCode = null;
    }
    notifyListeners();
  }

  // Validation methods
  String? validateBusinessName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Business name is required';
    }
    if (value.length < 3) {
      return 'Business name must be at least 3 characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    if (!mobileRegex.hasMatch(value)) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  // Image picker method
  Future<void> pickLogoImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    if (image != null) {
      logoImage = File(image.path);
      notifyListeners();
    }
  }

  // Navigate to next page
  void nextPage(PageController pageController) {
    if (currentPage < 2) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      currentPage++;
      notifyListeners();
    }
  }

  // Navigate to previous page
  void previousPage(PageController pageController) {
    if (currentPage > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      currentPage--;
      notifyListeners();
    }
  }

  // Page change handler
  void onPageChanged(int index) {
    currentPage = index;
    notifyListeners();
  }

  // Save business profile data to SharedPreferences
  Future<void> saveBusinessProfile(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final businessData = {
      'businessName': businessNameController.text,
      'gstin': gstinController.text,
      'pan': panController.text,
      'email': emailController.text,
      'mobile': mobileController.text,
      'street': streetAddressController.text,
      'city': cityController.text,
      'state': selectedState ?? (isIndiaSelected ? '' : 'Not Available'),
      'stateCode': selectedStateCode,
      'postalCode': postalCodeController.text,
      'country': selectedCountry ?? '',
      'logoPath': logoImage?.path,
    };

    await prefs.setString('businessData', json.encode(businessData));
  }
}
