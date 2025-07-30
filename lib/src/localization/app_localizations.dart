import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Onboarding
      'welcome_title': 'Welcome to Stima Sense',
      'welcome_subtitle': 'AI-Powered Outage Prediction',
      'slide1_title': 'Stay Ahead of Outages',
      'slide1_subtitle': 'AI powered predictions keep you prepared',
      'slide2_title': 'Report & Track in Real-Time',
      'slide2_subtitle': 'Help your community by reporting outages',
      'slide3_title': 'Get Personalized Alerts',
      'slide3_subtitle': 'Receive alerts for your specific area',
      'slide4_title': 'Offline-Ready Dashboard',
      'slide4_subtitle': 'Access critical info even when offline',
      'get_started': 'Get Started',
      'next': 'Next',
      'skip': 'Skip',

      // Authentication
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'username': 'Username',
      'region': 'Region',
      'forgot_password': 'Forgot Password?',
      'reset_password': 'Reset Password',
      'send_reset_link': 'Send Reset Link',
      'set_new_password': 'Set New Password',
      'new_password': 'New Password',
      'confirm_new_password': 'Confirm New Password',
      'back_to_sign_in': 'Back to Sign In',
      'create_account': 'Create Account',
      'dont_have_account': "Don't have an account? Sign up.",
      'already_have_account': 'Already have an account? Sign in.',
      'continue_with_google': 'Continue with Google',

      // Dashboard
      'dashboard': 'Dashboard',
      'welcome_back': 'Welcome Back',
      'power_status': 'Power Status',
      'power_stable': 'Power is Stable',
      'power_unstable': 'Power is Unstable',
      'ai_confidence': 'AI Confidence',
      'community_activity': 'Community Activity',
      'recent_reports': 'Recent Reports',
      'view_all': 'View All',
      'notifications': 'Notifications',
      'toggle_notifications': 'Toggle Notifications',

      // Reports
      'reports': 'Reports',
      'report_outage': 'Report Outage',
      'description': 'Description',
      'location': 'Location',
      'submit_report': 'Submit Report',
      'no_reports': 'No reports yet',
      'like': 'Like',
      'comment': 'Comment',
      'add_comment': 'Add Comment',
      'enter_comment': 'Enter your comment...',
      'view_all_comments': 'View all comments',

      // Map
      'map': 'Map',
      'outage_map': 'Outage Map',
      'current_outages': 'Current Outages',
      'predicted_outages': 'Predicted Outages',
      'restored_outages': 'Restored Outages',
      'filter_outages': 'Filter Outages',
      'my_location': 'My Location',

      // History
      'history': 'History',
      'outage_trends': 'Outage Trends',
      'recent_activity': 'Recent Activity',
      'personal_impact': 'Personal Impact',
      'past_24h': 'Past 24h',
      'past_1_week': 'Past 1 Week',
      'past_1_month': 'Past 1 Month',
      'loading_trends': 'Loading trends...',

      // Settings
      'settings': 'Settings',
      'appearance': 'Appearance',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'location_settings': 'Location Settings',
      'enable_location': 'Enable Location Services',
      'auto_detect_location': 'Auto-detect Location',
      'share_for_predictions': 'Share for Predictions',
      'precise_location': 'Precise Location',
      'notification_preferences': 'Notification Preferences',
      'enable_notifications': 'Enable Notifications',
      'outage_alerts': 'Outage Alerts',
      'ai_predictions': 'AI Predictions',
      'community_reports': 'Community Reports',
      'weather_alerts': 'Weather Alerts',
      'delivery_methods': 'Delivery Methods',
      'push_notifications': 'Push Notifications',
      'sms_notifications': 'SMS Notifications',
      'email_notifications': 'Email Notifications',
      'save_settings': 'Save Settings',
      'settings_saved': 'Settings saved successfully!',

      // Account
      'account': 'Account',
      'profile_information': 'Profile Information',
      'account_actions': 'Account Actions',
      'change_password': 'Change Password',
      'privacy_settings': 'Privacy Settings',
      'help_support': 'Help & Support',
      'member_since': 'Member Since',
      'sign_out': 'Sign Out',
      'edit_profile': 'Edit Profile',
      'save_profile': 'Save Profile',
      'profile_updated': 'Profile updated successfully!',

      // Common
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'back': 'Back',
      'close': 'Close',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
    },
    'sw': {
      // Onboarding
      'welcome_title': 'Karibu Stima Sense',
      'welcome_subtitle': 'Utabiri wa Matatizo ya Umeme na AI',
      'slide1_title': 'Endelea Mbele ya Matatizo',
      'slide1_subtitle': 'Utabiri wa AI unakupatia tayari',
      'slide2_title': 'Ripoti na Fuatilia Kwa Wakati Halisi',
      'slide2_subtitle': 'Saidia jamii yako kwa kuripoti matatizo',
      'slide3_title': 'Pata Arifa za Kibinafsi',
      'slide3_subtitle': 'Pokea arifa za eneo lako maalum',
      'slide4_title': 'Dashibodi ya Offline',
      'slide4_subtitle': 'Pata maelezo muhimu hata wakati wa offline',
      'get_started': 'Anza',
      'next': 'Ifuatayo',
      'skip': 'Ruka',

      // Authentication
      'sign_in': 'Ingia',
      'sign_up': 'Jisajili',
      'email': 'Barua Pepe',
      'password': 'Nywila',
      'confirm_password': 'Thibitisha Nywila',
      'username': 'Jina la Mtumiaji',
      'region': 'Mkoa',
      'forgot_password': 'Umesahau Nywila?',
      'reset_password': 'Weka Upya Nywila',
      'send_reset_link': 'Tuma Kiungo cha Kujirudisha',
      'set_new_password': 'Weka Nywila Mpya',
      'new_password': 'Nywila Mpya',
      'confirm_new_password': 'Thibitisha Nywila Mpya',
      'back_to_sign_in': 'Rudi Kwenye Kuingia',
      'create_account': 'Unda Akaunti',
      'dont_have_account': 'Huna akaunti? Jisajili.',
      'already_have_account': 'Una akaunti? Ingia.',
      'continue_with_google': 'Endelea na Google',

      // Dashboard
      'dashboard': 'Dashibodi',
      'welcome_back': 'Karibu Tena',
      'power_status': 'Hali ya Umeme',
      'power_stable': 'Umeme ni Thabiti',
      'power_unstable': 'Umeme si Thabiti',
      'ai_confidence': 'Uthabiti wa AI',
      'community_activity': 'Shughuli za Jamii',
      'recent_reports': 'Ripoti za Hivi Karibuni',
      'view_all': 'Ona Zote',
      'notifications': 'Arifa',
      'toggle_notifications': 'Badilisha Arifa',

      // Reports
      'reports': 'Ripoti',
      'report_outage': 'Ripoti Tatizo',
      'description': 'Maelezo',
      'location': 'Mahali',
      'submit_report': 'Wasilisha Ripoti',
      'no_reports': 'Hakuna ripoti bado',
      'like': 'Penda',
      'comment': 'Maoni',
      'add_comment': 'Ongeza Maoni',
      'enter_comment': 'Weka maoni yako...',
      'view_all_comments': 'Ona maoni yote',

      // Map
      'map': 'Ramani',
      'outage_map': 'Ramani ya Matatizo',
      'current_outages': 'Matatizo ya Sasa',
      'predicted_outages': 'Matatizo Yanayotabiriwa',
      'restored_outages': 'Matatizo Yaliyorekebishwa',
      'filter_outages': 'Chuja Matatizo',
      'my_location': 'Mahali Pangu',

      // History
      'history': 'Historia',
      'outage_trends': 'Mwelekeo wa Matatizo',
      'recent_activity': 'Shughuli za Hivi Karibuni',
      'personal_impact': 'Athari ya Kibinafsi',
      'past_24h': 'Saa 24 zilizopita',
      'past_1_week': 'Wiki 1 iliyopita',
      'past_1_month': 'Mwezi 1 uliopita',
      'loading_trends': 'Inapakia mwelekeo...',

      // Settings
      'settings': 'Mipangilio',
      'appearance': 'Muonekano',
      'dark_mode': 'Hali ya Giza',
      'language': 'Lugha',
      'location_settings': 'Mipangilio ya Mahali',
      'enable_location': 'Washa Huduma za Mahali',
      'auto_detect_location': 'Gundua Mahali Kiotomatiki',
      'share_for_predictions': 'Shiriki kwa Utabiri',
      'precise_location': 'Mahali Halisi',
      'notification_preferences': 'Mapendeleo ya Arifa',
      'enable_notifications': 'Washa Arifa',
      'outage_alerts': 'Arifa za Matatizo',
      'ai_predictions': 'Utabiri wa AI',
      'community_reports': 'Ripoti za Jamii',
      'weather_alerts': 'Arifa za Hali ya Hewa',
      'delivery_methods': 'Njia za Kufikisha',
      'push_notifications': 'Arifa za Kushinikiza',
      'sms_notifications': 'Arifa za SMS',
      'email_notifications': 'Arifa za Barua Pepe',
      'save_settings': 'Hifadhi Mipangilio',
      'settings_saved': 'Mipangilio imehifadhiwa!',

      // Account
      'account': 'Akaunti',
      'profile_information': 'Maelezo ya Wasifu',
      'account_actions': 'Vitendo vya Akaunti',
      'change_password': 'Badilisha Nywila',
      'privacy_settings': 'Mipangilio ya Faragha',
      'help_support': 'Msaada na Usaidizi',
      'member_since': 'Mwanachama Tangu',
      'sign_out': 'Ondoka',
      'edit_profile': 'Hariri Wasifu',
      'save_profile': 'Hifadhi Wasifu',
      'profile_updated': 'Wasifu umesasishwa!',

      // Common
      'loading': 'Inapakia...',
      'error': 'Hitilafu',
      'success': 'Mafanikio',
      'cancel': 'Ghairi',
      'save': 'Hifadhi',
      'edit': 'Hariri',
      'delete': 'Futa',
      'confirm': 'Thibitisha',
      'back': 'Rudi',
      'close': 'Funga',
      'yes': 'Ndiyo',
      'no': 'Hapana',
      'ok': 'Sawa',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'sw'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
