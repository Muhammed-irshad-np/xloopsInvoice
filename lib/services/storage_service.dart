import '../models/customer_model.dart';
import 'database_service.dart';

class StorageService {
  final _dbService = DatabaseService.instance;

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
}
