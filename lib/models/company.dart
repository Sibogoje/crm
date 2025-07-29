class Company {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String taxId;
  final String? logoPath;
  final String currency;
  final double defaultTaxRate;
  final String invoicePrefix;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.taxId,
    this.logoPath,
    this.currency = 'USD',
    this.defaultTaxRate = 0.0,
    this.invoicePrefix = 'INV',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'taxId': taxId,
      'logoPath': logoPath,
      'currency': currency,
      'defaultTaxRate': defaultTaxRate,
      'invoicePrefix': invoicePrefix,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      taxId: map['taxId']?.toString() ?? '',
      logoPath: map['logoPath']?.toString(),
      currency: map['currency']?.toString() ?? 'USD',
      defaultTaxRate: map['defaultTaxRate']?.toDouble() ?? 0.0,
      invoicePrefix: map['invoicePrefix']?.toString() ?? 'INV',
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) 
          : DateTime.now(),
    );
  }

  Company copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? taxId,
    String? logoPath,
    String? currency,
    double? defaultTaxRate,
    String? invoicePrefix,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      logoPath: logoPath ?? this.logoPath,
      currency: currency ?? this.currency,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
