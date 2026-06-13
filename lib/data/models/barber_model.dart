import 'barber_service.dart';
import 'work_schedule.dart';

/// Represents a barber in the shop.
class BarberModel {
  final String id;
  final String name;
  final String avatarUrl;
  final double rating; // computed average
  final int reviewCount;
  final int experienceYears;
  final bool isActive;
  final List<BarberService> services;
  final WorkSchedule schedule;

  const BarberModel({
    required this.id,
    required this.name,
    this.avatarUrl = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.experienceYears = 0,
    this.isActive = true,
    this.services = const [],
    required this.schedule,
  });

  BarberModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    double? rating,
    int? reviewCount,
    int? experienceYears,
    bool? isActive,
    List<BarberService>? services,
    WorkSchedule? schedule,
  }) {
    return BarberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      experienceYears: experienceYears ?? this.experienceYears,
      isActive: isActive ?? this.isActive,
      services: services ?? this.services,
      schedule: schedule ?? this.schedule,
    );
  }

  double get computedRating => reviewCount > 0 ? rating : 0.0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarUrl': avatarUrl,
    'rating': rating,
    'reviewCount': reviewCount,
    'experienceYears': experienceYears,
    'isActive': isActive,
    'services': services.map((s) => s.toJson()).toList(),
    'schedule': schedule.toJson(),
  };

  factory BarberModel.fromJson(Map<String, dynamic> json) => BarberModel(
    id: json['id'] as String,
    name: json['name'] as String,
    avatarUrl: json['avatarUrl'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    reviewCount: json['reviewCount'] as int? ?? 0,
    experienceYears: json['experienceYears'] as int? ?? 0,
    isActive: json['isActive'] as bool? ?? true,
    services:
        (json['services'] as List<dynamic>?)
            ?.map((s) => BarberService.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [],
    schedule: WorkSchedule.fromJson(json['schedule'] as Map<String, dynamic>),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarberModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BarberModel(id: $id, name: $name, rating: $rating)';
}
