class LineItemModel {
  final String description;
  final String unit; // Quantity value (e.g., "1", "5")
  final String unitType; // "LOT" or "EA"
  final String?
  referenceCode; // Optional item reference/number between EN & AR text
  final double subtotalAmount;
  // final double discountRate; // Removed per-item discount
  final double totalAmount;

  LineItemModel({
    required this.description,
    required this.unit,
    String? unitType,
    this.referenceCode,
    required this.subtotalAmount,
    // required this.discountRate,
    required this.totalAmount,
  }) : unitType = unitType ?? 'LOT';

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'unit': unit,
      'unitType': unitType,
      'referenceCode': referenceCode,
      'subtotalAmount': subtotalAmount,
      // 'discountRate': discountRate,
      'totalAmount': totalAmount,
    };
  }

  factory LineItemModel.fromJson(Map<String, dynamic> json) {
    return LineItemModel(
      description: json['description'] as String,
      unit: json['unit'] as String,
      unitType: (json['unitType'] ?? 'LOT') as String,
      referenceCode: json['referenceCode'] as String?,
      subtotalAmount: (json['subtotalAmount'] as num).toDouble(),
      // discountRate: (json['discountRate'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }

  LineItemModel copyWith({
    String? description,
    String? unit,
    String? unitType,
    String? referenceCode,
    double? subtotalAmount,
    // double? discountRate,
    double? totalAmount,
  }) {
    return LineItemModel(
      description: description ?? this.description,
      unit: unit ?? this.unit,
      unitType: unitType ?? this.unitType,
      referenceCode: referenceCode ?? this.referenceCode,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      // discountRate: discountRate ?? this.discountRate,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  // Calculate total amount based on unit price and quantity
  static double calculateTotal(double unitPrice, String quantity) {
    final qty = double.tryParse(quantity) ?? 0.0;
    return unitPrice * qty;
  }
}
