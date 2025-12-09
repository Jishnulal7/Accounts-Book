import 'package:account_book/app/data/model/transaction_model.dart';
import 'package:account_book/app/screens/yarima_wallet/attendance/attendance_screen.dart';
import 'package:account_book/app/screens/yarima_wallet/category/category_section.dart';
import 'package:account_book/app/screens/yarima_wallet/category/general_category.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';


class CategoryScreen extends StatefulWidget {
  final VoidCallback? onCategoryAdded;
  final DateTime selectDate;

  const CategoryScreen({
    this.onCategoryAdded,
    super.key,
    required this.selectDate,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final Box<TransactionModel> transactionBox =
      Hive.box<TransactionModel>('transactions');
  DateTime selectedMonth = DateTime.now();
  TextEditingController searchController = TextEditingController();

  void _navigateToCategorySection(Widget section) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => section));
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLandscape = screenSize.width > screenSize.height;
    final bool isTablet = screenSize.width > 600;
    final bool isWideScreen = screenSize.width > 1200;

    // Calculate adaptive padding based on screen width
    final double horizontalPadding =
        screenSize.width * (isWideScreen ? 0.1 : 0.05);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16.0,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Determine layout based on screen size
              if (isWideScreen) {
                // Very wide screens - limit width and use 3 columns
                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 3.0,
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                      children: _buildCategoryCards(constraints.maxWidth / 3),
                    ),
                  ),
                );
              } else if (isTablet && isLandscape) {
                // Tablet landscape layout - grid with 2 columns
                return GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  children: _buildCategoryCards(constraints.maxWidth / 2),
                );
              } else if (isTablet || isLandscape) {
                // Tablet portrait or phone landscape - grid with 2 columns
                return GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.8,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  children: _buildCategoryCards(constraints.maxWidth / 2),
                );
              } else {
                // Phone portrait - single column list
                return ListView.separated(
                  itemCount: 4,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16.0),
                  itemBuilder: (context, index) =>
                      _buildCategoryCards(constraints.maxWidth)[index],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryCards([double maxWidth = 400]) {
    return [
      _buildCategoryCard(
        title: 'Receipt Categories',
        image: 'assets/categories/receipt.png',
        onTap: () => _navigateToCategorySection(
          CategorySection(
            title: 'Receipt Categories',
            transactionType: TransactionType.receipt,
            transactionBox: transactionBox,
            selectedMonth: selectedMonth,
          ),
        ),
        maxWidth: maxWidth,
      ),
      _buildCategoryCard(
        title: 'Payment Categories',
        image: 'assets/categories/payment.png',
        onTap: () => _navigateToCategorySection(
          CategorySection(
            title: 'Payment Categories',
            transactionType: TransactionType.payment,
            transactionBox: transactionBox,
            selectedMonth: selectedMonth,
          ),
        ),
        maxWidth: maxWidth,
      ),
      _buildCategoryCard(
        title: 'General Categories',
        image: 'assets/categories/category.png',
        onTap: () => _navigateToCategorySection(
          GeneralCategorySection(
            transactionBox: transactionBox,
            selectedMonth: selectedMonth,
            onCategoryAdded: () {
              setState(() {});
            },
          ),
        ),
        maxWidth: maxWidth,
      ),
      _buildCategoryCard(
        title: 'Attendance Categories',
        image: 'assets/categories/attendance.png',
        onTap: () => _navigateToCategorySection(const AttendanceScreen()),
        maxWidth: maxWidth,
      ),
    ];
  }

  Widget _buildCategoryCard({
    required String title,
    required String image,
    required VoidCallback onTap,
    required double maxWidth,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes with maximums to prevent oversizing on wide screens
        final double cardWidth = constraints.maxWidth;

        // Adjust image size with upper limits
        final double baseImageSize = cardWidth * 0.1;
        final double imageSize = baseImageSize.clamp(24.0, 40.0);

        // Adjust font size with upper limits
        final double baseFontSize = cardWidth * 0.045;
        final double fontSize = baseFontSize.clamp(14.0, 18.0);

        // Adjust padding with upper limits
        final double basePadding = cardWidth * 0.04;
        final double padding = basePadding.clamp(12.0, 20.0);

        return GestureDetector(
          onTap: onTap,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                children: [
                  Image.asset(
                    image,
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: padding),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: imageSize * 0.8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
