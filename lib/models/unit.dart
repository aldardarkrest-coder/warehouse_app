class Unit {
  final String? id;
  final String code;
  final String name;
  final String? symbol;
  final int decimalPlaces;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Unit({
    this.id,
    required this.code,
    required this.name,
    this.symbol,
    this.decimalPlaces = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as String?,
      code: json['code'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String?,
      decimalPlaces: (json['decimal_places'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'code': code,
    'name': name,
    'symbol': symbol,
    'decimal_places': decimalPlaces,
    'is_active': isActive,
  };
}
