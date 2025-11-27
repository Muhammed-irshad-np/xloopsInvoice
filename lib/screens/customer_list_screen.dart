import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../services/storage_service.dart';
import 'customer_form_screen.dart';
import '../widgets/responsive_layout.dart';

class CustomerListScreen extends StatefulWidget {
  final Function(CustomerModel)? onCustomerSelected;
  final bool isSelectionMode;

  const CustomerListScreen({
    super.key,
    this.onCustomerSelected,
    this.isSelectionMode = false,
  });

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _storageService = StorageService();
  List<CustomerModel> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final customers = await _storageService.getCustomers();
    setState(() {
      _customers = customers;
      _isLoading = false;
    });
  }

  Future<void> _deleteCustomer(CustomerModel customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete ${customer.companyName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteCustomer(customer.id);
      _loadCustomers();
    }
  }

  Future<void> _navigateToForm(CustomerModel? customer) async {
    final result = await Navigator.push<CustomerModel>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerFormScreen(customer: customer),
      ),
    );

    if (result != null) {
      _loadCustomers();
    }
  }

  void _showCustomerDetails(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.companyName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Company', customer.companyName),
              _buildDetailRow('Country', customer.country),
              _buildDetailRow('City', customer.city),
              _buildDetailRow('Address', customer.streetAddress),
              _buildDetailRow('Building', customer.buildingNumber),
              _buildDetailRow('District', customer.district),
              _buildDetailRow('Postal Code', customer.postalCode),
              if (customer.addressAdditionalNumber != null &&
                  customer.addressAdditionalNumber!.isNotEmpty)
                _buildDetailRow(
                  'Additional No.',
                  customer.addressAdditionalNumber!,
                ),
              _buildDetailRow(
                'VAT Registered',
                customer.vatRegisteredInKSA ? 'Yes' : 'No',
              ),
              _buildDetailRow(
                'Tax Reg. Number',
                customer.taxRegistrationNumber,
              ),
            ],
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
              _navigateToForm(customer);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToForm(null),
            tooltip: 'Add Customer',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _customers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No customers yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToForm(null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Customer'),
                  ),
                ],
              ),
            )
          : ResponsiveLayout(
              mobile: ListView.builder(
                itemCount: _customers.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) =>
                    _buildCustomerCard(_customers[index]),
              ),
              desktop: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _customers.length,
                itemBuilder: (context, index) =>
                    _buildCustomerCard(_customers[index]),
              ),
            ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(customer.companyName),
        subtitle: Text(
          '${customer.streetAddress}, ${customer.city}\nVAT: ${customer.vatRegisteredInKSA ? 'Registered' : 'Not registered'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToForm(customer),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteCustomer(customer),
              color: Colors.red,
            ),
          ],
        ),
        onTap: () {
          if (widget.isSelectionMode || widget.onCustomerSelected != null) {
            if (widget.onCustomerSelected != null) {
              widget.onCustomerSelected!(customer);
            }
            Navigator.pop(context, customer);
          } else {
            _showCustomerDetails(customer);
          }
        },
      ),
    );
  }
}
