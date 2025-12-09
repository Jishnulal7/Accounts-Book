import 'package:account_book/app/screens/home/exports.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        QuickLinksCard(
          onSaleAdded: () =>
              Provider.of<DashboardProvider>(context, listen: false)
                  .refreshData(),
        ),
        if (!Platform.isWindows)
          ReportsQuickLink(
            onSaleAdded: () =>
                Provider.of<DashboardProvider>(context, listen: false)
                    .refreshData(),
          ),
      ],
    );
  }
}
