class Receipt {
  final int? id;
  final int companyId;
  final int invoiceId;
  final String receiptNumber;
  final double amount;
  final String paymentMethod; // cash, check, credit_card, bank_transfer, other
  final String? paymentReference;
  final String? notes;
  final DateTime? createdAt;
  
  // Additional fields from joins
  final String? invoiceNumber;
  final String? clientName;

  Receipt({
    this.id,
    required this.companyId,
    required this.invoiceId,
    required this.receiptNumber,
    required this.amount,
    required this.paymentMethod,
    this.paymentReference,
    this.notes,
    this.createdAt,
    this.invoiceNumber,
    this.clientName,
  });

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'] is String ? int.parse(map['id']) : map['id'],
      companyId: map['company_id'] is String ? int.parse(map['company_id']) : map['company_id'],
      invoiceId: map['invoice_id'] is String ? int.parse(map['invoice_id']) : map['invoice_id'],
      receiptNumber: map['receipt_number'] ?? '',
      amount: map['amount'] is String ? double.parse(map['amount']) : (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: map['payment_method'] ?? 'cash',
      paymentReference: map['payment_reference'],
      notes: map['notes'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      invoiceNumber: map['invoice_number'],
      clientName: map['client_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'invoice_id': invoiceId,
      'receipt_number': receiptNumber,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'invoice_id': invoiceId.toString(),
      'amount': amount.toString(),
      'payment_method': paymentMethod,
      'payment_reference': paymentReference ?? '',
      'notes': notes ?? '',
    };
  }

  Receipt copyWith({
    int? id,
    int? companyId,
    int? invoiceId,
    String? receiptNumber,
    double? amount,
    String? paymentMethod,
    String? paymentReference,
    String? notes,
    DateTime? createdAt,
    String? invoiceNumber,
    String? clientName,
  }) {
    return Receipt(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      invoiceId: invoiceId ?? this.invoiceId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientName: clientName ?? this.clientName,
    );
  }

  String get formattedPaymentMethod {
    switch (paymentMethod.toLowerCase()) {
      case 'credit_card':
        return 'Credit Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'check':
        return 'Check';
      case 'cash':
        return 'Cash';
      case 'other':
        return 'Other';
      default:
        return paymentMethod;
    }
  }

  @override
  String toString() {
    return 'Receipt{id: $id, receiptNumber: $receiptNumber, amount: $amount, paymentMethod: $paymentMethod}';
  }
}
