import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../../presentation/screens/auth/login_screen.dart';
import '../../../presentation/screens/auth/signup_screen.dart';
import '../../../presentation/screens/auth/email_verification_screen.dart';
import '../../../presentation/screens/main/main_navigation_screen.dart';
import '../../../presentation/screens/home/home_screen.dart';
import '../../../presentation/screens/explore/explore_screen.dart';
import '../../../presentation/screens/explore/opportunity_detail_screen.dart';
import '../../../presentation/screens/tracker/tracker_screen.dart';
import '../../../presentation/screens/community/community_screen.dart';
import '../../../presentation/screens/profile/profile_screen.dart';
import '../../../presentation/screens/profile/settings_screen.dart';
import '../../../presentation/screens/notifications/notifications_screen.dart'; // ADDED
import '../../../presentation/screens/admin/admin_login_screen.dart';
import '../../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../../presentation/screens/admin/opportunity_form_screen.dart';
import '../../../domain/models/opportunity.dart';
import '../../../presentation/blocs/auth/auth_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRouter {
  static const String onboarding = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyEmail = '/verify-email';
  static const String home = '/main/home';
  static const String explore = '/main/explore';
  static const String tracker = '/main/tracker';
  static const String community = '/main/community';
  static const String profile = '/main/profile';
  static const String opportunityDetail = '/opportunity/:id';
  static const String settings = '/settings';
  static const String notifications = '/notifications'; // ADDED
  
  // Admin routes
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminCreateOpportunity = '/admin/opportunity/create';
  static const String adminEditOpportunity = '/admin/opportunity/edit/:id';

  static final GoRouter router = GoRouter(
    initialLocation: onboarding,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final authState = context.read<AuthBloc>().state;
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      
      final isOnboarding = state.matchedLocation == '/';
      final isAuthPage = state.matchedLocation == '/login' || 
                        state.matchedLocation == '/signup' ||
                        state.matchedLocation == '/verify-email';
      final isAdminPage = state.matchedLocation.startsWith('/admin');
      final isNotificationsPage = state.matchedLocation == '/notifications'; // ADDED
      
      // If authenticated and trying to access auth pages, redirect to home
      if (authState is Authenticated && (isAuthPage || isOnboarding)) {
        return home;
      }
      
      // If not authenticated and trying to access protected pages
      if (authState is Unauthenticated && !isAuthPage && !isOnboarding && !isAdminPage && !isNotificationsPage) {
        return hasSeenOnboarding ? login : onboarding;
      }
      
      // If on onboarding and has seen it before, go to login
      if (isOnboarding && hasSeenOnboarding && authState is! Authenticated) {
        return login;
      }
      
      return null; // No redirect needed
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
    routes: [
      // Onboarding & Auth
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      // Email Verification
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),
      
      // Notifications Route - ADDED
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      
      // Admin Routes
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/opportunity/create',
        builder: (context, state) => const OpportunityFormScreen(),
      ),
      GoRoute(
        path: '/admin/opportunity/edit/:id',
        builder: (context, state) {
          final opportunity = state.extra as Opportunity?;
          return OpportunityFormScreen(opportunity: opportunity);
        },
      ),
      
      // Settings (outside main nav)
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Opportunity Detail (outside main nav)
      GoRoute(
        path: '/opportunity/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OpportunityDetailScreen(opportunityId: id);
        },
      ),
      
      // Main App Routes with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/main/home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/main/explore',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ExploreScreen(),
            ),
          ),
          GoRoute(
            path: '/main/tracker',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const TrackerScreen(),
            ),
          ),
          GoRoute(
            path: '/main/community',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const CommunityScreen(),
            ),
          ),
          GoRoute(
            path: '/main/profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}