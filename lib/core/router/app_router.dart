import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/auth_provider.dart';
import '../../data/models/models.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/booking/screens/barber_selection_screen.dart';
import '../../features/booking/screens/time_slot_screen.dart';
import '../../features/booking/screens/booking_confirmation_screen.dart';
import '../../features/booking/screens/booking_success_screen.dart';
import '../../features/history/screens/booking_history_screen.dart';
import '../../features/history/screens/booking_detail_screen.dart';
import '../../features/ratings/screens/rating_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/barber_dashboard/screens/barber_dashboard_screen.dart';
import '../../features/barber_dashboard/screens/appointment_detail_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/barber_list_screen.dart';
import '../../features/admin/screens/edit_barber_screen.dart';
import '../../features/admin/screens/service_catalog_screen.dart';
import '../../features/admin/screens/working_hours_screen.dart';
import '../../features/admin/screens/all_bookings_screen.dart';
import '../../features/accounting/screens/accounting_overview_screen.dart';
import '../../features/accounting/screens/accounting_export_screen.dart';

/// Route names for navigation
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  // Customer
  static const customerHome = '/customer/home';
  static const barberSelection = '/customer/book/barber';
  static const timeSlots = '/customer/book/slots';
  static const bookingConfirmation = '/customer/book/confirm';
  static const bookingSuccess = '/customer/book/success';
  static const bookingHistory = '/customer/history';
  static const bookingDetail = '/customer/history/:bookingId';
  static const rating = '/rating/:bookingId';
  static const profile = '/customer/profile';

  // Barber
  static const barberDashboard = '/barber';
  static const barberAppointmentDetail = '/barber/appointment/:bookingId';
  static const barberEarnings = '/barber/earnings';
  static const barberReviews = '/barber/reviews';

  // Admin
  static const adminHome = '/admin';
  static const adminBarbers = '/admin/barbers';
  static const adminAddBarber = '/admin/barbers/add';
  static const adminEditBarber = '/admin/barbers/edit/:barberId';
  static const adminServices = '/admin/services';
  static const adminWorkingHours = '/admin/working-hours/:barberId';
  static const adminBookings = '/admin/bookings';
  static const adminAccounting = '/admin/accounting';
  static const adminExport = '/admin/accounting/export';
}

/// Router configuration with role-based routing.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isOnAuthFlow = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.splash;

      // Splash → login once auth check completes (no user signed in)
      if (state.matchedLocation == AppRoutes.splash &&
          !isAuthenticated &&
          !authState.isLoading) {
        return AppRoutes.login;
      }

      // Not authenticated → auth flow
      if (!isAuthenticated && !isOnAuthFlow) {
        return AppRoutes.login;
      }

      // Authenticated on splash → go to role home
      if (isAuthenticated && state.matchedLocation == AppRoutes.splash) {
        return _roleHome(authState.user!.role);
      }

      return null;
    },
    routes: [
      // Auth routes (public)
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Customer routes
      GoRoute(
        path: AppRoutes.customerHome,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.barberSelection,
        builder: (context, state) => const BarberSelectionScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BarberSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.timeSlots,
        builder: (context, state) => const TimeSlotScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TimeSlotScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.bookingConfirmation,
        builder: (context, state) => const BookingConfirmationScreen(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BookingConfirmationScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.bookingSuccess,
        builder: (context, state) => const BookingSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingHistory,
        builder: (context, state) => const BookingHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingDetail,
        builder: (context, state) => BookingDetailScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.rating,
        builder: (context, state) => RatingScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: RatingScreen(
            bookingId: state.pathParameters['bookingId']!,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),

      // Barber routes
      GoRoute(
        path: AppRoutes.barberDashboard,
        builder: (context, state) => const BarberDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.barberAppointmentDetail,
        builder: (context, state) => AppointmentDetailScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),

      // Admin routes
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminBarbers,
        builder: (context, state) => const BarberListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAddBarber,
        builder: (context, state) => const EditBarberScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminEditBarber,
        builder: (context, state) => EditBarberScreen(
          barberId: state.pathParameters['barberId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminServices,
        builder: (context, state) => const ServiceCatalogScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminWorkingHours,
        builder: (context, state) => WorkingHoursScreen(
          barberId: state.pathParameters['barberId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminBookings,
        builder: (context, state) => const AllBookingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAccounting,
        builder: (context, state) => const AccountingOverviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminExport,
        builder: (context, state) => const AccountingExportScreen(),
      ),
    ],
  );
});

/// Get the home route for a given role.
String _roleHome(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return AppRoutes.adminHome;
    case UserRole.barber:
      return AppRoutes.barberDashboard;
    case UserRole.customer:
    default:
      return AppRoutes.customerHome;
  }
}
