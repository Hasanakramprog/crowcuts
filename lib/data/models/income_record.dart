/// Auto-created when a booking is marked `completed`.
/// Financial records are immutable.
class IncomeRecord {
  final String id;
  final String bookingId;
  final String barberId;
  final String barberName;
  final List<String> serviceIds;
  final List<String> serviceNames;
  final double amount;
  final DateTime date;

  const IncomeRecord({
    required this.id,
    required this.bookingId,
    required this.barberId,
    this.barberName = '',
    required this.serviceIds,
    this.serviceNames = const [],
    required this.amount,
    required this.date,
  });

  IncomeRecord copyWith({
    String? id,
    String? bookingId,
    String? barberId,
    String? barberName,
    List<String>? serviceIds,
    List<String>? serviceNames,
    double? amount,
    DateTime? date,
  }) {
    return IncomeRecord(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      barberId: barberId ?? this.barberId,
      barberName: barberName ?? this.barberName,
      serviceIds: serviceIds ?? this.serviceIds,
      serviceNames: serviceNames ?? this.serviceNames,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'barberId': barberId,
        'barberName': barberName,
        'serviceIds': serviceIds,
        'serviceNames': serviceNames,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory IncomeRecord.fromJson(Map<String, dynamic> json) => IncomeRecord(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        barberId: json['barberId'] as String,
        barberName: json['barberName'] as String? ?? '',
        serviceIds: (json['serviceIds'] as List<dynamic>?)?.cast<String>() ?? [],
        serviceNames: (json['serviceNames'] as List<dynamic>?)?.cast<String>() ?? [],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'IncomeRecord(\$${amount.toStringAsFixed(2)}, ${date.toIso8601String()})';
}
