import 'dart:io';
import 'package:account_book/app/widgets/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:account_book/app/screens/home/home_screen.dart';
import 'package:account_book/app/widgets/custom_text_field.dart';
import 'package:account_book/app/providers/business_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize provider data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BusinessProvider>(context, listen: false);
      provider.initializeStates();
      provider.loadCountries(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Onboarding'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              LinearProgressIndicator(
                  value: (businessProvider.currentPage + 1) / 3),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: isWideScreen
                      ? _buildWideScreenLayout(businessProvider)
                      : _buildNarrowScreenLayout(businessProvider),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWideScreenLayout(BusinessProvider provider) {
    return Row(
      children: [
        // Left side - Progress steps
        Container(
          width: 250,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressStep('Business Name', 0, provider),
              _buildProgressStep('Business Logo', 1, provider),
              _buildProgressStep('Business Details', 2, provider),
            ],
          ),
        ),
        // Right side - Content
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => provider.onPageChanged(index),
            children: [
              _buildBusinessNamePage(provider),
              _buildLogoUploadPage(provider),
              _buildBusinessDetailsPage(provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowScreenLayout(BusinessProvider provider) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) => provider.onPageChanged(index),
      children: [
        _buildBusinessNamePage(provider),
        _buildLogoUploadPage(provider),
        _buildBusinessDetailsPage(provider),
      ],
    );
  }

  Widget _buildBusinessNamePage(BusinessProvider provider) {
    return _buildPage(
      title: 'Enter Business Name',
      child: CustomTextField(
        controller: provider.businessNameController,
        labelText: 'Business Name',
        hintText: 'Enter your business name',
        prefixIcon: const Icon(Icons.business),
        validator: provider.validateBusinessName,
        onFieldSubmitted: (value) {
          if (_formKey.currentState!.validate()) {
            provider.nextPage(_pageController);
          }
        },
      ),
      onNext: () {
        if (_formKey.currentState!.validate()) {
          provider.nextPage(_pageController);
        }
      },
    );
  }

  Widget _buildLogoUploadPage(BusinessProvider provider) {
    return _buildPage(
      title: 'Upload Logo',
      child: Column(
        children: [
          GestureDetector(
            onTap: () => provider.pickLogoImage(ImageSource.gallery),
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.grey[200],
              backgroundImage: provider.logoImage != null
                  ? FileImage(provider.logoImage!, scale: .5)
                  : null,
              child: provider.logoImage == null
                  ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          if (!Platform.isWindows)
            ElevatedButton(
              onPressed: () => provider.pickLogoImage(ImageSource.camera),
              child: const Text('Take Photo'),
            ),
        ],
      ),
      onPrevious: () => provider.previousPage(_pageController),
      onNext: () => provider.nextPage(_pageController),
    );
  }

  Widget _buildBusinessDetailsPage(BusinessProvider provider) {
    return _buildPage(
      title: 'Business Details',
      child: Column(
        spacing: 10,
        children: [
          CustomTextField(
            controller: provider.gstinController,
            labelText: 'GSTIN',
          ),
          CustomTextField(
            controller: provider.panController,
            labelText: 'PAN',
          ),
          CustomTextField(
            controller: provider.emailController,
            labelText: 'Email',
            validator: provider.validateEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          CustomTextField(
            controller: provider.mobileController,
            labelText: 'Mobile',
            validator: provider.validateMobile,
            keyboardType: TextInputType.phone,
            maxLength: 10,
          ),
          const SizedBox(height: 16),
          const Text(
            'Business Address',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: provider.streetAddressController,
            labelText: 'Street Address',
            hintText: 'Building name, street, area',
            prefixIcon: const Icon(Icons.location_on),
          ),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: provider.cityController,
                  labelText: 'City',
                  prefixIcon: const Icon(Icons.location_city),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCountryDropdown(provider),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildStateDropdown(provider),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomTextField(
                  controller: provider.postalCodeController,
                  labelText: 'Pin Code',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
              ),
            ],
          ),
        ],
      ),
      onPrevious: () => provider.previousPage(_pageController),
      onNext: () => _saveAndNavigate(provider),
    );
  }

  Future<void> _saveAndNavigate(BusinessProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors before proceeding'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await provider.saveBusinessProfile(context);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Widget _buildCountryDropdown(BusinessProvider provider) {
    return CountryDropdown(
      countries: provider.countries,
      selectedCountry: provider.selectedCountry,
      onCountryChanged: (value) => provider.onCountryChanged(value),
      labelText: 'Country',
      prefixIcon: const Icon(Icons.public),
    );
  }

  Widget _buildStateDropdown(BusinessProvider provider) {
    if (provider.isIndiaSelected) {
      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'State',
          prefixIcon: Icon(Icons.location_city),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        ),
        value: provider.selectedState,
        hint: const Text('Select State'),
        items: provider.states.keys.map((stateName) {
          return DropdownMenuItem<String>(
            value: stateName,
            child: Text(stateName),
          );
        }).toList(),
        onChanged: (value) => provider.onStateChanged(value),
      );
    } else {
      // Show this only when a non-India country is selected
      return TextFormField(
        initialValue: 'Not Available',
        readOnly: true,
        enabled: false,
        decoration: const InputDecoration(
          labelText: 'State',
          prefixIcon: Icon(Icons.location_city),
          border: OutlineInputBorder(),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        ),
      );
    }
  }

  Widget _buildProgressStep(String title, int step, BusinessProvider provider) {
    final isCurrentStep = provider.currentPage == step;
    final isCompleted = provider.currentPage > step;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : isCurrentStep
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: Center(
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isCurrentStep
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal,
              color: isCurrentStep
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required Widget child,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              child,
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onPrevious != null) ...[
                    ElevatedButton(
                      onPressed: onPrevious,
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (onNext != null)
                    ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 48),
                      ),
                      child: Consumer<BusinessProvider>(
                        builder: (context, provider, child) {
                          return Text(
                              provider.currentPage == 2 ? 'Finish' : 'Next');
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
