import 'package:flutter/material.dart';

/// Booking status enum
enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow;

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.noShow:
        return 'No Show';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return const Color(0xFFE89040);
      case BookingStatus.confirmed:
        return const Color(0xFF4CAF7D);
      case BookingStatus.inProgress:
        return const Color(0xFF5B8DEF);
      case BookingStatus.completed:
        return const Color(0xFF7A7672);
      case BookingStatus.cancelled:
        return const Color(0xFFE05555);
      case BookingStatus.noShow:
        return const Color(0xFFE05555);
    }
  }
}

/// Represents a booking/appointment.
class BookingModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String barberId;
  final List<String> serviceIds;
  final List<String> serviceNames;
  final List<double> servicePrices;
  final List<int> serviceDurations;
  final DateTime date;
  final TimeOfDay startTime;
  final int totalDurationMinutes;
  final double totalPrice;
  final BookingStatus status;
  final DateTime createdAt;
  final String? cancellationReason;
  final bool isRated;

  const BookingModel({
    required this.id,
    required this.customerId,
    this.customerName = '',
    this.customerPhone = '',
    required this.barberId,
    required this.serviceIds,
    this.serviceNames = const [],
    this.servicePrices = const [],
    this.serviceDurations = const [],
    required this.date,
    required this.startTime,
    this.totalDurationMinutes = 0,
    this.totalPrice = 0.0,
    this.status = BookingStatus.pending,
    required this.createdAt,
    this.cancellationReason,
    this.isRated = false,
  });

  BookingModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? barberId,
    List<String>? serviceIds,
    List<String>? serviceNames,
    List<double>? servicePrices,
    List<int>? serviceDurations,
    DateTime? date,
    TimeOfDay? startTime,
    int? totalDurationMinutes,
    double? totalPrice,
    BookingStatus? status,
    DateTime? createdAt,
    String? cancellationReason,
    bool? isRated,
  }) {
    return BookingModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      barberId: barberId ?? this.barberId,
      serviceIds: serviceIds ?? this.serviceIds,
      serviceNames: serviceNames ?? this.serviceNames,
      servicePrices: servicePrices ?? this.servicePrices,
      serviceDurations: serviceDurations ?? this.serviceDurations,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      isRated: isRated ?? this.isRated,
    );
  }

  DateTime get endDateTime {
    final startDt = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    return startDt.add(Duration(minutes: totalDurationMinutes));
  }

  String get timeRange {
    final startH = startTime.hour.toString().padLeft(2, '0');
    final startM = startTime.minute.toString().padLeft(2, '0');
    final endH = endDateTime.hour.toString().padLeft(2, '0');
    final endM = endDateTime.minute.toString().padLeft(2, '0');
    return '$startH:$startM - $endH:$endM';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'barberId': barberId,
        'serviceIds': serviceIds,
        'serviceNames': serviceNames,
        'servicePrices': servicePrices,
        'serviceDurations': serviceDurations,
        'date': date.toIso8601String(),
        'startTime': '${startTime.hour}:${startTime.minute}',
        'totalDurationMinutes': totalDurationMinutes,
        'totalPrice': totalPrice,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'cancellationReason': cancellationReason,
        'isRated': isRated,
      };

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final startParts = (json['startTime'] as String).split(':');
    return BookingModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      barberId: json['barberId'] as String,
      serviceIds: (json['serviceIds'] as List<dynamic>).cast<String>(),
      serviceNames: (json['serviceNames'] as List<dynamic>?)?.cast<String>() ?? [],
      servicePrices: (json['servicePrices'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      serviceDurations: (json['serviceDurations'] as List<dynamic>?)
              ?.cast<int>() ??
          [],
      date: DateTime.parse(json['date'] as String),
      startTime: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      totalDurationMinutes: json['totalDurationMinutes'] as int? ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status:
          BookingStatus.values.firstWhere((s) => s.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      cancellationReason: json['cancellationReason'] as String?,
      isRated: json['isRated'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BookingModel(id: $id, status: ${status.name})';
}
