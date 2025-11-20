import 'customer_model.dart';
import 'line_item_model.dart';

class InvoiceModel {
  final DateTime date;
  final String invoiceNumber;
  final String contractReference;
  final String paymentTerms;
  final CustomerModel? customer;
  final List<LineItemModel> lineItems;

  InvoiceModel({
    required this.date,
    required this.invoiceNumber,
    required this.contractReference,
    required this.paymentTerms,
    this.customer,
    required this.lineItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'invoiceNumber': invoiceNumber,
      'contractReference': contractReference,
      'paymentTerms': paymentTerms,
      'customer': customer?.toJson(),
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
    };
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      date: DateTime.parse(json['date'] as String),
      invoiceNumber: json['invoiceNumber'] as String,
      contractReference: json['contractReference'] as String,
      paymentTerms: json['paymentTerms'] as String,
      customer: json['customer'] != null
          ? CustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      lineItems: (json['lineItems'] as List)
          .map((item) => LineItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Calculate totals
  double get subtotalAmount {
    return lineItems.fold(0.0, (sum, item) => sum + item.subtotalAmount);
  }

  double get totalDiscount {
    return lineItems.fold(0.0, (sum, item) {
      return sum + (item.subtotalAmount * item.discountRate / 100);
    });
  }

  double get totalAmount {
    return lineItems.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  double get whtAmount {
    return totalAmount * 0.05; // 5% WHT
  }

  double get grandTotal {
    return totalAmount - whtAmount;
  }
}

