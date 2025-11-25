import 'customer_model.dart';
import 'line_item_model.dart';

class InvoiceModel {
  final String? id; // UUID for database
  final DateTime date;
  final String invoiceNumber;
  final String contractReference;
  final String paymentTerms;
  final CustomerModel? customer;
  final List<LineItemModel> lineItems;
  final double taxRate; // WHT Rate, default 5.0
  final double discount; // Global discount rate (%)

  InvoiceModel({
    this.id,
    required this.date,
    required this.invoiceNumber,
    required this.contractReference,
    required this.paymentTerms,
    this.customer,
    required this.lineItems,
    this.taxRate = 5.0,
    this.discount = 0.0,
  });

  Map<String, dynamic> toJson({bool forSQLite = false}) {
    final map = {
      'date': date.toIso8601String(),
      'invoiceNumber': invoiceNumber,
      'contractReference': contractReference,
      'paymentTerms': paymentTerms,
      'taxRate': taxRate,
      'discount': discount,
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
    };

    if (id != null) {
      map['id'] = id!;
    }

    if (forSQLite) {
      map['date'] = date.millisecondsSinceEpoch;
      map['createdAt'] = DateTime.now().millisecondsSinceEpoch;
      if (customer != null) {
        map['customerId'] = customer!.id;
      }
      // Line items are saved separately in SQLite
      map.remove('lineItems');
    } else {
      map['customer'] = customer?.toJson() as Object;
    }

    return map;
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String?,
      date: DateTime.parse(json['date'] as String),
      invoiceNumber: json['invoiceNumber'] as String,
      contractReference: json['contractReference'] as String,
      paymentTerms: json['paymentTerms'] as String,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 5.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      customer: json['customer'] != null
          ? CustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      lineItems: (json['lineItems'] as List)
          .map((item) => LineItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Factory for creating from SQLite join query
  factory InvoiceModel.fromMap(
    Map<String, dynamic> map, {
    CustomerModel? customer,
    List<LineItemModel>? items,
  }) {
    return InvoiceModel(
      id: map['id'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      invoiceNumber: map['invoiceNumber'] as String,
      contractReference: map['contractReference'] as String,
      paymentTerms: map['paymentTerms'] as String,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 5.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      customer: customer,
      lineItems: items ?? [],
    );
  }

  // Calculate totals
  double get subtotalAmount {
    return lineItems.fold(0.0, (sum, item) => sum + item.subtotalAmount);
  }

  double get totalDiscount {
    return lineItems.fold(0.0, (sum, item) {
      return sum + (item.subtotalAmount * discount / 100);
    });
  }

  double get totalAmount {
    return subtotalAmount - totalDiscount;
  }

  double get taxAmount {
    return totalAmount * (taxRate / 100);
  }

  double get grandTotal {
    return totalAmount + taxAmount;
  }
}
