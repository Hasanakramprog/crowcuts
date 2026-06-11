/// Global service catalog entry (e.g. "Haircut", "Beard Trim").
class ServiceModel {
  final String id;
  final String name;
  final String? iconName;
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.name,
    this.iconName,
    this.isActive = true,
  });

  ServiceModel copyWith({
    String? id,
    String? name,
    String? iconName,
    bool? isActive,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconName': iconName,
        'isActive': isActive,
      };

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        iconName: json['iconName'] as String?,
        isActive: json['isActive'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServiceModel($name)';
}
