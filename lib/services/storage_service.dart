import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import 'database_service.dart';

class StorageService {
  final _dbService = DatabaseService.instance;
  static const String _invoiceDraftKey = 'invoice_draft';

  // Customer CRUD operations
  Future<List<CustomerModel>> getCustomers() async {
    return await _dbService.getAllCustomers();
  }

  Future<void> saveCustomer(CustomerModel customer) async {
    await _dbService.insertCustomer(customer);
  }

  Future<void> deleteCustomer(String customerId) async {
    await _dbService.deleteCustomer(customerId);
  }

  // Invoice Draft operations
  Future<void> saveInvoiceDraft(InvoiceModel invoice) async {
    final prefs = await SharedPreferences.getInstance();
    final invoiceJson = jsonEncode(invoice.toJson());
    await prefs.setString(_invoiceDraftKey, invoiceJson);
  }

  Future<InvoiceModel?> getInvoiceDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final invoiceJson = prefs.getString(_invoiceDraftKey);
    if (invoiceJson != null) {
      try {
        return InvoiceModel.fromJson(jsonDecode(invoiceJson));
      } catch (e) {
        // If parsing fails, clear the corrupted draft
        await clearInvoiceDraft();
        return null;
      }
    }
    return null;
  }

  Future<void> clearInvoiceDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_invoiceDraftKey);
  }
}
