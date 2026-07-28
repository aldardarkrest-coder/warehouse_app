class Customer {
  final String? id;
  final String? code;
  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    this.id,
    this.code,
    required this.name,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String?,
      code: json['code'] as String?,
      name: json['name'] as String,
      contactPerson: json['contact_person'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'code': code,
    'name': name,
    'contact_person': contactPerson,
    'email': email,
    'phone': phone,
    'address': address,
    'is_active': isActive,
  };
}
