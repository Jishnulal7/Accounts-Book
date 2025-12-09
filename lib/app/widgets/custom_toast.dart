import 'package:account_book/app/data/constants/colors.dart';
import 'package:account_book/app/data/helpers/enums/toast.dart';
import 'package:flutter/material.dart';

class ToastService {
  /// Shows a toast message
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onDismiss,
  }) {
    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    final ResponsiveValues responsive = ResponsiveValues(screenSize.width);

    // Create an overlay entry for the toast
    final overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return _ToastOverlay(
          message: message,
          type: type,
          duration: duration,
          responsive: responsive,
          onDismiss: () {
            onDismiss?.call();
          },
        );
      },
    );

    // Insert the overlay and remove after duration
    overlay.insert(overlayEntry);
    Future.delayed(duration, () {
      overlayEntry.remove();
      onDismiss?.call();
    });
  }
}



/// Helper class to manage responsive values
class ResponsiveValues {
  final double screenWidth;
  final bool isTablet;
  final bool isLargeScreen;

  ResponsiveValues(this.screenWidth)
      : isTablet = screenWidth > 600 && screenWidth < 1200,
        isLargeScreen = screenWidth >= 1200;

  // Responsive values
  double get horizontalPadding =>
      isLargeScreen ? 32.0 : (isTablet ? 28.0 : 24.0);
  double get verticalPadding => isLargeScreen ? 16.0 : (isTablet ? 14.0 : 12.0);
  double get imageSize => isLargeScreen ? 30.0 : (isTablet ? 28.0 : 25.0);
  double get spacing => isLargeScreen ? 16.0 : (isTablet ? 14.0 : 12.0);
  double get fontSize => isLargeScreen ? 16.0 : (isTablet ? 14.0 : 13.0);
  double get borderRadius => isLargeScreen ? 30.0 : 25.0;
  double get widthPercentage => isLargeScreen ? 0.3 : (isTablet ? 0.4 : 0.6);
  double get bottomPosition =>
      isLargeScreen ? 120.0 : (isTablet ? 110.0 : 100.0);
  double get outerPadding => isLargeScreen ? 12.0 : 8.0;
}

/// A private widget to handle the toast overlay presentation
class _ToastOverlay extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final ResponsiveValues responsive;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.responsive,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();

    // Start fade out animation just before duration ends
    Future.delayed(widget.duration - const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.responsive;

    return Positioned(
      bottom: r.bottomPosition,
      left: (MediaQuery.of(context).size.width * (1 - r.widthPercentage)) / 2,
      right: (MediaQuery.of(context).size.width * (1 - r.widthPercentage)) / 2,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(r.outerPadding),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomToast(
              message: widget.message,
              type: widget.type,
              responsive: r,
            ),
          ),
        ),
      ),
    );
  }
}

/// The actual toast widget that displays the message
class CustomToast extends StatelessWidget {
  final String message;
  final ToastType type;
  final ResponsiveValues responsive;

  const CustomToast({
    super.key,
    required this.message,
    required this.type,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    final r = responsive;
    final toastConfig = _getToastConfigForType(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.horizontalPadding,
        vertical: r.verticalPadding,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.borderRadius),
        color: toastConfig.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            toastConfig.icon,
            color: toastConfig.iconColor,
            size: r.imageSize,
          ),
          SizedBox(width: r.spacing),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: toastConfig.textColor,
                fontSize: r.fontSize,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.start,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Get styling configuration based on toast type
  _ToastConfig _getToastConfigForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastConfig(
          backgroundColor: AppColor.kGrayscaleDark100,
          iconColor: Colors.green,
          textColor: AppColor.kWhite,
          icon: Icons.check_circle,
        );
      case ToastType.error:
        return _ToastConfig(
          backgroundColor: AppColor.kGrayscaleDark100,
          iconColor: Colors.red,
          textColor: AppColor.kWhite,
          icon: Icons.error,
        );
      case ToastType.warning:
        return _ToastConfig(
          backgroundColor: AppColor.kGrayscaleDark100,
          iconColor: Colors.orange,
          textColor: AppColor.kWhite,
          icon: Icons.warning,
        );
      case ToastType.info:
        return _ToastConfig(
          backgroundColor: AppColor.kGrayscaleDark100,
          iconColor: AppColor.kWhite,
          textColor: AppColor.kWhite,
          icon: Icons.info,
        );
    }
  }
}

/// Configuration class for toast styling
class _ToastConfig {
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  _ToastConfig({
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}
