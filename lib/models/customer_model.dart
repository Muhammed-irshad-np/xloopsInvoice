class CustomerModel {
  final String id;
  final String companyName;
  final String? email;
  final String? country;
  final bool vatRegisteredInKSA;
  final String? taxRegistrationNumber;
  final String? city;
  final String? streetAddress;
  final String? buildingNumber;
  final String? district;
  final String? addressAdditionalNumber;
  final String? postalCode;

  CustomerModel({
    required this.id,
    required this.companyName,
    this.email,
    this.country,
    this.vatRegisteredInKSA = false,
    this.taxRegistrationNumber,
    this.city,
    this.streetAddress,
    this.buildingNumber,
    this.district,
    this.addressAdditionalNumber,
    this.postalCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'email': email,
      'country': country,
      'vatRegisteredInKSA': vatRegisteredInKSA,
      'taxRegistrationNumber': taxRegistrationNumber,
      'city': city,
      'streetAddress': streetAddress,
      'buildingNumber': buildingNumber,
      'district': district,
      'addressAdditionalNumber': addressAdditionalNumber,
      'postalCode': postalCode,
    };
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    // Handle both legacy int format and bool format for backward compatibility
    bool isVatRegistered = false;
    if (json['vatRegistered'] != null) {
      isVatRegistered = (json['vatRegistered'] is int)
          ? (json['vatRegistered'] as int) == 1
          : json['vatRegistered'] as bool;
    } else if (json['vatRegisteredInKSA'] != null) {
      if (json['vatRegisteredInKSA'] is int) {
        isVatRegistered = (json['vatRegisteredInKSA'] as int) == 1;
      } else {
        isVatRegistered = json['vatRegisteredInKSA'] as bool;
      }
    }

    return CustomerModel(
      id: json['id'] as String,
      companyName: (json['companyName'] ?? json['name'] ?? '') as String,
      email: json['email'] as String?,
      country: json['country'] as String?,
      vatRegisteredInKSA: isVatRegistered,
      taxRegistrationNumber: json['taxRegistrationNumber'] as String?,
      city: json['city'] as String?,
      streetAddress: (json['streetAddress'] ?? json['address']) as String?,
      buildingNumber: json['buildingNumber'] as String?,
      district: json['district'] as String?,
      addressAdditionalNumber: json['addressAdditionalNumber'] as String?,
      postalCode: json['postalCode'] as String?,
    );
  }

  CustomerModel copyWith({
    String? id,
    String? companyName,
    String? email,
    String? country,
    bool? vatRegisteredInKSA,
    String? taxRegistrationNumber,
    String? city,
    String? streetAddress,
    String? buildingNumber,
    String? district,
    String? addressAdditionalNumber,
    String? postalCode,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      country: country ?? this.country,
      vatRegisteredInKSA: vatRegisteredInKSA ?? this.vatRegisteredInKSA,
      taxRegistrationNumber:
          taxRegistrationNumber ?? this.taxRegistrationNumber,
      city: city ?? this.city,
      streetAddress: streetAddress ?? this.streetAddress,
      buildingNumber: buildingNumber ?? this.buildingNumber,
      district: district ?? this.district,
      addressAdditionalNumber:
          addressAdditionalNumber ?? this.addressAdditionalNumber,
      postalCode: postalCode ?? this.postalCode,
    );
  }
}
