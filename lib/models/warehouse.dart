class Warehouse {
  final String? id;
  final String branchId;
  final String? branchName;
  final String code;
  final String name;
  final String? location;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Warehouse({
    this.id,
    required this.branchId,
    this.branchName,
    required this.code,
    required this.name,
    this.location,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    final branchData = json['branches'] as Map<String, dynamic>?;
    return Warehouse(
      id: json['id'] as String?,
      branchId: json['branch_id'] as String,
      branchName: branchData?['name'] as String?,
      code: json['code'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'branch_id': branchId,
    'code': code,
    'name': name,
    'location': location,
    'is_active': isActive,
  };
}
