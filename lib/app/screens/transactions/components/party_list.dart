import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/transactions/export.dart';

class PartyList extends StatelessWidget {
  final List<PartyModel> parties;
  final Function(PartyModel) onSelectParty;

  const PartyList({
    super.key,
    required this.parties,
    required this.onSelectParty,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth >= 1200;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final partyProvider = Provider.of<PartyProvider>(context);
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;

    final double titleFontSize = isLargeScreen
        ? 15.0
        : isTablet
            ? 14.0
            : 13.0;
    final double subtitleFontSize = isLargeScreen
        ? 14.0
        : isTablet
            ? 13.0
            : 12.0;
    final double verticalPadding = isLargeScreen
        ? 12.0
        : isTablet
            ? 10.0
            : 8.0;

    return ListView.separated(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: parties.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: isDark ? Colors.grey[800] : Colors.grey[200],
      ),
      itemBuilder: (context, index) {
        final party = parties[index];
        final balance = partyProvider.calculatePartyBalance(party.name ?? '');

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              onSelectParty(party);
              FocusScope.of(context).unfocus();
            },
            splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
            highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: verticalPadding,
                horizontal: isLargeScreen ? 16.0 : 12.0,
              ),
              decoration: BoxDecoration(
                color:
                    isDark ? Colors.grey[900]?.withOpacity(0.3) : Colors.white,
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context)
                        .primaryColor
                        .withOpacity(balance >= 0 ? 0.5 : 0.0),
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                    radius: isLargeScreen
                        ? 20
                        : isTablet
                            ? 18
                            : 16,
                    child: Icon(
                      Icons.person,
                      size: isLargeScreen
                          ? 18
                          : isTablet
                              ? 16
                              : 14,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          party.name!,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[100] : Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (party.contactNumber?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: subtitleFontSize,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                party.contactNumber ?? '',
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$currencySymbol ${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w500,
                        color:
                            balance >= 0 ? Colors.green[700] : Colors.red[700],
                      ),
                      textAlign: TextAlign.end,
                    ),
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
