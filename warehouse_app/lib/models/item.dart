class Item {
  final String? id;
  final String name;
  final String? description;
  final String sku;
  final String? categoryId;
  final String? categoryName;
  final String unit;
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
    this.unit = 'piece',
    this.minStockLevel = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: json['categories'] != null
          ? (json['categories'] as Map<String, dynamic>)['name'] as String?
          : null,
      unit: json['unit'] as String? ?? 'piece',
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
    'unit': unit,
    'min_stock_level': minStockLevel,
    'is_active': isActive,
  };
}
