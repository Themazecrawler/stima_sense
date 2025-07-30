import 'package:flutter/material.dart';

class LocalizationService {
  static const Locale english = Locale('en', 'US');
  static const Locale swahili = Locale('sw', 'KE');

  static const List<Locale> supportedLocales = [
    english,
    swahili,
  ];

  static const String fallbackLanguageCode = 'en';

  static String getTranslatedText(String key, String languageCode) {
    switch (languageCode) {
      case 'sw':
        return _swahiliTranslations[key] ?? key;
      case 'en':
      default:
        return _englishTranslations[key] ?? key;
    }
  }

  static const Map<String, String> _englishTranslations = {
    'welcome_back': 'Welcome back!',
    'stay_informed': 'Stay informed about power outages in your area',
    'ai_prediction': 'AI Prediction',
    'ai_confidence': 'AI Confidence',
    'power_stable': 'Power is stable',
    'moderate_risk': 'Moderate risk',
    'unstable_outage_likely': 'Unstable - Outage likely',
    'quick_actions': 'Quick Actions',
    'report_outage': 'Report Outage',
    'community_activity': 'Community Activity',
    'recent_outage_reported': 'Recent outage reported',
    'power_restored': 'Power restored',
    'notifications_enabled': 'Notifications enabled',
    'notifications_disabled': 'Notifications disabled',
    'create_account': 'Create Account',
    'join_community': 'Join the community and stay informed',
    'email': 'Email',
    'password': 'Password',
    'confirm_password': 'Confirm Password',
    'sign_in': 'Sign In',
    'welcome_back_user': 'Welcome back!',
    'forgot_password': 'Forgot Password?',
    'dont_have_account': "Don't have an account? Sign up.",
    'already_have_account': 'Already have an account? Sign in.',
    'continue_with_google': 'Continue with Google',
    'complete_setup': 'Complete Setup',
    'help_personalize': 'Help us personalize your experience',
    'username': 'Username',
    'region': 'Region',
    'add_profile_picture': 'Add Profile Picture',
    'location_access_granted': 'Location access granted. We\'ll use this to provide personalized alerts.',
    'enable_location_access': 'Enable location access for personalized outage alerts in your area.',
    'profile_setup_completed': 'Profile setup completed!',
    'error_saving_profile': 'Error saving profile:',
    'dashboard': 'Dashboard',
    'reports': 'Reports',
    'map': 'Map',
    'history': 'History',
    'account': 'Account',
    'settings': 'Settings',
  };

  static const Map<String, String> _swahiliTranslations = {
    'welcome_back': 'Karibu tena!',
    'stay_informed': 'Endelea kujua kuhusu umeme uliopo katika eneo lako',
    'ai_prediction': 'Utabiri wa AI',
    'ai_confidence': 'Uthabiti wa AI',
    'power_stable': 'Umeme ni thabiti',
    'moderate_risk': 'Hatari ya wastani',
    'unstable_outage_likely': 'Haithabiti - Kukatika kunawezekana',
    'quick_actions': 'Vitendo vya Haraka',
    'report_outage': 'Ripoti Kukatika',
    'community_activity': 'Shughuli za Jamii',
    'recent_outage_reported': 'Kukatika hivi karibuni kuripotiwa',
    'power_restored': 'Umeme umerudishwa',
    'notifications_enabled': 'Arifa zimewezeshwa',
    'notifications_disabled': 'Arifa zimezuiwa',
    'create_account': 'Unda Akaunti',
    'join_community': 'Jiunge na jamii na uendelee kujua',
    'email': 'Barua pepe',
    'password': 'Nywila',
    'confirm_password': 'Thibitisha Nywila',
    'sign_in': 'Ingia',
    'welcome_back_user': 'Karibu tena!',
    'forgot_password': 'Umesahau nywila?',
    'dont_have_account': 'Huna akaunti? Jisajili.',
    'already_have_account': 'Una akaunti? Ingia.',
    'continue_with_google': 'Endelea na Google',
    'complete_setup': 'Maliza Usanidi',
    'help_personalize': 'Tusaidie kufanya uzoefu wako wa kibinafsi',
    'username': 'Jina la mtumiaji',
    'region': 'Mkoa',
    'add_profile_picture': 'Ongeza Picha ya Profaili',
    'location_access_granted': 'Ufikiaji wa eneo umewezeshwa. Tutatumia hii kutoa arifa za kibinafsi.',
    'enable_location_access': 'Wezesha ufikiaji wa eneo kwa arifa za kukatika kwa umeme za kibinafsi katika eneo lako.',
    'profile_setup_completed': 'Usanidi wa profaili umekamilika!',
    'error_saving_profile': 'Hitilafu kuhifadhi profaili:',
    'dashboard': 'Dashibodi',
    'reports': 'Ripoti',
    'map': 'Ramani',
    'history': 'Historia',
    'account': 'Akaunti',
    'settings': 'Mipangilio',
  };
} 