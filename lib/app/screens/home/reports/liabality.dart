import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:account_book/app/data/model/liability_model.dart';
import 'package:account_book/app/data/model/party_model.dart';

class LiabilitiesScreen extends StatefulWidget {
  const LiabilitiesScreen({super.key});

  @override
  LiabilitiesScreenState createState() => LiabilitiesScreenState();
}

class LiabilitiesScreenState extends State<LiabilitiesScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _searchController = TextEditingController();
  String _filter = 'All';
  bool _isLoading = false;
  List<LiabilityModel> _liabilities = [];
  List<PartyModel> _parties = [];

  @override
  void initState() {
    super.initState();
    _loadLiabilities();
  }

  Future<void> _loadLiabilities() async {
    setState(() => _isLoading = true);

    try {
      final liabilityBox = Hive.box<LiabilityModel>('liabilities');
      final partyBox = Hive.box<PartyModel>('partyBox');

      setState(() {
        _liabilities = liabilityBox.values.toList();
        _parties = partyBox.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error loading liabilities: $e')),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liabilities'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddLiabilityDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLiabilityDialog,
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildSearchBar(),
          _buildSummaryCards(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _liabilities.isEmpty
                    ? Center(child: Text('No liabilities recorded'))
                    : _buildLiabilityList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Text('Filter:'),
          const SizedBox(width: 10),
          ChoiceChip(
            label: const Text('All'),
            selected: _filter == 'All',
            onSelected: (selected) {
              setState(() {
                _filter = 'All';
              });
            },
          ),
          const SizedBox(width: 5),
          ChoiceChip(
            label: const Text('Current'),
            selected: _filter == 'Current',
            onSelected: (selected) {
              setState(() {
                _filter = 'Current';
              });
            },
          ),
          const SizedBox(width: 5),
          ChoiceChip(
            label: const Text('Long-term'),
            selected: _filter == 'Long-term',
            onSelected: (selected) {
              setState(() {
                _filter = 'Long-term';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search liabilities...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSummaryCards() {
    final currentLiabilities = _liabilities
        .where((l) => l.category == 'Current')
        .fold(0.0, (sum, l) => sum + l.amount);

    final longTermLiabilities = _liabilities
        .where((l) => l.category == 'Long-term')
        .fold(0.0, (sum, l) => sum + l.amount);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Current Liabilities',
              currentLiabilities,
              Colors.orange,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Long-term Liabilities',
              longTermLiabilities,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 4),
            Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiabilityList() {
    final filteredLiabilities = _liabilities.where((liability) {
      final matchesFilter = _filter == 'All' || liability.category == _filter;
      final matchesSearch = _searchController.text.isEmpty ||
          liability.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return ListView.builder(
      itemCount: filteredLiabilities.length,
      itemBuilder: (context, index) {
        final liability = filteredLiabilities[index];
        final party = liability.partyId != null
            ? _parties.firstWhere((p) => p.id == liability.partyId,
                orElse: () => PartyModel())
            : null;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(liability.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${liability.category} Liability'),
                if (party != null && party.name != null)
                  Text('Party: ${party.name}'),
                Text(
                    'Date: ${DateFormat('dd-MM-yyyy').format(liability.date)}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(liability.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                if (liability.interestRate != null)
                  Text(
                    '${liability.interestRate}% interest',
                    style: TextStyle(fontSize: 12),
                  ),
              ],
            ),
            onTap: () => _showLiabilityDetails(liability, party),
          ),
        );
      },
    );
  }

  void _showAddLiabilityDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final interestController = TextEditingController();
    final descriptionController = TextEditingController();
    final termsController = TextEditingController();

    String? selectedCategory = 'Current';
    String? selectedPartyId;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Liability'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Liability Name'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: ['Current', 'Long-term'].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedCategory = value;
                  },
                  decoration: InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: interestController,
                  decoration: InputDecoration(labelText: 'Interest Rate (%)'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: selectedPartyId,
                  items: _parties.map((party) {
                    return DropdownMenuItem(
                      value: party.id,
                      child: Text(party.name ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedPartyId = value;
                  },
                  decoration: InputDecoration(labelText: 'Party (Optional)'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration:
                      InputDecoration(labelText: 'Description (Optional)'),
                ),
                TextField(
                  controller: termsController,
                  decoration:
                      InputDecoration(labelText: 'Payment Terms (Optional)'),
                ),
                ListTile(
                  title: Text(
                      'Date: ${DateFormat('dd-MM-yyyy').format(selectedDate)}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      selectedDate = date;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  final newLiability = LiabilityModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    category: selectedCategory!,
                    amount: double.parse(amountController.text),
                    date: selectedDate,
                    partyId: selectedPartyId,
                    description: descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    interestRate: interestController.text.isEmpty
                        ? null
                        : double.parse(interestController.text),
                    paymentTerms: termsController.text.isEmpty
                        ? null
                        : termsController.text,
                  );

                  final liabilityBox = Hive.box<LiabilityModel>('liabilities');
                  await liabilityBox.add(newLiability);

                  Navigator.pop(context);
                  _loadLiabilities();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showLiabilityDetails(LiabilityModel liability, PartyModel? party) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(liability.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Type: ${liability.category} Liability'),
                SizedBox(height: 8),
                Text('Amount: ${currencyFormat.format(liability.amount)}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (liability.interestRate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Interest Rate: ${liability.interestRate}%'),
                  ),
                if (party != null && party.name != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Party: ${party.name}'),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                      'Date: ${DateFormat('dd-MM-yyyy').format(liability.date)}'),
                ),
                if (liability.paymentTerms != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Payment Terms: ${liability.paymentTerms}'),
                  ),
                if (liability.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Description: ${liability.description}'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
