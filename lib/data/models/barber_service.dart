/// A service offered by a specific barber with their price and duration.
class BarberService {
  final String serviceId; // references global Service catalog
  final String name;
  final double price;
  final int durationMinutes;
  final bool isAvailable;

  const BarberService({
    required this.serviceId,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.isAvailable = true,
  });

  BarberService copyWith({
    String? serviceId,
    String? name,
    double? price,
    int? durationMinutes,
    bool? isAvailable,
  }) {
    return BarberService(
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'name': name,
        'price': price,
        'durationMinutes': durationMinutes,
        'isAvailable': isAvailable,
      };

  factory BarberService.fromJson(Map<String, dynamic> json) => BarberService(
        serviceId: json['serviceId'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        durationMinutes: json['durationMinutes'] as int,
        isAvailable: json['isAvailable'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarberService &&
          runtimeType == other.runtimeType &&
          serviceId == other.serviceId;

  @override
  int get hashCode => serviceId.hashCode;

  @override
  String toString() => 'BarberService($name, \$${price.toStringAsFixed(2)}, ${durationMinutes}min)';
}
