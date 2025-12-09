import 'package:account_book/app/screens/profile/exports.dart';
import 'package:account_book/app/widgets/country_picker.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ProfileEditScreenState createState() => ProfileEditScreenState();
}

class ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  // Split the address into components
  final TextEditingController _streetAddressController =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  // Variables for dropdown selections
  String? _selectedState;
  String? _selectedCountry;
  String? _selectedStateCode;

  // List to store countries and states
  List<Map<String, dynamic>> _countries = [];
  Map<String, String> _states = {};
  bool _isIndiaSelected = false;

  File? _logoImage;
  String? _savedLogoPath;

  // Validation Patterns
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );
  static final RegExp _mobileRegExp = RegExp(r'^[0-9]{10}$');
  // static final RegExp _gstinRegExp = RegExp(
  //   r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$',
  // );
  // static final RegExp _panRegExp = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');

  String? _validateBusinessName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter business name';
    }
    if (value.length < 3) {
      return 'Business name must be at least 3 characters';
    }
    return null;
  }
 
  // String? _validateGSTIN(String? value) {
  //   if (value == null || value.isEmpty) {
  //     return 'Please enter GSTIN';
  //   }
  //   if (!_gstinRegExp.hasMatch(value)) {
  //     return 'Please enter a valid GSTIN';
  //   }
  //   return null;
  // }

  // String? _validatePAN(String? value) {
  //   if (value == null || value.isEmpty) {
  //     return 'Please enter PAN';
  //   }
  //   if (!_panRegExp.hasMatch(value)) {
  //     return 'Please enter a valid PAN number';
  //   }
  //   return null;
  // }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    if (!_emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter mobile number';
    }
    if (!_mobileRegExp.hasMatch(value)) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? _validateStreetAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter street address';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter city';
    }
    return null;
  }

  String? _validatePincode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter pincode';
    }
    if (value.length != 6) {
      return 'Pincode must be 6 digits';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _initializeStates();
    _loadProfileData();
  }

  Future<void> _loadCountries() async {
    try {
      final String response = await DefaultAssetBundle.of(context)
          .loadString('assets/json/world.json');
      final List<dynamic> decoded = json.decode(response);
      setState(() {
        _countries = List<Map<String, dynamic>>.from(decoded.map((country) => {
              'id': country['id'],
              'name': country['name'],
            }));
      });
      // debugPrint('Countries Loaded: $_countries');
    } catch (e) {
      debugPrint('Error loading countries: $e');
    }
  }

  void _initializeStates() {
    _states = {
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

  // Get state code from state name
  String getStateCode(String stateName) {
    return _states[stateName] ?? 'No Data';
  }

  void _onCountryChanged(String? countryName) {
    setState(() {
      _selectedCountry = countryName;
      _isIndiaSelected = countryName == 'India';

      // Reset state if country is not India
      if (!_isIndiaSelected) {
        _selectedState = null;
        _selectedStateCode = null;
      }
    });
  }

  void _onStateChanged(String? stateName) {
    setState(() {
      _selectedState = stateName;
      if (stateName != null) {
        _selectedStateCode = getStateCode(stateName);
      } else {
        _selectedStateCode = null;
      }
    });
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    // First, try to load from businessData JSON
    String? businessDataJson = prefs.getString('businessData');

    if (businessDataJson != null) {
      try {
        // Parse the JSON string
        Map<String, dynamic> businessData = json.decode(businessDataJson);

        setState(() {
          _businessNameController.text = businessData['businessName'] ?? '';
          _gstinController.text = businessData['gstin'] ?? '';
          _panController.text = businessData['pan'] ?? '';
          _emailController.text = businessData['email'] ?? '';
          _mobileController.text = businessData['mobile'] ?? '';

          // Load address components
          _streetAddressController.text = businessData['street'] ?? '';
          _cityController.text = businessData['city'] ?? '';
          _pincodeController.text = businessData['postalCode'] ?? '';

          // Load country and state
          _selectedCountry = businessData['country'] ?? '';
          _selectedState = businessData['state'] ?? '';
          _selectedStateCode = businessData['stateCode'] ?? '';
          _isIndiaSelected = _selectedCountry == 'India';

          // Load logo if path exists
          _savedLogoPath = businessData['logoPath'];
          if (_savedLogoPath != null && _savedLogoPath!.isNotEmpty) {
            _logoImage = File(_savedLogoPath!);
          }
        });
      } catch (e) {
        // If JSON parsing fails, fall back to individual preferences
        setState(() {
          _businessNameController.text = prefs.getString('businessName') ?? '';
          _gstinController.text = prefs.getString('gstin') ?? '';
          _panController.text = prefs.getString('pan') ?? '';
          _emailController.text = prefs.getString('email') ?? '';
          _mobileController.text = prefs.getString('mobile') ?? '';
          _streetAddressController.text = prefs.getString('street') ?? '';
          _pincodeController.text = prefs.getString('postalCode') ?? '';
          _savedLogoPath = prefs.getString('logoPath');
          if (_savedLogoPath != null) {
            _logoImage = File(_savedLogoPath!);
          }
        });
      }
    } else {
      // If no businessData exists, keep everything empty
      setState(() {
        _businessNameController.clear();
        _gstinController.clear();
        _panController.clear();
        _emailController.clear();
        _mobileController.clear();
        _streetAddressController.clear();
        _cityController.clear();
        _pincodeController.clear();
        _logoImage = null;
        _savedLogoPath = null;
      });
    }
  }

  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) {
      // Show error message if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // Create a map of all business data
    final businessData = {
      'businessName': _businessNameController.text,
      'gstin': _gstinController.text,
      'pan': _panController.text,
      'email': _emailController.text,
      'mobile': _mobileController.text,
      'street': _streetAddressController.text,
      'city': _cityController.text,
      'state': _selectedState ?? (_isIndiaSelected ? '' : 'Not Available'),
      'stateCode': _selectedStateCode,
      'postalCode': _pincodeController.text,
      'country': _selectedCountry ?? '',
      'logoPath': _logoImage?.path,
    };

    // Save the entire business data as JSON
    await prefs.setString('businessData', json.encode(businessData));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickLogoImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _logoImage = File(image.path);
      });
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Widget _buildCountryDropdown() {
    return CountryDropdown(
      countries: _countries,
      selectedCountry: _selectedCountry,
      onCountryChanged: _onCountryChanged,
      labelText: 'Country',
      prefixIcon: Icon(
        Icons.public,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildStateDropdown() {
    if (_isIndiaSelected) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'State',
          prefixIcon: Icon(
            Icons.location_city,
            color: Theme.of(context).primaryColor,
          ),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        ),
        value: _selectedState,
        hint: const Text('Select State'),
        items: _states.keys.map((stateName) {
          return DropdownMenuItem<String>(
            value: stateName,
            child: Text(stateName),
          );
        }).toList(),
        onChanged: _onStateChanged,
      );
    } else {
      // Show this only when a non-India country is selected
      return TextFormField(
        initialValue: 'Not Available',
        readOnly: true,
        enabled: false,
        decoration: InputDecoration(
          labelText: 'State',
          prefixIcon: Icon(
            Icons.location_city,
            color: Theme.of(context).primaryColor,
          ),
          border: OutlineInputBorder(),
          disabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (Platform.isWindows) {
      screenWidth = screenWidth * 0.5;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.save,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: _saveProfileData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          alignment: Alignment.center,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickLogoImage,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: _logoImage != null
                        ? ClipOval(
                            child: Image.file(
                              _logoImage!,
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Logo',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: screenWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Information
                      CustomTextField(
                        controller: _businessNameController,
                        labelText: 'Business Name',
                        hintText: 'Enter your business name',
                        prefixIcon: Icon(
                          Icons.business,
                          color: Theme.of(context).primaryColor,
                        ),
                        validator: _validateBusinessName,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _gstinController,
                        labelText: 'GSTIN',
                        hintText: 'Enter your GSTIN',
                        prefixIcon: Icon(
                          Icons.confirmation_number,
                          color: Theme.of(context).primaryColor,
                        ),
                        // validator: _validateGSTIN,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _panController,
                        labelText: 'PAN Card',
                        hintText: 'Enter your PAN card number',
                        prefixIcon: Icon(
                          Icons.credit_card,
                          color: Theme.of(context).primaryColor,
                        ),
                        // validator: _validatePAN,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Enter your email address',
                        prefixIcon: Icon(
                          Icons.email,
                          color: Theme.of(context).primaryColor,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _mobileController,
                        labelText: 'Mobile No',
                        hintText: 'Enter your mobile number',
                        prefixIcon: Icon(
                          Icons.phone,
                          color: Theme.of(context).primaryColor,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: _validateMobile,
                        maxLength: 10,
                      ),
                      const SizedBox(height: 16),

                      // Address Section Header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Business Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Street Address
                      CustomTextField(
                        controller: _streetAddressController,
                        labelText: 'Street Address',
                        hintText: 'Building name, street, area',
                        prefixIcon: Icon(
                          Icons.location_on,
                          color: Theme.of(context).primaryColor,
                        ),
                        validator: _validateStreetAddress,
                      ),
                      const SizedBox(height: 8),

                      // City and Country
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _cityController,
                              labelText: 'City',
                              hintText: 'Enter city',
                              prefixIcon: Icon(
                                Icons.location_city,
                                color: Theme.of(context).primaryColor,
                              ),
                              validator: _validateCity,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCountryDropdown(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // State and Pincode
                      Row(
                        children: [
                          Expanded(
                            child: _buildStateDropdown(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              controller: _pincodeController,
                              labelText: 'Pincode',
                              hintText: 'Enter your pincode',
                              prefixIcon: Icon(
                                Icons.location_on,
                                color: Theme.of(context).primaryColor,
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              validator: _validatePincode,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _saveProfileData,
                  icon: Icon(
                    Icons.save,
                    color: Theme.of(context).primaryColor,
                  ),
                  label: const Text('Save Profile'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(200, 48),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
