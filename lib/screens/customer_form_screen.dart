import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../services/storage_service.dart';
import '../widgets/responsive_layout.dart';

class CustomerFormScreen extends StatefulWidget {
  final CustomerModel? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _taxRegController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingNumberController = TextEditingController();
  final _districtController = TextEditingController();
  final _addressAdditionalController = TextEditingController();
  final _postalCodeController = TextEditingController();
  bool _vatRegisteredInKSA = true;
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      final customer = widget.customer!;
      _companyNameController.text = customer.companyName;
      _countryController.text = customer.country;
      _vatRegisteredInKSA = customer.vatRegisteredInKSA;
      _taxRegController.text = customer.taxRegistrationNumber;
      _cityController.text = customer.city;
      _streetController.text = customer.streetAddress;
      _buildingNumberController.text = customer.buildingNumber;
      _districtController.text = customer.district;
      _addressAdditionalController.text =
          customer.addressAdditionalNumber ?? '';
      _postalCodeController.text = customer.postalCode;
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _countryController.dispose();
    _taxRegController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _buildingNumberController.dispose();
    _districtController.dispose();
    _addressAdditionalController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final customer = CustomerModel(
        id:
            widget.customer?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        companyName: _companyNameController.text.trim(),
        country: _countryController.text.trim(),
        vatRegisteredInKSA: _vatRegisteredInKSA,
        taxRegistrationNumber: _taxRegController.text.trim(),
        city: _cityController.text.trim(),
        streetAddress: _streetController.text.trim(),
        buildingNumber: _buildingNumberController.text.trim(),
        district: _districtController.text.trim(),
        addressAdditionalNumber:
            _addressAdditionalController.text.trim().isEmpty
            ? null
            : _addressAdditionalController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      );

      await _storageService.saveCustomer(customer);

      if (mounted) {
        Navigator.pop(context, customer);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ResponsiveLayout(
                mobile: Column(
                  children: [
                    _buildBusinessDetailsSection(),
                    const SizedBox(height: 16),
                    _buildAddressSection(),
                  ],
                ),
                desktop: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildBusinessDetailsSection()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAddressSection()),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Customer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business and VAT Treatment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter company name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Country *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter country';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'VAT Treatment *',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            RadioListTile<bool>(
              title: const Text('Not VAT registered in KSA'),
              value: false,
              groupValue: _vatRegisteredInKSA,
              onChanged: (value) {
                setState(() {
                  _vatRegisteredInKSA = value ?? false;
                });
              },
            ),
            RadioListTile<bool>(
              title: const Text('VAT registered in KSA'),
              value: true,
              groupValue: _vatRegisteredInKSA,
              onChanged: (value) {
                setState(() {
                  _vatRegisteredInKSA = value ?? true;
                });
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _taxRegController,
              decoration: const InputDecoration(
                labelText: 'Tax registration number *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter tax registration number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter city';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street address *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.streetview),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter street address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buildingNumberController,
              decoration: const InputDecoration(
                labelText: 'Building number *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter building number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _districtController,
              decoration: const InputDecoration(
                labelText: 'District *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter district';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressAdditionalController,
              decoration: const InputDecoration(
                labelText: 'Address additional number (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.add_location_alt),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'Postal code *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_post_office),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter postal code';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
