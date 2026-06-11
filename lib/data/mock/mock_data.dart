import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

/// Crown Cuts — Phase 1 Mock Data
///
/// Comprehensive mock dataset for development and testing.
/// Replace with Firebase providers in Phase 2.
class MockData {
  static const _uuid = Uuid();

  // ── Current User ──────────────────────────────────────────────────────────

  static final UserModel currentCustomer = UserModel(
    id: 'user-1',
    name: 'Alex Johnson',
    phone: '+1 (555) 123-4567',
    email: 'alex@example.com',
    role: UserRole.customer,
    createdAt: DateTime(2025, 1, 15),
  );

  static final UserModel currentBarber = UserModel(
    id: 'user-2',
    name: 'Karim Hassan',
    phone: '+1 (555) 234-5678',
    email: 'karim@crowncuts.com',
    role: UserRole.barber,
    barberId: 'barber-1',
    createdAt: DateTime(2024, 6, 1),
  );

  static final UserModel adminUser = UserModel(
    id: 'user-admin',
    name: 'Marco Ruiz',
    phone: '+1 (555) 111-2233',
    email: 'marco@crowncuts.com',
    role: UserRole.admin,
    createdAt: DateTime(2024, 1, 1),
  );

  // ── Service Catalog ───────────────────────────────────────────────────────

  static final List<ServiceModel> services = [
    ServiceModel(id: 'svc-1', name: 'Haircut', iconName: 'content_cut'),
    ServiceModel(id: 'svc-2', name: 'Beard Trim', iconName: 'face'),
    ServiceModel(id: 'svc-3', name: 'Hair Wash', iconName: 'water_drop'),
    ServiceModel(id: 'svc-4', name: 'Hot Towel Shave', iconName: 'spa'),
    ServiceModel(id: 'svc-5', name: 'Hair & Beard Combo', iconName: 'star'),
    ServiceModel(id: 'svc-6', name: 'Kids Haircut', iconName: 'child_care'),
    ServiceModel(id: 'svc-7', name: 'Hair Styling', iconName: 'auto_fix_high'),
    ServiceModel(id: 'svc-8', name: 'Face Mask', iconName: 'masks'),
  ];

  // ── Barbers ────────────────────────────────────────────────────────────────

  static final BarberModel barber1 = BarberModel(
    id: 'barber-1',
    name: 'Karim Hassan',
    rating: 4.8,
    reviewCount: 124,
    experienceYears: 8,
    isActive: true,
    services: [
      BarberService(
        serviceId: 'svc-1', name: 'Haircut', price: 35.0, durationMinutes: 30,
      ),
      BarberService(
        serviceId: 'svc-2', name: 'Beard Trim', price: 20.0, durationMinutes: 15,
      ),
      BarberService(
        serviceId: 'svc-3', name: 'Hair Wash', price: 15.0, durationMinutes: 10,
      ),
      BarberService(
        serviceId: 'svc-5', name: 'Hair & Beard Combo', price: 50.0, durationMinutes: 45,
      ),
      BarberService(
        serviceId: 'svc-6', name: 'Kids Haircut', price: 25.0, durationMinutes: 25,
      ),
    ],
    schedule: _standardSchedule(),
  );

  static final BarberModel barber2 = BarberModel(
    id: 'barber-2',
    name: 'Diego Martinez',
    rating: 4.6,
    reviewCount: 98,
    experienceYears: 5,
    isActive: true,
    services: [
      BarberService(
        serviceId: 'svc-1', name: 'Haircut', price: 30.0, durationMinutes: 30,
      ),
      BarberService(
        serviceId: 'svc-2', name: 'Beard Trim', price: 18.0, durationMinutes: 15,
      ),
      BarberService(
        serviceId: 'svc-4', name: 'Hot Towel Shave', price: 40.0, durationMinutes: 35,
      ),
      BarberService(
        serviceId: 'svc-7', name: 'Hair Styling', price: 45.0, durationMinutes: 40,
      ),
    ],
    schedule: _standardSchedule(),
  );

