import 'package:account_book/app/screens/profile/exports.dart';
import 'package:hive_ce/hive.dart';

class ResetAppScreen extends StatefulWidget {
  const ResetAppScreen({super.key});

  @override
  State<ResetAppScreen> createState() => _ResetAppScreenState();
}

class _ResetAppScreenState extends State<ResetAppScreen> {
  bool _isResetting = false;
  String _statusMessage = '';

  // New methods for clearing sales and purchases separately
  Future<void> _clearSalesData() async {
    setState(() {
      _isResetting = true;
      _statusMessage = 'Clearing sales data...';
    });

    try {
      await _clearTypedBox<SaleModel>('saleBox');

      setState(() {
        _statusMessage = 'Sales data cleared successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error clearing sales data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  Future<void> _clearPurchasesData() async {
    setState(() {
      _isResetting = true;
      _statusMessage = 'Clearing purchases data...';
    });

    try {
      await _clearTypedBox<PurchaseModel>('purchaseBox');

      setState(() {
        _statusMessage = 'Purchases data cleared successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error clearing purchases data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  Future<void> _resetAppData() async {
    setState(() {
      _isResetting = true;
      _statusMessage = 'Resetting application data...';
    });

    try {
      // Clear regular boxes
      await _clearRegularBox('themeMode');
      await _clearRegularBox('themeSettings');
      await _clearRegularBox('themeColor');
      await _clearRegularBox('openingStockBox');

      // Clear typed boxes
      await _clearTypedBox<PartyModel>('partyBox');
      await _clearTypedBox<ItemModel>('itemBox');
      await _clearTypedBox<StockAdjustmentModel>('stockAdjustmentBox');
      await _clearTypedBox<TaskModel>('tasks');
      await _clearTypedBox<TransactionModel>('transactions');
      await _clearTypedBox<AttendanceModel>('attendanceBox');
      await _clearTypedBox<SaleModel>('saleBox');
      await _clearTypedBox<PurchaseModel>('purchaseBox');

      // Reset SharedPreferences
      setState(() {
        _statusMessage = 'Clearing SharedPreferences...';
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      setState(() {
        _statusMessage = 'Reset complete! Redirecting to onboarding...';
      });

      // Slight delay to show the success message before navigating
      await Future.delayed(const Duration(seconds: 1));

      // Navigate to onboarding screen and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          (route) => false, // This removes all previous routes
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during reset: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  // Existing helper methods remain the same
  Future<void> _clearRegularBox(String boxName) async {
    setState(() {
      _statusMessage = 'Clearing $boxName...';
    });

    if (Hive.isBoxOpen(boxName)) {
      final box = Hive.box(boxName);
      await box.clear();
    } else {
      final box = await Hive.openBox(boxName);
      await box.clear();
    }
  }

  Future<void> _clearTypedBox<T>(String boxName) async {
    setState(() {
      _statusMessage = 'Clearing $boxName...';
    });

    if (Hive.isBoxOpen(boxName)) {
      final box = Hive.box<T>(boxName);
      await box.clear();
    } else {
      final box = await Hive.openBox<T>(boxName);
      await box.clear();
    }
  }

  // Updated _allBoxes to include separate entries for sales and purchases
  List<String> get _allBoxes => [
        'themeMode',
        'themeSettings',
        'themeColor',
        'partyBox',
        'itemBox',
        'stockAdjustmentBox',
        'tasks',
        'transactions',
        'attendanceBox',
        'saleBox',
        'purchaseBox',
        'openingStockBox',
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Application Data'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 48, color: Colors.orange),
                    SizedBox(height: 8),
                    Text(
                      'Warning: This action cannot be undone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Resetting the application will clear all data including theme settings, parties, items, transactions, tasks, and other stored information. You will be redirected to the onboarding screen.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), 
            Text(
              'Selective Data Clearing Options:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isResetting ? null : _clearSalesData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: const Text('Clear Sales Data'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isResetting ? null : _clearPurchasesData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: const Text('Clear Purchases Data'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'The following data will be reset:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                child: ListView.builder(
                  itemCount: _allBoxes.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: Text(_allBoxes[index]),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('Error')
                        ? Colors.red
                        : _statusMessage.contains('complete') ||
                                _statusMessage.contains('Redirecting')
                            ? Colors.green
                            : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: _isResetting ? null : _resetAppData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: _isResetting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Resetting...',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    )
                  : const Text(
                      'RESET ALL DATA',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
