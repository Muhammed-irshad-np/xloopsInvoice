class LineItemModel {
  final String description;
  final String unit;
  final double subtotalAmount;
  final double discountRate; // Percentage (e.g., 3.0 for 3%)
  final double totalAmount;

  LineItemModel({
    required this.description,
    required this.unit,
    required this.subtotalAmount,
    required this.discountRate,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'unit': unit,
      'subtotalAmount': subtotalAmount,
      'discountRate': discountRate,
      'totalAmount': totalAmount,
    };
  }

  factory LineItemModel.fromJson(Map<String, dynamic> json) {
    return LineItemModel(
      description: json['description'] as String,
      unit: json['unit'] as String,
      subtotalAmount: (json['subtotalAmount'] as num).toDouble(),
      discountRate: (json['discountRate'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }

  LineItemModel copyWith({
    String? description,
    String? unit,
    double? subtotalAmount,
    double? discountRate,
    double? totalAmount,
  }) {
    return LineItemModel(
      description: description ?? this.description,
      unit: unit ?? this.unit,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      discountRate: discountRate ?? this.discountRate,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  // Calculate total amount based on subtotal and discount
  static double calculateTotal(double subtotal, double discountRate) {
    return subtotal * (1 - discountRate / 100);
  }
}