  static final BarberModel barber3 = BarberModel(
    id: 'barber-3',
    name: 'Sofia Reyes',
    rating: 4.9,
    reviewCount: 156,
    experienceYears: 10,
    isActive: true,
    services: [
      BarberService(
        serviceId: 'svc-1', name: 'Haircut', price: 40.0, durationMinutes: 35,
      ),
      BarberService(
        serviceId: 'svc-3', name: 'Hair Wash', price: 18.0, durationMinutes: 15,
      ),
      BarberService(
        serviceId: 'svc-5', name: 'Hair & Beard Combo', price: 55.0, durationMinutes: 50,
      ),
      BarberService(
        serviceId: 'svc-8', name: 'Face Mask', price: 25.0, durationMinutes: 20,
      ),
      BarberService(
        serviceId: 'svc-7', name: 'Hair Styling', price: 50.0, durationMinutes: 45,
      ),
    ],
    schedule: _standardSchedule(),
  );

  static final BarberModel barber4 = BarberModel(
    id: 'barber-4',
    name: 'James Wilson',
    rating: 4.5,
    reviewCount: 72,
    experienceYears: 4,
    isActive: true,
    services: [
      BarberService(
        serviceId: 'svc-1', name: 'Haircut', price: 28.0, durationMinutes: 25,
      ),
      BarberService(
        serviceId: 'svc-2', name: 'Beard Trim', price: 15.0, durationMinutes: 15,
      ),
      BarberService(
        serviceId: 'svc-6', name: 'Kids Haircut', price: 22.0, durationMinutes: 20,
      ),
    ],
    schedule: _partTimeSchedule(),
  );

  static List<BarberModel> get allBarbers =>
      [barber1, barber2, barber3, barber4];

  // ── Standard Work Schedule ────────────────────────────────────────────────

