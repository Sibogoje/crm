class Item {
  final int? id;
  final int companyId;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool isService;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Item({
    this.id,
    required this.companyId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.isService,
    this.createdAt,
    this.updatedAt,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] is String ? int.parse(map['id']) : map['id'],
      companyId: map['company_id'] is String ? int.parse(map['company_id']) : map['company_id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] is String ? double.parse(map['price']) : (map['price'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      isService: map['is_service'] is String ? map['is_service'] == '1' : (map['is_service'] == 1 || map['is_service'] == true),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'is_service': isService,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'name': name,
      'description': description,
      'price': price.toString(),
      'category': category,
      'is_service': isService ? '1' : '0',
    };
  }

  Item copyWith({
    int? id,
    int? companyId,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isService,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isService: isService ?? this.isService,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Item{id: $id, name: $name, price: $price, category: $category, isService: $isService}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
