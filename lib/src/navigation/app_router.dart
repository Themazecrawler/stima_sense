import 'package:flutter/material.dart';
import 'package:stima_sense/src/components/auth/forgot_password.dart';
import 'package:stima_sense/src/features/dashboard/dashboard_screen.dart';
import 'package:stima_sense/src/features/reports/reports_screen.dart';
import 'package:stima_sense/src/features/map/map_screen.dart';
import 'package:stima_sense/src/features/history/history_screen.dart';
import 'package:stima_sense/src/features/settings/settings_screen.dart';
import 'package:stima_sense/src/features/account/account_screen.dart';
import 'package:stima_sense/src/features/profile/profile_setup_screen.dart';
import 'package:stima_sense/onboarding_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case '/profile-setup':
        return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());

      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      case '/reports':
        return MaterialPageRoute(builder: (_) => const ReportsScreen());

      case '/map':
        return MaterialPageRoute(builder: (_) => const MapScreen());

      case '/history':
        return MaterialPageRoute(builder: (_) => const HistoryScreen());

      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case '/account':
        return MaterialPageRoute(builder: (_) => const AccountScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
