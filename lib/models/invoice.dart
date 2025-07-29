import 'dart:convert';

class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int? itemId;
  final String itemName;
  final String description;
  final double unitPrice;
  final double quantity;
  final double totalPrice;

  InvoiceItem({
    this.id,
    this.invoiceId,
    this.itemId,
    required this.itemName,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] is String ? int.parse(map['id']) : map['id'],
      invoiceId: map['invoice_id'] is String ? int.parse(map['invoice_id']) : map['invoice_id'],
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
      'invoice_id': invoiceId,
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

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? itemId,
    String? itemName,
    String? description,
    double? unitPrice,
    double? quantity,
    double? totalPrice,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
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
    return 'InvoiceItem{itemName: $itemName, quantity: $quantity, unitPrice: $unitPrice, totalPrice: $totalPrice}';
  }
}

class Invoice {
  final int? id;
  final int companyId;
  final int clientId;
  final int? quoteId; // Reference to original quote if converted
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String status; // unpaid, partial, paid, cancelled
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final String? notes;
  final List<InvoiceItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Invoice({
    this.id,
    required this.companyId,
    required this.clientId,
    this.quoteId,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.notes,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  double get remainingAmount => totalAmount - paidAmount;
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && status != 'paid';
  bool get isPaid => status == 'paid';
  bool get isPartiallyPaid => paidAmount > 0 && paidAmount < totalAmount && status != 'paid';

  factory Invoice.fromMap(Map<String, dynamic> map) {
    
    // Parse invoice items if they exist
    List<InvoiceItem> invoiceItems = [];
    if (map['items'] != null) {
      if (map['items'] is List) {
        invoiceItems = (map['items'] as List).map((item) => InvoiceItem.fromMap(item)).toList();
      } else if (map['items'] is String) {
        // Handle case where items might be stored as JSON string
        try {
          final itemsJson = json.decode(map['items']);
          if (itemsJson is List) {
            invoiceItems = itemsJson.map((item) => InvoiceItem.fromMap(item)).toList();
          }
        } catch (e) {
          // Silently handle JSON parsing errors
        }
      }
    }
    
    return Invoice(
      id: map['id'] is String ? int.parse(map['id']) : map['id'],
      companyId: map['company_id'] is String ? int.parse(map['company_id']) : map['company_id'],
      clientId: map['client_id'] is String ? int.parse(map['client_id']) : map['client_id'],
      quoteId: map['quote_id'] != null 
          ? (map['quote_id'] is String ? int.parse(map['quote_id']) : map['quote_id'])
          : null,
      invoiceNumber: map['invoice_number'] ?? '',
      invoiceDate: map['invoice_date'] != null 
          ? DateTime.parse(map['invoice_date']) 
          : DateTime.now(), // Default to current date if not provided
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      status: map['status'] ?? 'draft',
      subtotal: map['subtotal'] is String ? double.parse(map['subtotal']) : (map['subtotal'] ?? 0.0).toDouble(),
      taxAmount: map['tax_amount'] is String ? double.parse(map['tax_amount']) : (map['tax_amount'] ?? 0.0).toDouble(),
      totalAmount: map['total_amount'] != null 
          ? (map['total_amount'] is String ? double.parse(map['total_amount']) : map['total_amount'].toDouble())
          : (map['total'] != null 
              ? (map['total'] is String ? double.parse(map['total']) : map['total'].toDouble())
              : 0.0), // Handle both 'total_amount' and 'total' field names
      paidAmount: map['paid_amount'] is String ? double.parse(map['paid_amount']) : (map['paid_amount'] ?? 0.0).toDouble(),
      notes: map['notes'],
      items: invoiceItems,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'client_id': clientId,
      'quote_id': quoteId,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'client_id': clientId.toString(),
      'quote_id': quoteId?.toString(),
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'status': status,
      'subtotal': subtotal.toString(),
      'tax_amount': taxAmount.toString(),
      'total_amount': totalAmount.toString(),
      'paid_amount': paidAmount.toString(),
      'notes': notes ?? '',
      'items': items.map((item) => item.toApiMap()).toList(),
    };
  }

  Invoice copyWith({
    int? id,
    int? companyId,
    int? clientId,
    int? quoteId,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? status,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    double? paidAmount,
    String? notes,
    List<InvoiceItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      clientId: clientId ?? this.clientId,
      quoteId: quoteId ?? this.quoteId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Invoice{id: $id, invoiceNumber: $invoiceNumber, status: $status, totalAmount: $totalAmount}';
  }
}