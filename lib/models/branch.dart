class Branch {
  final String? id;
  final String code;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Branch({
    this.id,
    required this.code,
    required this.name,
    this.address,
    this.phone,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String?,
      code: json['code'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'code': code,
    'name': name,
    'address': address,
    'phone': phone,
    'is_active': isActive,
  };
}
