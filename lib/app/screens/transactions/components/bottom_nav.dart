import 'package:account_book/app/screens/transactions/export.dart';

class BottomNavButtons extends StatelessWidget {
  final VoidCallback? onSaveAndNew;
  final VoidCallback onSave;
  final String saveText;

  const BottomNavButtons({
    super.key,
    this.onSaveAndNew,
    required this.onSave,
    required this.saveText,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth >= 1200;

    // Adjust padding based on screen size
    final horizontalPadding = isLargeScreen
        ? 32.0
        : isTablet
            ? 16.0
            : 8.0;

    final verticalPadding = isLargeScreen
        ? 16.0
        : isTablet
            ? 12.0
            : 8.0;

    // Adjust button height based on screen size
    final buttonHeight = isLargeScreen
        ? 48.0
        : isTablet
            ? 44.0
            : 40.0;

    // Adjust spacing between buttons
    final buttonSpacing = isLargeScreen
        ? 16.0
        : isTablet
            ? 12.0
            : 8.0;

    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: onSaveAndNew,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: AppColor.kWhite,
                    textStyle: TextStyle(
                      fontSize: isLargeScreen
                          ? 16
                          : isTablet
                              ? 14
                              : 13,
                      fontWeight: FontWeight.w500,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 24 : 16,
                    ),
                  ),
                  child: Text(saveText),
                ),
              ),
            ),
            SizedBox(width: buttonSpacing),
            Expanded(
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: AppColor.kWhite,
                    textStyle: TextStyle(
                      fontSize: isLargeScreen
                          ? 16
                          : isTablet
                              ? 14
                              : 13,
                      fontWeight: FontWeight.w500,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 24 : 16,
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
