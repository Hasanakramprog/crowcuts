/// Customer rating for a barber after a completed booking.
class RatingModel {
  final String id;
  final String bookingId;
  final String customerId;
  final String customerName;
  final String barberId;
  final double stars; // 1.0 to 5.0, increments of 0.5
  final String? comment;
  final DateTime createdAt;

  const RatingModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    this.customerName = '',
    required this.barberId,
    required this.stars,
    this.comment,
    required this.createdAt,
  });

  RatingModel copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? customerName,
    String? barberId,
    double? stars,
    String? comment,
    DateTime? createdAt,
  }) {
    return RatingModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      barberId: barberId ?? this.barberId,
      stars: stars ?? this.stars,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'customerId': customerId,
        'customerName': customerName,
        'barberId': barberId,
        'stars': stars,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RatingModel.fromJson(Map<String, dynamic> json) => RatingModel(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String? ?? '',
        barberId: json['barberId'] as String,
        stars: (json['stars'] as num).toDouble(),
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RatingModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'RatingModel($stars stars for barber $barberId)';
}
