import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../../presentation/screens/auth/login_screen.dart';
import '../../../presentation/screens/auth/signup_screen.dart';
import '../../../presentation/screens/main/main_navigation_screen.dart';
import '../../../presentation/screens/home/home_screen.dart';
import '../../../presentation/screens/explore/explore_screen.dart';
import '../../../presentation/screens/explore/opportunity_detail_screen.dart';
import '../../../presentation/screens/tracker/tracker_screen.dart';
import '../../../presentation/screens/community/community_screen.dart';
import '../../../presentation/screens/profile/profile_screen.dart';
import '../../../presentation/screens/profile/settings_screen.dart';
import '../../../presentation/screens/admin/admin_login_screen.dart';
import '../../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../../presentation/screens/admin/opportunity_form_screen.dart';
import '../../../domain/models/opportunity.dart';

class AppRouter {
  static const String onboarding = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String main = '/main';
  static const String home = '/main/home';
  static const String explore = '/main/explore';
  static const String tracker = '/main/tracker';
  static const String community = '/main/community';
  static const String profile = '/main/profile';
  static const String opportunityDetail = '/opportunity/:id';
  static const String settings = '/settings';
  
  // Admin routes
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminCreateOpportunity = '/admin/opportunity/create';
  static const String adminEditOpportunity = '/admin/opportunity/edit/:id';

  static final GoRouter router = GoRouter(
    initialLocation: onboarding,
    routes: [
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        builder: (context, state) => const SignupScreen(),
      ),
      
      // Admin routes
      GoRoute(
        path: adminLogin,
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: adminCreateOpportunity,
        builder: (context, state) => const OpportunityFormScreen(),
      ),
      GoRoute(
        path: adminEditOpportunity,
        builder: (context, state) {
          final opportunity = state.extra as Opportunity?;
          return OpportunityFormScreen(opportunity: opportunity);
        },
      ),
      
      // Main app routes
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          GoRoute(
            path: home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: explore,
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: tracker,
            builder: (context, state) => const TrackerScreen(),
          ),
          GoRoute(
            path: community,
            builder: (context, state) => const CommunityScreen(),
          ),
          GoRoute(
            path: profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: opportunityDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OpportunityDetailScreen(opportunityId: id);
        },
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}