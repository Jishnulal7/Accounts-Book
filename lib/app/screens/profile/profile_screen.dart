import 'package:account_book/app/screens/profile/exports.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Maximum content width for larger screens
  static const double maxContentWidth = 600;

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ElevatedButton(
        onPressed: () {
          // Implement logout functionality
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.white),
            SizedBox(width: 8),
            Text('Logout', style: TextStyle(fontSize: 16, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: _calculateHorizontalPadding(context),
              vertical: 16,
            ),
            children: [
              _buildSectionTitle('Profile'),
              Card(
                child: ListTile(
                  leading:
                      Icon(Icons.person, color: Theme.of(context).primaryColor),
                  title: const Text('Edit Business Profile'),
                  subtitle: const Text('Update your business details'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileEditScreen(),
                        ));
                  },
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              ),
              _buildSectionTitle('Settings'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.color_lens,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: const Text('Theme'),
                      subtitle: const Text('Select your app theme'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ThemeSelectionPage(),
                          ),
                        );
                      },
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      title: 'Currency',
                      image: Icons.currency_exchange,
                      subTitle: 'Select your currency',
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      image: Icons.backup,
                      title: 'BackUp',
                      subTitle: 'Tap here to Backup your data',
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    if (Platform.isAndroid || Platform.isIOS)
                      _buildSettingsTile(
                        image: Icons.lock,
                        title: 'App-Lock',
                        subTitle: 'Tap here to enable Biometrics',
                        onTap: () {},
                      ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      image: Icons.account_balance,
                      title: 'Bank Details',
                      subTitle: 'Tap here to see bank details',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BankDetailsScreen(),
                            ));
                      },
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      image: Icons.remove_circle_outline,
                      title: 'Reset Application Data',
                      subTitle: 'Tap here reset application',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResetAppScreen(),
                            ));
                      },
                    ),
                    const Divider(height: 1),
                  ],
                ),
              ),
              SizedBox(height: 16),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= maxContentWidth) {
      return 16.0; // Default padding for mobile screens
    }
    // For screens wider than maxContentWidth, add extra padding based on screen size
    final extraSpace = (screenWidth - maxContentWidth) / 2;
    return extraSpace > 16 ? 16.0 : extraSpace;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    IconData? image,
    required String title,
    String? subTitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    if (title == 'Currency') {
      return Consumer<CurrencyNotifier>(
        builder: (context, currencyNotifier, child) {
          return ListTile(
            subtitle: Text(subTitle ?? ''),
            leading: Icon(
              image,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: DropdownButton<String>(
              value: currencyNotifier.currencyName,
              items: currencyNotifier.availableCurrencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency['name'],
                  child: Text('${currency['name']} (${currency['symbol']})'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  final selectedCurrency = currencyNotifier.availableCurrencies
                      .firstWhere((currency) => currency['name'] == newValue);
                  currencyNotifier.updateCurrency(
                    selectedCurrency['name']!,
                    selectedCurrency['symbol']!,
                  );
                }
              },
            ),
            onTap: onTap,
          );
        },
      );
    }
    return ListTile(
      leading: Icon(
        image,
        color: Theme.of(context).primaryColor,
      ),
      subtitle: Text(subTitle ?? ''),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
