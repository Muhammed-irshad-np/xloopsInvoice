import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('invoices.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        companyName TEXT NOT NULL,
        country TEXT NOT NULL,
        vatRegistered INTEGER NOT NULL DEFAULT 0,
        taxRegistrationNumber TEXT NOT NULL,
        city TEXT NOT NULL,
        streetAddress TEXT NOT NULL,
        buildingNumber TEXT NOT NULL,
        district TEXT NOT NULL,
        addressAdditionalNumber TEXT,
        postalCode TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Invoices table (for future use)
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        invoiceNumber TEXT UNIQUE NOT NULL,
        date INTEGER NOT NULL,
        contractReference TEXT,
        paymentTerms TEXT NOT NULL,
        customerId TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // Line items table (for future use)
    await db.execute('''
      CREATE TABLE line_items (
        id TEXT PRIMARY KEY,
        invoiceId TEXT NOT NULL,
        description TEXT NOT NULL,
        unit TEXT NOT NULL,
        subtotalAmount REAL NOT NULL,
        discountRate REAL NOT NULL,
        totalAmount REAL NOT NULL,
        itemOrder INTEGER NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id)
      )
    ''');
  }

  // Customer CRUD operations
  Future<void> insertCustomer(CustomerModel customer) async {
    final db = await database;
    await db.insert(
      'customers',
      customer.toJson(forSQLite: true),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CustomerModel>> getAllCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'companyName ASC',
    );

    return List.generate(maps.length, (i) {
      return CustomerModel.fromJson(maps[i]);
    });
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return CustomerModel.fromJson(maps.first);
    }
    return null;
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    final db = await database;
    await db.update(
      'customers',
      customer.toJson(forSQLite: true),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

