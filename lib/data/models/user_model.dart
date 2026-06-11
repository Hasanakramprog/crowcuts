/// User role enum
enum UserRole { customer, barber, admin }

/// Represents an authenticated user in the system.
class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;
  final String? barberId; // set if role == barber
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.barberId,
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    String? barberId,
    bool clearBarberId = false,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      barberId: clearBarberId ? null : barberId ?? this.barberId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role.name,
        'barberId': barberId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
        role: UserRole.values.firstWhere((r) => r.name == json['role']),
        barberId: json['barberId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserModel(id: $id, name: $name, role: ${role.name})';
}
