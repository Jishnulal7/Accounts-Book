import 'package:account_book/app/screens/profile/exports.dart';

class ThemeSelectionPage extends StatelessWidget {
  const ThemeSelectionPage({super.key});

  static const double maxContentWidth = 600;

  double _calculateHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= maxContentWidth) {
      return 16.0;
    }
    final extraSpace = (screenWidth - maxContentWidth) / 2;
    return extraSpace > 24 ? 24.0 : extraSpace;
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final horizontalPadding = _calculateHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThemeModeSection(context, themeNotifier),
                const SizedBox(height: 32),
                _buildColorSection(context, themeNotifier),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeModeSection(
      BuildContext context, ThemeNotifier themeNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 16),
          child: Text(
            'App Theme',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 500;
            if (isWideScreen) {
              return Row(
                children: [
                  Expanded(
                    child: _buildThemeModeCard(
                      context: context,
                      icon: Icons.brightness_auto,
                      title: 'System Default',
                      subtitle: 'Follow system theme',
                      isSelected: themeNotifier.themeMode == ThemeMode.system,
                      onTap: () => themeNotifier.setTheme(ThemeMode.system),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThemeModeCard(
                      context: context,
                      icon: Icons.light_mode,
                      title: 'Light Theme',
                      subtitle: 'Clean, bright appearance',
                      isSelected: themeNotifier.themeMode == ThemeMode.light,
                      onTap: () => themeNotifier.setTheme(ThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThemeModeCard(
                      context: context,
                      icon: Icons.dark_mode,
                      title: 'Dark Theme',
                      subtitle: 'Easy on the eyes',
                      isSelected: themeNotifier.themeMode == ThemeMode.dark,
                      onTap: () => themeNotifier.setTheme(ThemeMode.dark),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _buildThemeModeCard(
                  context: context,
                  icon: Icons.brightness_auto,
                  title: 'System Default',
                  subtitle: 'Follow system theme',
                  isSelected: themeNotifier.themeMode == ThemeMode.system,
                  onTap: () => themeNotifier.setTheme(ThemeMode.system),
                ),
                const SizedBox(height: 12),
                _buildThemeModeCard(
                  context: context,
                  icon: Icons.light_mode,
                  title: 'Light Theme',
                  subtitle: 'Clean, bright appearance',
                  isSelected: themeNotifier.themeMode == ThemeMode.light,
                  onTap: () => themeNotifier.setTheme(ThemeMode.light),
                ),
                const SizedBox(height: 12),
                _buildThemeModeCard(
                  context: context,
                  icon: Icons.dark_mode,
                  title: 'Dark Theme',
                  subtitle: 'Easy on the eyes',
                  isSelected: themeNotifier.themeMode == ThemeMode.dark,
                  onTap: () => themeNotifier.setTheme(ThemeMode.dark),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildThemeModeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorSection(BuildContext context, ThemeNotifier themeNotifier) {
    final colors = [
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.teal,
      Colors.cyan,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accent Color',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 500;
            final itemWidth = isWideScreen ? 72.0 : 60.0;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((color) {
                // Compare color values instead of color objects
                final isSelected =
                    themeNotifier.themeColor.value == color.value;
                return GestureDetector(
                  onTap: () => themeNotifier.setThemeColor(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: itemWidth,
                    height: itemWidth,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
