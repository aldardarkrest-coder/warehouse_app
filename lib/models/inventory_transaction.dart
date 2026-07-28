enum TransactionType {
  openingBalance, purchaseReceipt, salesIssue, transfer,
  adjustmentIn, adjustmentOut, customerReturn, supplierReturn, stockCount;

  String get value {
    switch (this) {
      case TransactionType.openingBalance: return 'opening_balance';
      case TransactionType.purchaseReceipt: return 'purchase_receipt';
      case TransactionType.salesIssue: return 'sales_issue';
      case TransactionType.transfer: return 'transfer';
      case TransactionType.adjustmentIn: return 'adjustment_in';
      case TransactionType.adjustmentOut: return 'adjustment_out';
      case TransactionType.customerReturn: return 'customer_return';
      case TransactionType.supplierReturn: return 'supplier_return';
      case TransactionType.stockCount: return 'stock_count';
    }
  }

  String get displayName {
    switch (this) {
      case TransactionType.openingBalance: return 'رصيد افتتاحي';
      case TransactionType.purchaseReceipt: return 'إيصال استلام';
      case TransactionType.salesIssue: return 'صرف مبيعات';
      case TransactionType.transfer: return 'تحويل';
      case TransactionType.adjustmentIn: return 'تسوية إضافة';
      case TransactionType.adjustmentOut: return 'تسوية خصم';
      case TransactionType.customerReturn: return 'مرتجع عميل';
      case TransactionType.supplierReturn: return 'مرتجع مورد';
      case TransactionType.stockCount: return 'جرد';
    }
  }

  static TransactionType fromString(String type) {
    return TransactionType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => TransactionType.openingBalance,
    );
  }
}

enum TransactionStatus { draft, posted, cancelled;

  String get value {
    switch (this) {
      case TransactionStatus.draft: return 'draft';
      case TransactionStatus.posted: return 'posted';
      case TransactionStatus.cancelled: return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case TransactionStatus.draft: return 'مسودة';
      case TransactionStatus.posted: return 'مرحل';
      case TransactionStatus.cancelled: return 'ملغي';
    }
  }

  static TransactionStatus fromString(String status) {
    return TransactionStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => TransactionStatus.draft,
    );
  }
}

class InventoryTransaction {
  final String? id;
  final int? transactionNo;
  final String branchId;
  final String? branchName;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime? transactionDate;
  final String? sourceWarehouseId;
  final String? sourceWarehouseName;
  final String? destinationWarehouseId;
  final String? destinationWarehouseName;
  final String? supplierId;
  final String? supplierName;
  final String? customerId;
  final String? customerName;
  final String? externalReference;
  final String? notes;
  final String createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? postedBy;
  final DateTime? postedAt;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  InventoryTransaction({
    this.id,
    this.transactionNo,
    required this.branchId,
    this.branchName,
    required this.type,
    this.status = TransactionStatus.draft,
    this.transactionDate,
    this.sourceWarehouseId,
    this.sourceWarehouseName,
    this.destinationWarehouseId,
    this.destinationWarehouseName,
    this.supplierId,
    this.supplierName,
    this.customerId,
    this.customerName,
    this.externalReference,
    this.notes,
    required this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
    this.postedBy,
    this.postedAt,
    this.cancelledBy,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    final branchData = json['branches'] as Map<String, dynamic>?;
    final swData = json['source_warehouses'] as Map<String, dynamic>?;
    final dwData = json['destination_warehouses'] as Map<String, dynamic>?;
    final suppData = json['suppliers'] as Map<String, dynamic>?;
    final custData = json['customers'] as Map<String, dynamic>?;
    final profileData = json['profiles'] as Map<String, dynamic>?;
    return InventoryTransaction(
      id: json['id'] as String?,
      transactionNo: (json['transaction_no'] as num?)?.toInt(),
      branchId: json['branch_id'] as String,
      branchName: branchData?['name'] as String?,
      type: TransactionType.fromString(json['transaction_type'] as String),
      status: TransactionStatus.fromString(json['status'] as String? ?? 'draft'),
      transactionDate: json['transaction_date'] != null ? DateTime.parse(json['transaction_date'] as String) : null,
      sourceWarehouseId: json['source_warehouse_id'] as String?,
      sourceWarehouseName: swData?['name'] as String?,
      destinationWarehouseId: json['destination_warehouse_id'] as String?,
      destinationWarehouseName: dwData?['name'] as String?,
      supplierId: json['supplier_id'] as String?,
      supplierName: suppData?['name'] as String?,
      customerId: json['customer_id'] as String?,
      customerName: custData?['name'] as String?,
      externalReference: json['external_reference'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String,
      createdByName: profileData?['full_name'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      postedBy: json['posted_by'] as String?,
      postedAt: json['posted_at'] != null ? DateTime.parse(json['posted_at'] as String) : null,
      cancelledBy: json['cancelled_by'] as String?,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at'] as String) : null,
      cancellationReason: json['cancellation_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'branch_id': branchId,
    'transaction_type': type.value,
    if (transactionDate != null) 'transaction_date': transactionDate!.toIso8601String(),
    'source_warehouse_id': sourceWarehouseId,
    'destination_warehouse_id': destinationWarehouseId,
    'supplier_id': supplierId,
    'customer_id': customerId,
    'external_reference': externalReference,
    'notes': notes,
    'created_by': createdBy,
  };
}
