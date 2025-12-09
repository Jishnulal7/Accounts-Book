import 'package:account_book/app/screens/transactions/export.dart';
import 'package:intl/intl.dart';

class InvoiceBottomSheet extends StatefulWidget {
  final TextEditingController dateController;
  final DateTime invoiceDate;
  final String initialInvoiceNumber;
  final Function(String, DateTime, PrefixType, String) onSave;
  final Function(DateTime) onDateChanged;
  final PrefixType initialPrefixType;
  final String initialCustomPrefix;

  const InvoiceBottomSheet({
    super.key,
    required this.dateController,
    required this.invoiceDate,
    required this.initialInvoiceNumber,
    required this.onSave,
    required this.onDateChanged,
    this.initialPrefixType = PrefixType.none,
    this.initialCustomPrefix = '',
  });

  @override
  InvoiceBottomSheetState createState() => InvoiceBottomSheetState();
}

class InvoiceBottomSheetState extends State<InvoiceBottomSheet> {
  late String newInvoiceNumber;
  late DateTime newInvoiceDate;
  late PrefixType selectedPrefix;
  late String customPrefix;
  List<SavedPrefix> savedPrefixes = [];
  SavedPrefix? selectedSavedPrefix;
  bool isLoading = true;
  final TextEditingController invoiceNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    newInvoiceNumber = widget.initialInvoiceNumber;
    invoiceNumberController.text = widget.initialInvoiceNumber;
    newInvoiceDate = widget.invoiceDate;
    selectedPrefix = widget.initialPrefixType;
    customPrefix = widget.initialCustomPrefix;

