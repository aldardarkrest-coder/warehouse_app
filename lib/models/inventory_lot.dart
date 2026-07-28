class InventoryLot {
  final String? id;
  final String itemId;
  final String? itemName;
  final String lotNumber;
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final String? supplierId;
  final String? supplierName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InventoryLot({
    this.id,
    required this.itemId,
    this.itemName,
    required this.lotNumber,
    this.manufactureDate,
    this.expiryDate,
    this.supplierId,
    this.supplierName,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory InventoryLot.fromJson(Map<String, dynamic> json) {
    final itemData = json['items'] as Map<String, dynamic>?;
    final supplierData = json['suppliers'] as Map<String, dynamic>?;
    return InventoryLot(
      id: json['id'] as String?,
      itemId: json['item_id'] as String,
      itemName: itemData?['name'] as String?,
      lotNumber: json['lot_number'] as String,
      manufactureDate: json['manufacture_date'] != null ? DateTime.parse(json['manufacture_date'] as String) : null,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date'] as String) : null,
      supplierId: json['supplier_id'] as String?,
      supplierName: supplierData?['name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'item_id': itemId,
    'lot_number': lotNumber,
    'manufacture_date': manufactureDate?.toIso8601String(),
    'expiry_date': expiryDate?.toIso8601String(),
    'supplier_id': supplierId,
    'is_active': isActive,
  };
}
