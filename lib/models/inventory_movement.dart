enum MovementType { in_, out, transfer }

extension MovementTypeExtension on MovementType {
  String get value {
    switch (this) {
      case MovementType.in_:
        return 'in';
      case MovementType.out:
        return 'out';
      case MovementType.transfer:
        return 'transfer';
    }
  }

  String get displayName {
    switch (this) {
      case MovementType.in_:
        return 'إدخال';
      case MovementType.out:
        return 'إخراج';
      case MovementType.transfer:
        return 'تحويل';
    }
  }

  static MovementType fromString(String type) {
    switch (type) {
      case 'in':
        return MovementType.in_;
      case 'out':
        return MovementType.out;
      case 'transfer':
        return MovementType.transfer;
      default:
        return MovementType.in_;
    }
  }
}

class InventoryMovement {
  final String? id;
  final String itemId;
  final String? itemName;
  final String warehouseId;
  final String? warehouseName;
  final MovementType type;
  final double quantity;
  final String? referenceType;
  final String? referenceId;
  final String? notes;
  final String createdBy;
  final String? createdByName;
  final DateTime? createdAt;

  InventoryMovement({
    this.id,
    required this.itemId,
    this.itemName,
    required this.warehouseId,
    this.warehouseName,
    required this.type,
    required this.quantity,
    this.referenceType,
    this.referenceId,
    this.notes,
    required this.createdBy,
    this.createdByName,
    this.createdAt,
  });

  factory InventoryMovement.fromJson(Map<String, dynamic> json) {
    return InventoryMovement(
      id: json['id'] as String?,
      itemId: json['item_id'] as String,
      itemName: json['items'] != null
          ? (json['items'] as Map<String, dynamic>)['name'] as String?
          : null,
      warehouseId: json['warehouse_id'] as String,
      warehouseName: json['warehouses'] != null
          ? (json['warehouses'] as Map<String, dynamic>)['name'] as String?
          : null,
      type: MovementTypeExtension.fromString(json['type'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String,
      createdByName: json['profiles'] != null
          ? (json['profiles'] as Map<String, dynamic>)['full_name'] as String?
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'item_id': itemId,
    'warehouse_id': warehouseId,
    'type': type.value,
    'quantity': quantity,
    'reference_type': referenceType,
    'reference_id': referenceId,
    'notes': notes,
    'created_by': createdBy,
  };
}

class InventoryItem {
  final String? id;
  final String itemId;
  final String? itemName;
  final String? itemSku;
  final String warehouseId;
  final String? warehouseName;
  final double quantity;
  final double? minStockLevel;

  InventoryItem({
    this.id,
    required this.itemId,
    this.itemName,
    this.itemSku,
    required this.warehouseId,
    this.warehouseName,
    required this.quantity,
    this.minStockLevel,
  });

  bool get isLowStock => minStockLevel != null && quantity <= minStockLevel!;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final itemData = json['items'] as Map<String, dynamic>?;
    final warehouseData = json['warehouses'] as Map<String, dynamic>?;
    return InventoryItem(
      id: json['id'] as String?,
      itemId: json['item_id'] as String,
      itemName: itemData?['name'] as String?,
      itemSku: itemData?['sku'] as String?,
      warehouseId: json['warehouse_id'] as String,
      warehouseName: warehouseData?['name'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      minStockLevel: (itemData?['min_stock_level'] as num?)?.toDouble(),
    );
  }
}
