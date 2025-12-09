import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class TransportationDetails extends StatefulWidget {
  final TextEditingController transportationNameController;
  final TextEditingController vehicleNumberController;
  final TextEditingController deliveryDateController;
  final TextEditingController deliveryLocationController;
  final List<String> transportationDetails;

  const TransportationDetails({
    super.key,
    required this.transportationNameController,
    required this.vehicleNumberController,
    required this.deliveryDateController,
    required this.deliveryLocationController,
    required this.transportationDetails,
  });

  @override
  State<TransportationDetails> createState() => _TransportationDetailsState();
}

class _TransportationDetailsState extends State<TransportationDetails> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => _showDetailsSheet(context),
          icon: const Icon(Icons.local_shipping),
          label: const Text('Transportation Details'),
        ),
        if (widget.transportationDetails.isNotEmpty) ...[
          Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🚛 Transport Name: ${widget.transportationDetails[0]}'),
                  Text('🚗 Vehicle Number: ${widget.transportationDetails[1]}'),
                  Text('📅 Delivery Date: ${widget.transportationDetails[2]}'),
                  Text('📍 Location: ${widget.transportationDetails[3]}'),
                ],
              ),
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: const Text('No transportation details added yet'),
          ),
        ],
      ],
    );
  }

  Future<void> _showDetailsSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHeader(),
              const SizedBox(height: 24),
              _buildTransportNameField(),
              const SizedBox(height: 16),
              _buildVehicleNumberField(),
              const SizedBox(height: 16),
              _buildDateField(context),
              const SizedBox(height: 16),
              _buildLocationField(),
              const SizedBox(height: 24),
              _buildSaveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Transportation Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransportNameField() {
    return TextFormField(
      controller: widget.transportationNameController,
      decoration: InputDecoration(
        labelText: 'Transport Name',
        hintText: 'Enter transport company name',
        prefixIcon: const Icon(Icons.business),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter transport name';
        }
        return null;
      },
    );
  }

  Widget _buildVehicleNumberField() {
    return TextFormField(
      controller: widget.vehicleNumberController,
      decoration: InputDecoration(
        labelText: 'Vehicle Number',
        hintText: 'Enter vehicle registration number',
        prefixIcon: const Icon(Icons.directions_car),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter vehicle number';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(BuildContext context) {
    return TextFormField(
      controller: widget.deliveryDateController,
      decoration: InputDecoration(
        labelText: 'Delivery Date',
        hintText: 'Select delivery date',
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      readOnly: true,
      onTap: () => _selectDate(context),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select delivery date';
        }
        return null;
      },
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: widget.deliveryLocationController,
      decoration: InputDecoration(
        labelText: 'Delivery Location',
        hintText: 'Enter delivery address',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter delivery location';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      widget.deliveryDateController.text =
          DateFormat('dd MMM yyyy').format(picked);
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        widget.transportationDetails
          ..clear()
          ..addAll([
            widget.transportationNameController.text,
            widget.vehicleNumberController.text,
            widget.deliveryDateController.text,
            widget.deliveryLocationController.text,
          ]);

        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transportation details saved successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
