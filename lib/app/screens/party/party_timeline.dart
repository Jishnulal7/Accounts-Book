import 'package:account_book/app/providers/currency_provider.dart';
import 'package:account_book/app/screens/party/exports.dart';
import 'package:hive_ce/hive.dart';

class PartyTimeline extends StatefulWidget {
  final String partyId;
  final String partyName;

  const PartyTimeline({
    super.key,
    required this.partyId,
    required this.partyName,
  });

  @override
  PartyTimelineState createState() => PartyTimelineState();
}

class PartyTimelineState extends State<PartyTimeline> {
  late PartyModel party = PartyModel();

  // Media query breakpoint
  final double _mobileBreakpoint = 600;

  @override
  void initState() {
    super.initState();
    fetchPartyDetails();
  }

  Future<void> fetchPartyDetails() async {
    final partyBox = await Hive.openBox<PartyModel>('partyBox');
    final partyFromBox = partyBox.get(widget.partyId);
    if (partyFromBox != null) {
      setState(() {
        party = partyFromBox;
        party.id = widget.partyId;
        party.name = widget.partyName;
      });
    }
  }

  Widget _buildInfoSection({
    required String title,
    required Widget content,
    bool showDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        content,
        if (showDivider) ...[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    Widget? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                icon,
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveRow({
    required BuildContext context,
    required List<Widget> children,
    double spacing = 16,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Stack vertically on small screens, horizontally on larger screens
    if (screenWidth < _mobileBreakpoint) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++)
            Padding(
              padding: EdgeInsets.only(
                  bottom: i < children.length - 1 ? spacing : 0),
              child: children[i],
            ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i < children.length - 1) SizedBox(width: spacing),
          ],
        ],
      );
    }
  }

  Widget _buildIdentificationInfo() {
    return _buildResponsiveRow(
      context: context,
      children: [
        _buildInfoCard(
          title: 'GSTIN',
          value: party.gstNumber ?? '--',
        ),
        _buildInfoCard(
          title: 'PAN Number',
          value: party.panNumber ?? '--',
        ),
      ],
    );
  }

  Widget _buildAddressInfo() {
    return _buildResponsiveRow(
      context: context,
      children: [
        _buildInfoCard(
          title: 'Billing Address',
          value: party.billingAddress,
          icon: const Icon(
            Icons.location_on_outlined,
            size: 16,
            color: Colors.black,
          ),
        ),
        _buildInfoCard(
          title: 'Shipping Address',
          value: party.shippingAddress,
          icon: const Icon(
            Icons.local_shipping_outlined,
            size: 16,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceInfo() {
    final currencySymbol =
        Provider.of<CurrencyNotifier>(context).currencySymbol;
    return _buildResponsiveRow(
      context: context,
      children: [
        _buildInfoCard(
          title: 'Credit Period',
          value: party.creditPeriod ?? '--',
        ),
        _buildInfoCard(
          title: 'Credit Limit',
          value: '$currencySymbol  ${(party.creditAmount ?? 0.0).toString()}',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        padding:
            EdgeInsets.all(constraints.maxWidth < _mobileBreakpoint ? 12 : 16),
        child: Column(
          children: [
            _buildInfoSection(
              title: 'Party Info',
              content: Column(
                children: [
                  ContactInfoWidget(
                    icon: Icons.phone_outlined,
                    title: 'Party Name',
                    value: party.name ?? '--',
                    iconColor: AppColor.kPurple,
                    backgroundColor: AppColor.kPurple.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                  ContactInfoWidget(
                    icon: Icons.mail_outline,
                    title: 'Party Email',
                    value: party.email ?? '--',
                    iconColor: AppColor.kPurple,
                    backgroundColor: AppColor.kPurple.withOpacity(0.1),
                  ),
                ],
              ),
            ),
            _buildInfoSection(
              title: 'GST & PAN',
              content: _buildIdentificationInfo(),
            ),
            _buildInfoSection(
              title: 'Address',
              content: _buildAddressInfo(),
            ),
            _buildInfoSection(
              title: 'Balance Details',
              content: _buildBalanceInfo(),
              showDivider: false,
            ),
          ],
        ),
      );
    });
  }
}

class ContactInfoWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color backgroundColor;

  const ContactInfoWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor = Colors.purple,
    this.backgroundColor = const Color(0xFFF3E5F5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'Not Available',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
