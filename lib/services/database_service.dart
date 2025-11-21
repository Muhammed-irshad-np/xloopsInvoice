import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:xloop_invoice/models/invoice_model.dart';
import 'package:xloop_invoice/models/line_item_model.dart';
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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Invoices table
    await db.execute('''
      CREATE TABLE invoices(
        id TEXT PRIMARY KEY,
        date INTEGER,
        invoiceNumber TEXT,
        contractReference TEXT,
        paymentTerms TEXT,
        customerId TEXT,
        taxRate REAL DEFAULT 5.0,
        createdAt INTEGER
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE customers(
        id TEXT PRIMARY KEY,
        companyName TEXT,
        country TEXT,
        vatRegisteredInKSA INTEGER,
        taxRegistrationNumber TEXT,
        city TEXT,
        streetAddress TEXT,
        buildingNumber TEXT,
        district TEXT,
        addressAdditionalNumber TEXT,
        postalCode TEXT
      )
    ''');

    // Line items table
    await db.execute('''
      CREATE TABLE line_items(
        id TEXT PRIMARY KEY,
        invoiceId TEXT,
        description TEXT,
        referenceCode TEXT,
        unit TEXT,
        unitType TEXT DEFAULT "LOT",
        subtotalAmount REAL,
        discountRate REAL,
        totalAmount REAL,
        itemOrder INTEGER,
        FOREIGN KEY(invoiceId) REFERENCES invoices(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE line_items ADD COLUMN unitType TEXT DEFAULT "LOT"',
      );
      await db.execute('ALTER TABLE line_items ADD COLUMN referenceCode TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE invoices ADD COLUMN taxRate REAL DEFAULT 5.0',
      );
    }
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
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Invoice Operations

  Future<String> generateNewInvoiceNumber() async {
    final db = await database;
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // Count invoices for today to generate sequence
    // Pattern: TRA-YYYYMMDD-SEQ
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM invoices WHERE invoiceNumber LIKE 'TRA-$dateStr-%'",
    );

    final count = Sqflite.firstIntValue(result) ?? 0;
    final sequence = (count + 1).toString().padLeft(3, '0');

    return 'TRA-$dateStr-$sequence';
  }

  Future<void> insertInvoice(InvoiceModel invoice) async {
    final db = await database;

    print('DEBUG INSERT: Saving invoice with ID: ${invoice.id}');
    print('DEBUG INSERT: Invoice has ${invoice.lineItems.length} line items');

    await db.transaction((txn) async {
      // Insert invoice
      final invoiceMap = invoice.toJson(forSQLite: true);
      print('DEBUG INSERT: Invoice map ID: ${invoiceMap['id']}');

      await txn.insert(
        'invoices',
        invoiceMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert line items
      for (var i = 0; i < invoice.lineItems.length; i++) {
        final item = invoice.lineItems[i];
        final itemMap = item.toJson();
        itemMap['id'] =
            DateTime.now().millisecondsSinceEpoch.toString() +
            i.toString(); // Simple ID generation
        itemMap['invoiceId'] = invoice.id;
        itemMap['itemOrder'] = i;

        print(
          'DEBUG INSERT: Line item $i - invoiceId: ${itemMap['invoiceId']}, desc: ${itemMap['description']}, amount: ${itemMap['subtotalAmount']}',
        );

        await txn.insert(
          'line_items',
          itemMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print(
        'DEBUG INSERT: Successfully saved ${invoice.lineItems.length} line items',
      );
    });
  }

  Future<List<InvoiceModel>> getAllInvoices({int? month, int? year}) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (month != null && year != null) {
      // Filter by month and year
      // SQLite stores date as millisecondsSinceEpoch
      final startDate = DateTime(year, month, 1).millisecondsSinceEpoch;
      final endDate = DateTime(year, month + 1, 1).millisecondsSinceEpoch;
      whereClause = 'WHERE i.date >= ? AND i.date < ?';
      whereArgs = [startDate, endDate];
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT i.id as invoice_id, i.*, c.* 
      FROM invoices i
      LEFT JOIN customers c ON i.customerId = c.id
      $whereClause
      ORDER BY i.date DESC
    ''', whereArgs);

    print('DEBUG RETRIEVE: Found ${maps.length} invoices in database');

    List<InvoiceModel> invoices = [];

    for (var map in maps) {
      final invoiceId = map['invoice_id'];
      print('DEBUG RETRIEVE: Processing invoice ID: $invoiceId');

      // Extract customer data
      CustomerModel? customer;
      if (map['customerId'] != null) {
        customer = await getCustomerById(map['customerId']);
      }

      // Fetch line items
      final lineItemsResult = await db.query(
        'line_items',
        where: 'invoiceId = ?',
        whereArgs: [invoiceId.toString()],
        orderBy: 'itemOrder ASC',
      );

      print(
        'DEBUG RETRIEVE: Invoice $invoiceId has ${lineItemsResult.length} line items in DB',
      );
      for (var itemMap in lineItemsResult) {
        print(
          '  - Item: ${itemMap['description']} = ${itemMap['subtotalAmount']}',
        );
      }

      final lineItems = lineItemsResult
          .map((itemMap) => LineItemModel.fromJson(itemMap))
          .toList();

      print(
        'DEBUG RETRIEVE: Converted to ${lineItems.length} LineItemModel objects',
      );

      // Ensure the map passed to InvoiceModel has the correct ID
      final invoiceMap = Map<String, dynamic>.from(map);
      invoiceMap['id'] = invoiceId;

      invoices.add(
        InvoiceModel.fromMap(invoiceMap, customer: customer, items: lineItems),
      );
    }

    return invoices;
  }

  Future<Map<String, dynamic>> getAnalytics({int? month, int? year}) async {
    // Get all invoices for the period
    final invoices = await getAllInvoices(month: month, year: year);

    // Calculate total revenue and other metrics
    double totalRevenue = 0;
    double totalTax = 0;
    double totalDiscount = 0;
    int invoiceCount = invoices.length;

    for (var invoice in invoices) {
      totalRevenue += invoice.grandTotal;
      totalTax += invoice.taxAmount;
      totalDiscount += invoice.totalDiscount;
    }

    double averageInvoiceValue = invoiceCount > 0
        ? totalRevenue / invoiceCount
        : 0;

    // Get monthly revenue breakdown (last 6 months)
    final now = DateTime.now();
    List<Map<String, dynamic>> monthlyRevenue = [];

    for (int i = 5; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final monthInvoices = await getAllInvoices(
        month: targetMonth.month,
        year: targetMonth.year,
      );

      double monthTotal = 0;
      for (var invoice in monthInvoices) {
        monthTotal += invoice.grandTotal;
      }

      monthlyRevenue.add({
        'month': targetMonth.month,
        'year': targetMonth.year,
        'revenue': monthTotal,
        'count': monthInvoices.length,
      });
    }

    // Get top customers by revenue
    Map<String, Map<String, dynamic>> customerRevenue = {};

    for (var invoice in invoices) {
      if (invoice.customer != null) {
        final customerId = invoice.customer!.id;
        if (!customerRevenue.containsKey(customerId)) {
          customerRevenue[customerId] = {
            'customer': invoice.customer,
            'revenue': 0.0,
            'invoiceCount': 0,
          };
        }
        customerRevenue[customerId]!['revenue'] += invoice.grandTotal;
        customerRevenue[customerId]!['invoiceCount'] += 1;
      }
    }

    // Sort customers by revenue and get top 5
    final topCustomers = customerRevenue.values.toList()
      ..sort(
        (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
      );
    final top5Customers = topCustomers.take(5).toList();

    return {
      'totalRevenue': totalRevenue,
      'invoiceCount': invoiceCount,
      'averageInvoiceValue': averageInvoiceValue,
      'totalTax': totalTax,
      'totalDiscount': totalDiscount,
      'monthlyRevenue': monthlyRevenue,
      'topCustomers': top5Customers,
    };
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final db = await database;

    await db.transaction((txn) async {
      // Delete line items first (foreign key constraint)
      await txn.delete(
        'line_items',
        where: 'invoiceId = ?',
        whereArgs: [invoiceId],
      );

      // Delete invoice
      await txn.delete('invoices', where: 'id = ?', whereArgs: [invoiceId]);
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
