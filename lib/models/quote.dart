import 'dart:convert';

class QuoteItem {
  final int? id;
  final int? quoteId;
  final int? itemId;
  final String itemName;
  final String description;
  final double unitPrice;
  final double quantity; // Changed from int to double
  final double totalPrice;

  QuoteItem({
    this.id,
    this.quoteId,
    this.itemId,
    required this.itemName,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
  });

  factory QuoteItem.fromMap(Map<String, dynamic> map) {
    return QuoteItem(
      id: map['id'] is String ? int.parse(map['id']) : map['id'],
      quoteId: map['quote_id'] is String ? int.parse(map['quote_id']) : map['quote_id'],
      itemId: map['item_id'] is String ? int.parse(map['item_id']) : map['item_id'],
      itemName: map['item_name'] ?? '',
      description: map['description'] ?? '',
      unitPrice: map['unit_price'] is String ? double.parse(map['unit_price']) : (map['unit_price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] is String ? double.parse(map['quantity']) : (map['quantity'] ?? 1.0).toDouble(),
      totalPrice: map['total_price'] is String ? double.parse(map['total_price']) : (map['total_price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote_id': quoteId,
      'item_id': itemId,
      'item_name': itemName,
      'description': description,
      'unit_price': unitPrice,
      'quantity': quantity,
      'total_price': totalPrice,
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'item_id': itemId?.toString(),
      'item_name': itemName,
      'description': description,
      'unit_price': unitPrice.toString(),
      'quantity': quantity.toString(),
      'total_price': totalPrice.toString(),
    };
  }

  QuoteItem copyWith({
    int? id,
    int? quoteId,
    int? itemId,
    String? itemName,
    String? description,
    double? unitPrice,
    double? quantity, // Changed from int to double
    double? totalPrice,
  }) {
    return QuoteItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  String toString() {
    return 'QuoteItem{itemName: $itemName, quantity: $quantity, unitPrice: $unitPrice, totalPrice: $totalPrice}';
  }
}



class Quote {
  final int? id;
  final int companyId;
  final int clientId;
  final String quoteNumber;
  final DateTime quoteDate;
  final DateTime? expiryDate;
  final String status; // draft, sent, accepted, rejected, expired
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String? notes;
  final List<QuoteItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Quote({
    this.id,
    required this.companyId,
    required this.clientId,
    required this.quoteNumber,
    required this.quoteDate,
    this.expiryDate,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    this.notes,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  factory Quote.fromMap(Map<String, dynamic> map) {
    
    // Parse quote items if they exist
    List<QuoteItem> quoteItems = [];
    if (map['items'] != null) {
      if (map['items'] is List) {
        quoteItems = (map['items'] as List).map((item) => QuoteItem.fromMap(item)).toList();
      } else if (map['items'] is String) {
        // Handle case where items might be stored as JSON string
        try {
          final itemsJson = json.decode(map['items']);
          if (itemsJson is List) {
            quoteItems = itemsJson.map((item) => QuoteItem.fromMap(item)).toList();
          }
        } catch (e) {
          // Silently handle JSON parsing errors
        }
      }
    }
    
    return Quote(
      id: map['id'] is String ? int.parse(map['id']) : map['id'],
      companyId: map['company_id'] is String ? int.parse(map['company_id']) : map['company_id'],
      clientId: map['client_id'] is String ? int.parse(map['client_id']) : map['client_id'],
      quoteNumber: map['quote_number'] ?? '',
      quoteDate: DateTime.parse(map['quote_date']),
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date']) : null,
      status: map['status'] ?? 'draft',
      subtotal: map['subtotal'] is String ? double.parse(map['subtotal']) : (map['subtotal'] ?? 0.0).toDouble(),
      taxAmount: map['tax_amount'] is String ? double.parse(map['tax_amount']) : (map['tax_amount'] ?? 0.0).toDouble(),
      totalAmount: map['total_amount'] is String ? double.parse(map['total_amount']) : (map['total_amount'] ?? 0.0).toDouble(),
      notes: map['notes'],
      items: quoteItems,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'client_id': clientId,
      'quote_number': quoteNumber,
      'quote_date': quoteDate.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'status': status,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'client_id': clientId.toString(),
      'quote_number': quoteNumber,
      'quote_date': quoteDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'status': status,
      'subtotal': subtotal.toString(),
      'tax_amount': taxAmount.toString(),
      'total_amount': totalAmount.toString(),
      'notes': notes ?? '',
      'items': items.map((item) => item.toApiMap()).toList(),
    };
  }

  Quote copyWith({
    int? id,
    int? companyId,
    int? clientId,
    String? quoteNumber,
    DateTime? quoteDate,
    DateTime? expiryDate,
    String? status,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    String? notes,
    List<QuoteItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quote(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      clientId: clientId ?? this.clientId,
      quoteNumber: quoteNumber ?? this.quoteNumber,
      quoteDate: quoteDate ?? this.quoteDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Quote{id: $id, quoteNumber: $quoteNumber, status: $status, totalAmount: $totalAmount}';
  }
}
