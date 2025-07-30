import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stima_sense/src/navigation/app_router.dart';
import 'package:stima_sense/src/themes/app_theme.dart';
import 'package:stima_sense/src/services/notification_service.dart';
import 'package:stima_sense/src/services/ml/ml_service.dart';
import 'package:stima_sense/src/services/firebase_service.dart';
import 'package:stima_sense/src/localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();

  // Initialize ML models in background
  MLService.loadFirebaseModel().then((success) {
    if (success) {
      debugPrint('Firebase ML model loaded successfully');
    } else {
      debugPrint('Failed to load Firebase ML model, trying local model...');
      MLService.loadLocalModel().then((localSuccess) {
        if (localSuccess) {
          debugPrint('Local ML model loaded successfully');
        } else {
          debugPrint('Failed to load any ML model');
        }
      });
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadThemeAndLanguagePreference();
  }

  Future<void> _loadThemeAndLanguagePreference() async {
    try {
      final user = await FirebaseService.getCurrentUserProfile();
      if (user != null && mounted) {
        setState(() {
          _isDarkMode = user['isDarkMode'] ?? false;
          final language = user['language'] ?? 'English';
          _locale =
              language == 'Swahili' ? const Locale('sw') : const Locale('en');
        });
      }
    } catch (e) {
      debugPrint('Error loading theme and language preference: $e');
    }
  }

  // Method to update theme and language (can be called from settings)
  void updateThemeAndLanguage(bool isDarkMode, String language) {
    setState(() {
      _isDarkMode = isDarkMode;
      _locale = language == 'Swahili' ? const Locale('sw') : const Locale('en');
    });
  }

  @override
  void dispose() {
    // Dispose ML models when app closes
    MLService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stima Sense',
      theme: AppTheme.getTheme(_isDarkMode),
      locale: _locale,
      onGenerateRoute: AppRouter.generateRoute,
      home: const SplashScreen(),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('sw'), // Swahili
      ],
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      debugPrint('SplashScreen: Starting auth check...');

      // Wait a bit to show splash screen
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) {
        debugPrint('SplashScreen: Widget not mounted, returning');
        return;
      }

      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('SplashScreen: Current user: ${user?.email ?? 'null'}');

      if (user != null) {
        // User is logged in, go to dashboard
        debugPrint('SplashScreen: Navigating to dashboard');
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // User is not logged in, go to onboarding
        debugPrint('SplashScreen: Navigating to onboarding');
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } catch (e) {
      debugPrint('SplashScreen: Error during auth check: $e');
      // Fallback to onboarding on error
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B2192),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/appIcon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Name
            const Text(
              'Stima Sense',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            const Text(
              'AI-Powered Outage Prediction',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