  static WorkSchedule _standardSchedule() {
    return WorkSchedule(
      weeklySchedule: [
        DaySchedule(
          weekday: 1, isWorking: true,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          slotIntervalMinutes: 30,
        ),
        DaySchedule(
          weekday: 2, isWorking: true,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          slotIntervalMinutes: 30,
        ),
        DaySchedule(
          weekday: 3, isWorking: true,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          slotIntervalMinutes: 30,
        ),
        DaySchedule(
          weekday: 4, isWorking: true,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 20, minute: 0),
          slotIntervalMinutes: 30,
        ),
        DaySchedule(
          weekday: 5, isWorking: true,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 20, minute: 0),
          slotIntervalMinutes: 30,
        ),
        DaySchedule(
          weekday: 6, isWorking: true,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          slotIntervalMinutes: 30,
        ),
        DaySchedule(
          weekday: 7, isWorking: false,
          startTime: const TimeOfDay(hour: 0, minute: 0),
          endTime: const TimeOfDay(hour: 0, minute: 0),
          slotIntervalMinutes: 30,
        ),
      ],
      daysOff: [
        DateTime.now().add(const Duration(days: 14)),
      ],
    );
  }

  static WorkSchedule _partTimeSchedule() {
    return WorkSchedule(
      weeklySchedule: [
        DaySchedule(
          weekday: 1, isWorking: false,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          slotIntervalMinutes: 30,
        ),
        DaySchedule(
          weekday: 2, isWorking: false,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          slotIntervalMinutes: 30,
        ),
        DaySchedule(
          weekday: 3, isWorking: true,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          slotIntervalMinutes: 30,
        ),
        DaySchedule(
          weekday: 4, isWorking: true,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          slotIntervalMinutes: 30,
        ),
        DaySchedule(
          weekday: 5, isWorking: true,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          slotIntervalMinutes: 30,
        ),
        DaySchedule(
          weekday: 6, isWorking: true,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 15, minute: 0),
          slotIntervalMinutes: 30,
        ),
        DaySchedule(
          weekday: 7, isWorking: false,
          startTime: const TimeOfDay(hour: 0, minute: 0),
          endTime: const TimeOfDay(hour: 0, minute: 0),
          slotIntervalMinutes: 30,
        ),
      ],
      daysOff: [],
    );
  }

  // ── Bookings ──────────────────────────────────────────────────────────────

  static List<BookingModel> get sampleBookings {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 7));
    final lastMonth = today.subtract(const Duration(days: 20));

    return [
      // Upcoming booking for current customer (tomorrow)
      BookingModel(
        id: 'bkg-1',
        customerId: 'user-1',
        customerName: 'Alex Johnson',
        customerPhone: '+1 (555) 123-4567',
        barberId: 'barber-1',
        serviceIds: ['svc-1', 'svc-2'],
        serviceNames: ['Haircut', 'Beard Trim'],
        servicePrices: [35.0, 20.0],
        serviceDurations: [30, 15],
        date: tomorrow,
        startTime: const TimeOfDay(hour: 10, minute: 30),
        totalDurationMinutes: 45,
        totalPrice: 55.0,
        status: BookingStatus.confirmed,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      // Completed booking (rated) — yesterday
      BookingModel(
        id: 'bkg-2',
        customerId: 'user-1',
        customerName: 'Alex Johnson',
        customerPhone: '+1 (555) 123-4567',
        barberId: 'barber-2',
        serviceIds: ['svc-1'],
        serviceNames: ['Haircut'],
        servicePrices: [30.0],
        serviceDurations: [30],
        date: yesterday,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        totalDurationMinutes: 30,
        totalPrice: 30.0,
        status: BookingStatus.completed,
        createdAt: yesterday.subtract(const Duration(hours: 24)),
        isRated: true,
      ),
      // Canceled booking
      BookingModel(
        id: 'bkg-3',
        customerId: 'user-1',
        customerName: 'Alex Johnson',
        customerPhone: '+1 (555) 123-4567',
        barberId: 'barber-3',
        serviceIds: ['svc-5'],
        serviceNames: ['Hair & Beard Combo'],
        servicePrices: [55.0],
        serviceDurations: [50],
        date: lastWeek,
        startTime: const TimeOfDay(hour: 11, minute: 0),
        totalDurationMinutes: 50,
        totalPrice: 55.0,
        status: BookingStatus.cancelled,
        createdAt: lastWeek.subtract(const Duration(hours: 48)),
        cancellationReason: 'Schedule conflict',
      ),
      // Completed booking (not yet rated) — last month
      BookingModel(
        id: 'bkg-4',
        customerId: 'user-1',
        customerName: 'Alex Johnson',
        customerPhone: '+1 (555) 123-4567',
        barberId: 'barber-1',
        serviceIds: ['svc-1', 'svc-3'],
        serviceNames: ['Haircut', 'Hair Wash'],
        servicePrices: [35.0, 15.0],
        serviceDurations: [30, 10],
        date: lastMonth,
        startTime: const TimeOfDay(hour: 16, minute: 0),
        totalDurationMinutes: 40,
        totalPrice: 50.0,
        status: BookingStatus.completed,
        createdAt: lastMonth.subtract(const Duration(hours: 12)),
        isRated: false,
      ),
      // Today — an in-progress booking for another customer
      BookingModel(
        id: 'bkg-5',
        customerId: 'user-other-1',
        customerName: 'Marcus Brown',
        customerPhone: '+1 (555) 333-4444',
        barberId: 'barber-1',
        serviceIds: ['svc-1'],
        serviceNames: ['Haircut'],
        servicePrices: [35.0],
        serviceDurations: [30],
        date: today,
        startTime: TimeOfDay(
          hour: DateTime.now().hour - 1,
          minute: 0,
        ),
        totalDurationMinutes: 30,
        totalPrice: 35.0,
        status: BookingStatus.inProgress,
        createdAt: today.subtract(const Duration(days: 1)),
      ),
      // Today — upcoming booking for Diego
      BookingModel(
        id: 'bkg-6',
        customerId: 'user-other-2',
        customerName: 'Lisa Kim',
        customerPhone: '+1 (555) 555-6666',
        barberId: 'barber-2',
        serviceIds: ['svc-4'],
        serviceNames: ['Hot Towel Shave'],
        servicePrices: [40.0],
        serviceDurations: [35],
        date: today,
        startTime: TimeOfDay(
          hour: DateTime.now().hour + 2,
          minute: 0,
        ),
        totalDurationMinutes: 35,
        totalPrice: 40.0,
        status: BookingStatus.confirmed,
        createdAt: today.subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Get bookings for a specific barber on a specific date.
  static List<BookingModel> getBookingsForBarber(
      String barberId, DateTime date) {
    return sampleBookings.where((b) {
      if (b.barberId != barberId) return false;
      return DateHelpers.isSameDay(b.date, date);
    }).toList();
  }

  // ── Ratings ───────────────────────────────────────────────────────────────

  static final List<RatingModel> ratings = [
    RatingModel(
      id: 'rating-1',
      bookingId: 'bkg-2',
      customerId: 'user-1',
      customerName: 'Alex Johnson',
      barberId: 'barber-2',
      stars: 4.5,
      comment: 'Great haircut! Diego is very detail-oriented.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    RatingModel(
      id: 'rating-2',
      bookingId: 'bkg-other-1',
      customerId: 'user-other-1',
      customerName: 'Marcus Brown',
      barberId: 'barber-1',
      stars: 5.0,
      comment: 'Best barber in town! Always consistent.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    RatingModel(
      id: 'rating-3',
      bookingId: 'bkg-other-2',
      customerId: 'user-other-2',
      customerName: 'Lisa Kim',
      barberId: 'barber-2',
      stars: 4.0,
      comment: 'Good service, friendly atmosphere.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    RatingModel(
      id: 'rating-4',
      bookingId: 'bkg-other-3',
      customerId: 'user-other-3',
      customerName: 'Tom Cruz',
      barberId: 'barber-1',
      stars: 5.0,
      comment: 'Karim is a master with scissors! Amazing fade.',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    RatingModel(
      id: 'rating-5',
      bookingId: 'bkg-other-4',
      customerId: 'user-other-4',
      customerName: 'Nina Patel',
      barberId: 'barber-3',
      stars: 5.0,
      comment: 'Sofia is incredible! Best haircut I have ever had.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    RatingModel(
      id: 'rating-6',
      bookingId: 'bkg-other-5',
      customerId: 'user-other-5',
      customerName: 'Ryan Park',
      barberId: 'barber-3',
      stars: 4.5,
      comment: 'Love the new style Sofia suggested. Will come back!',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    RatingModel(
      id: 'rating-7',
      bookingId: 'bkg-other-6',
      customerId: 'user-other-4',
      customerName: 'Nina Patel',
      barberId: 'barber-1',
      stars: 4.0,
      comment: 'Good as always!',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  /// Get ratings for a specific barber.
  static List<RatingModel> getRatingsForBarber(String barberId) {
    return ratings.where((r) => r.barberId == barberId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Compute the average rating for a barber.
  static double computeAverageRating(String barberId) {
    final barberRatings = getRatingsForBarber(barberId);
    if (barberRatings.isEmpty) return 0;
    final total = barberRatings.fold<double>(
      0, (sum, r) => sum + r.stars,
    );
    return (total / barberRatings.length).roundToDouble();
  }

  // ── Income Records ────────────────────────────────────────────────────────

  static List<IncomeRecord> get incomeRecords {
    final today = DateTime.now();
    final records = <IncomeRecord>[];

    // Generate income records for the last 30 days
    for (int i = 0; i < 30; i++) {
      final day = today.subtract(Duration(days: i));
      // 3-6 bookings per day
      final numBookings = 3 + (i % 4);
      for (int j = 0; j < numBookings; j++) {
        final barber = allBarbers[j % allBarbers.length];
        final serviceIdx = j % barber.services.length;
        final service = barber.services[serviceIdx];
        records.add(IncomeRecord(
          id: _uuid.v4(),
          bookingId: _uuid.v4(),
          barberId: barber.id,
          barberName: barber.name,
          serviceIds: [service.serviceId],
          serviceNames: [service.name],
          amount: service.price,
          date: DateTime(day.year, day.month, day.day, 9 + j * 2),
        ));
      }
    }

    return records;
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  /// Get a barber by ID.
  static BarberModel? getBarberById(String id) {
    try {
      return allBarbers.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get a user-friendly time of day label.
  static String timeOfDayPeriod(TimeOfDay time) {
    final hour = time.hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

/// Local reference to DateHelpers for mock data use.
class DateHelpers {
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
