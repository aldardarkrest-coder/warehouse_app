enum UserRole { admin, warehouseManager, employee, accountant }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.warehouseManager:
        return 'warehouse_manager';
      case UserRole.employee:
        return 'employee';
      case UserRole.accountant:
        return 'accountant';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'مدير النظام';
      case UserRole.warehouseManager:
        return 'مدير مستودع';
      case UserRole.employee:
        return 'موظف';
      case UserRole.accountant:
        return 'محاسب';
    }
  }

  static UserRole fromString(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'warehouse_manager':
        return UserRole.warehouseManager;
      case 'accountant':
        return UserRole.accountant;
      default:
        return UserRole.employee;
    }
  }
}

class Profile {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: UserRoleExtension.fromString(json['role'] as String),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'role': role.value,
    'is_active': isActive,
  };
}
