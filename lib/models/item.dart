class Item {
  final String? id;
  final String name;
  final String? description;
  final String sku;
  final String? categoryId;
  final String? categoryName;
  final String baseUnitId;
  final String? baseUnitName;
  final String? baseUnitSymbol;
  final bool trackBatch;
  final bool trackExpiry;
  final double minStockLevel;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Item({
    this.id,
    required this.name,
    this.description,
    required this.sku,
    this.categoryId,
    this.categoryName,
    required this.baseUnitId,
    this.baseUnitName,
    this.baseUnitSymbol,
    this.trackBatch = false,
    this.trackExpiry = false,
    this.minStockLevel = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    final unitData = json['base_unit'] as Map<String, dynamic>?;
    return Item(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: json['categories'] != null
          ? (json['categories'] as Map<String, dynamic>)['name'] as String?
          : null,
      baseUnitId: json['base_unit_id'] as String,
      baseUnitName: unitData?['name'] as String?,
      baseUnitSymbol: unitData?['symbol'] as String?,
      trackBatch: json['track_batch'] as bool? ?? false,
      trackExpiry: json['track_expiry'] as bool? ?? false,
      minStockLevel: (json['min_stock_level'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'description': description,
    'sku': sku,
    'category_id': categoryId,
    'base_unit_id': baseUnitId,
    'track_batch': trackBatch,
    'track_expiry': trackExpiry,
    'min_stock_level': minStockLevel,
    'is_active': isActive,
  };
}
