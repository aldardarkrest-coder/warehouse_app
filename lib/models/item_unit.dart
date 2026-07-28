class ItemUnit {
  final String? id;
  final String itemId;
  final String unitId;
  final String? unitName;
  final String? unitSymbol;
  final String? unitCode;
  final double factorToBase;
  final String? barcode;
  final bool isBase;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ItemUnit({
    this.id,
    required this.itemId,
    required this.unitId,
    this.unitName,
    this.unitSymbol,
    this.unitCode,
    required this.factorToBase,
    this.barcode,
    this.isBase = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ItemUnit.fromJson(Map<String, dynamic> json) {
    final unitData = json['units'] as Map<String, dynamic>?;
    return ItemUnit(
      id: json['id'] as String?,
      itemId: json['item_id'] as String,
      unitId: json['unit_id'] as String,
      unitName: unitData?['name'] as String?,
      unitSymbol: unitData?['symbol'] as String?,
      unitCode: unitData?['code'] as String?,
      factorToBase: (json['factor_to_base'] as num).toDouble(),
      barcode: json['barcode'] as String?,
      isBase: json['is_base'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'item_id': itemId,
    'unit_id': unitId,
    'factor_to_base': factorToBase,
    'barcode': barcode,
    'is_base': isBase,
    'is_active': isActive,
  };
}