    // Load saved prefixes after widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedPrefixes();
    });
  }

  @override
  void dispose() {
    invoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPrefixes() async {
    try {
      setState(() => isLoading = true);

      // Get saved prefixes
      final prefixes = await PrefixManager.getSavedPrefixes();

      if (mounted) {
        setState(() {
          savedPrefixes = prefixes;

          // Find and set the selected saved prefix if we have a matching prefix
          if (customPrefix.isNotEmpty) {
            for (var prefix in savedPrefixes) {
              if (prefix.code == customPrefix) {
                selectedSavedPrefix = prefix;

                // If initial type is saved or we found a matching saved prefix and we're in custom mode
                if (selectedPrefix == PrefixType.saved ||
                    (customPrefix.isNotEmpty &&
                        selectedPrefix == PrefixType.custom)) {
                  selectedPrefix = PrefixType.saved;
                }
                break;
              }
            }
          }

          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved prefixes: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showPrefixDialog() {
    final TextEditingController prefixController =
        TextEditingController(text: customPrefix);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Custom Prefix'),
          content: TextField(
            controller: prefixController,
            maxLength: 3,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Enter 3 letter prefix',
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final tempPrefix = prefixController.text.toUpperCase();

                if (tempPrefix.isNotEmpty && tempPrefix.length <= 3) {
                  // Save the prefix to shared preferences
                  final newPrefix = SavedPrefix(code: tempPrefix);
                  await PrefixManager.savePrefix(newPrefix);

                  // Reload the saved prefixes
                  final updatedPrefixes =
                      await PrefixManager.getSavedPrefixes();

                  if (mounted) {
                    setState(() {
                      savedPrefixes = updatedPrefixes;
                      customPrefix = tempPrefix;
                      selectedPrefix = PrefixType.saved;

                      // Find and select the saved prefix
                      for (var prefix in savedPrefixes) {
                        if (prefix.code == tempPrefix) {
                          selectedSavedPrefix = prefix;
                          break;
                        }
                      }
                    });
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showManagePrefixesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, dialogSetState) {
          return AlertDialog(
            title: const Text('Manage Saved Prefixes'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300, // Fixed height to ensure dialog is properly sized
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : savedPrefixes.isEmpty
                      ? const Center(child: Text('No saved prefixes'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: savedPrefixes.length,
                          itemBuilder: (context, index) {
                            final prefix = savedPrefixes[index];
                            final bool isSelected =
                                selectedPrefix == PrefixType.saved &&
                                    selectedSavedPrefix != null &&
                                    selectedSavedPrefix!.code == prefix.code;

                            return Card(
                              color: isSelected
                                  ? Colors.blue.withOpacity(0.1)
                                  : null,
                              elevation: isSelected ? 2 : 1,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(
                                  prefix.code,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                leading: isSelected
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.blue)
                                    : const Icon(Icons.circle_outlined),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    // If we're deleting the currently selected prefix, reset the selection
                                    if (isSelected) {
                                      setState(() {
                                        selectedPrefix = PrefixType.none;
                                        selectedSavedPrefix = null;
                                        customPrefix = '';
                                      });
                                    }

                                    await PrefixManager.removePrefix(
                                        prefix.code);

                                    // Update state in both dialogs
                                    final updatedPrefixes =
                                        await PrefixManager.getSavedPrefixes();
                                    if (mounted) {
                                      setState(() {
                                        savedPrefixes = updatedPrefixes;
                                      });
                                    }

                                    dialogSetState(() {
                                      savedPrefixes = updatedPrefixes;
                                    });
                                  },
                                ),
                                onTap: () {
                                  // Update state for the main component
                                  setState(() {
                                    selectedPrefix = PrefixType.saved;
                                    selectedSavedPrefix = prefix;
                                    customPrefix = prefix.code;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showPrefixDialog();
                },
                child: const Text('Add New'),
              ),
            ],
          );
        });
      },
    );
  }

  // ignore: unused_element
  Widget _buildPrefixSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Invoice Prefix',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextButton(
              onPressed: () {
                if (isLoading) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Loading prefixes... Please wait')));
                  return;
                }
                _showManagePrefixesDialog();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Manage Prefixes'),
                  if (isLoading)
                    const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          children: [
            _buildRadioTile(PrefixType.none, 'None'),
            _buildRadioTile(PrefixType.inv, 'INV'),
            _buildRadioTile(
                PrefixType.custom,
                customPrefix.isNotEmpty && selectedPrefix == PrefixType.custom
                    ? customPrefix
                    : 'Add Custom'),
            if (savedPrefixes.isNotEmpty)
              _buildRadioTile(
                  PrefixType.saved,
                  selectedPrefix == PrefixType.saved &&
                          selectedSavedPrefix != null
                      ? selectedSavedPrefix!.code
                      : 'Saved Prefixes'),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioTile(PrefixType value, String label) {
    return InkWell(
      onTap: () {
        if (value == PrefixType.custom &&
            (selectedPrefix != PrefixType.custom || customPrefix.isEmpty)) {
          _showPrefixDialog();
        } else if (value == PrefixType.saved &&
            selectedSavedPrefix == null &&
            savedPrefixes.isNotEmpty) {
          _showManagePrefixesDialog();
        } else {
          setState(() {
            selectedPrefix = value;
          });
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<PrefixType>(
            value: value,
            groupValue: selectedPrefix,
            onChanged: (PrefixType? newValue) {
              if (newValue == PrefixType.custom &&
                  (selectedPrefix != PrefixType.custom ||
                      customPrefix.isEmpty)) {
                _showPrefixDialog();
              } else if (newValue == PrefixType.saved &&
                  selectedSavedPrefix == null &&
                  savedPrefixes.isNotEmpty) {
                _showManagePrefixesDialog();
              } else if (newValue != null) {
                setState(() {
                  selectedPrefix = newValue;
                });
              }
            },
          ),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Invoice Date & Number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // _buildPrefixSelector(),
              const SizedBox(height: 10),
              const Text(
                'Invoice Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: CustomTextField(
                  controller: widget.dateController,
                  onChanged: (newValue) {
                    setState(() {
                      newInvoiceNumber = newValue;
                    });
                  },
                  onTap: () {
                    selectMonthYear(context);
                  },
                  hintText: DateFormat('dd MMM y').format(newInvoiceDate),
                  readOnly: true,
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Invoice Number',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              CustomTextField(
                controller: invoiceNumberController,
                onChanged: (newValue) {
                  setState(() {
                    newInvoiceNumber = widget.initialInvoiceNumber;
                  });
                },
                keyboardType: TextInputType.number,
                hintText: widget.initialInvoiceNumber,
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                onTap: () {
                  final effectivePrefix = selectedPrefix == PrefixType.saved &&
                          selectedSavedPrefix != null
                      ? selectedSavedPrefix!.code
                      : (selectedPrefix == PrefixType.custom
                          ? customPrefix
                          : '');

                  // Validate invoice number is not empty
                  if (invoiceNumberController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Invoice number cannot be empty')),
                    );
                    return;
                  }

                  widget.onSave(
                    invoiceNumberController.text,
                    newInvoiceDate,
                    selectedPrefix,
                    effectivePrefix,
                  );
                  Navigator.pop(context, {
                    'invoiceNumber': invoiceNumberController.text,
                    'invoiceDate': newInvoiceDate,
                    'prefixType': selectedPrefix,
                    'customPrefix': effectivePrefix,
                  });
                },
                text: 'Save',
                textColor: AppColor.kWhite,
                bgColor: AppColor.kPrimary,
                borderRadius: 10,
                width: width,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void selectMonthYear(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: newInvoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Invoice Date',
    );

    if (selectedDate != null && mounted) {
      setState(() {
        newInvoiceDate = selectedDate;
        widget.dateController.text =
            DateFormat('dd MMM y').format(selectedDate);
      });
      widget.onDateChanged(selectedDate);
    }
  }
}
