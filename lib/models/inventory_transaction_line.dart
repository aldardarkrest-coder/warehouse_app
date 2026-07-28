class InventoryTransactionLine {
  final String? id;
  final String transactionId;
  final int lineNo;
  final String itemId;
  final String? itemName;
  final String? itemSku;
  final String itemUnitId;
  final String? unitName;
  final String? unitCode;
  final double quantity;
  final double factorToBase;
  final double baseQuantity;
  final String? lotId;
  final String? lotNumber;
  final double unitCost;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InventoryTransactionLine({
    this.id,
    required this.transactionId,
    required this.lineNo,
    required this.itemId,
    this.itemName,
    this.itemSku,
    required this.itemUnitId,
    this.unitName,
    this.unitCode,
    required this.quantity,
    required this.factorToBase,
    this.baseQuantity = 0,
    this.lotId,
    this.lotNumber,
    this.unitCost = 0,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory InventoryTransactionLine.fromJson(Map<String, dynamic> json) {
    final itemData = json['items'] as Map<String, dynamic>?;
    final unitData = json['item_units'] != null
        ? (json['item_units'] as Map<String, dynamic>)['units'] as Map<String, dynamic>?
        : null;
    final lotData = json['inventory_lots'] as Map<String, dynamic>?;
    return InventoryTransactionLine(
      id: json['id'] as String?,
      transactionId: json['transaction_id'] as String,
      lineNo: (json['line_no'] as num).toInt(),
      itemId: json['item_id'] as String,
      itemName: itemData?['name'] as String?,
      itemSku: itemData?['sku'] as String?,
      itemUnitId: json['item_unit_id'] as String,
      unitName: unitData?['name'] as String?,
      unitCode: unitData?['code'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      factorToBase: (json['factor_to_base'] as num).toDouble(),
      baseQuantity: (json['base_quantity'] as num?)?.toDouble() ?? 0,
      lotId: json['lot_id'] as String?,
      lotNumber: lotData?['lot_number'] as String?,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'transaction_id': transactionId,
    'line_no': lineNo,
    'item_id': itemId,
    'item_unit_id': itemUnitId,
    'quantity': quantity,
    'factor_to_base': factorToBase,
    'lot_id': lotId,
    'unit_cost': unitCost,
    'notes': notes,
  };
}
