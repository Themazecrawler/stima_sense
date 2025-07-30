import 'package:flutter/material.dart';
import 'package:stima_sense/src/components/shared/bottom_nav_bar.dart';
import 'package:stima_sense/src/components/shared/gradient_button.dart';
import 'package:stima_sense/src/services/firebase_service.dart';
import 'package:stima_sense/src/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _currentIndex = 4;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _autoDetectLocation = true;
  bool _shareLocationForPredictions = true;
  bool _preciseLocation = false;

  // Notification preferences
  bool _outageAlerts = true;
  bool _aiPredictions = true;
  bool _communityReports = true;
  bool _weatherAlerts = false;

  // Delivery methods
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _emailNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await FirebaseService.getCurrentUserProfile();
      if (user != null) {
        setState(() {
          _isDarkMode = user['isDarkMode'] ?? false;
          _selectedLanguage = user['language'] ?? 'English';
          _notificationsEnabled = user['notificationsEnabled'] ?? true;
          _locationEnabled = user['locationEnabled'] ?? true;
          _autoDetectLocation = user['autoDetectLocation'] ?? true;
          _shareLocationForPredictions =
              user['shareLocationForPredictions'] ?? true;
          _preciseLocation = user['preciseLocation'] ?? false;
          _outageAlerts = user['outageAlerts'] ?? true;
          _aiPredictions = user['aiPredictions'] ?? true;
          _communityReports = user['communityReports'] ?? true;
          _weatherAlerts = user['weatherAlerts'] ?? false;
          _pushNotifications = user['pushNotifications'] ?? true;
          _smsNotifications = user['smsNotifications'] ?? false;
          _emailNotifications = user['emailNotifications'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = {
        'isDarkMode': _isDarkMode,
        'language': _selectedLanguage,
        'notificationsEnabled': _notificationsEnabled,
        'locationEnabled': _locationEnabled,
        'autoDetectLocation': _autoDetectLocation,
        'shareLocationForPredictions': _shareLocationForPredictions,
        'preciseLocation': _preciseLocation,
        'outageAlerts': _outageAlerts,
        'aiPredictions': _aiPredictions,
        'communityReports': _communityReports,
        'weatherAlerts': _weatherAlerts,
        'pushNotifications': _pushNotifications,
        'smsNotifications': _smsNotifications,
        'emailNotifications': _emailNotifications,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await FirebaseService.updateCurrentUserProfile(settings);

      // Update notification settings
      await NotificationService.toggleNotifications(_notificationsEnabled);

      // Force app theme and language update
      if (mounted) {
        // Rebuild the entire app to apply theme and language changes
        Navigator.pushReplacementNamed(context, '/dashboard');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/reports');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/map');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 4:
        // Already on settings
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF8B2192),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appearance
                  _buildSection(
                    'Appearance',
                    [
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle:
                            const Text('Switch between light and dark theme'),
                        value: _isDarkMode,
                        onChanged: (value) {
                          setState(() {
                            _isDarkMode = value;
                          });
                          _saveSettings();
                        },
                        activeColor: const Color(0xFF8B2192),
                        activeTrackColor:
                            const Color(0xFF8B2192).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      ListTile(
                        title: const Text('Language'),
                        subtitle: Text(_selectedLanguage),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _showLanguageDialog,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Location Settings
                  _buildSection(
                    'Location Settings',
                    [
                      SwitchListTile(
                        title: const Text('Enable Location Services'),
                        subtitle:
                            const Text('Allow app to access your location'),
                        value: _locationEnabled,
                        onChanged: (value) {
                          setState(() {
                            _locationEnabled = value;
                          });
                          _saveSettings();
                        },
                        activeColor: const Color(0xFF8B2192),
                        activeTrackColor:
                            const Color(0xFF8B2192).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      SwitchListTile(
                        title: const Text('Auto-detect Location'),
                        subtitle:
                            const Text('Automatically detect your region'),
                        value: _autoDetectLocation,
                        onChanged: (value) {
                          setState(() {
                            _autoDetectLocation = value;
                          });
                          _saveSettings();
                        },
                        activeColor: const Color(0xFF8B2192),
                        activeTrackColor:
                            const Color(0xFF8B2192).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      SwitchListTile(
                        title: const Text('Share for Predictions'),
                        subtitle:
                            const Text('Share location to improve predictions'),
                        value: _shareLocationForPredictions,
                        onChanged: (value) {
                          setState(() {
                            _shareLocationForPredictions = value;
                          });
                          _saveSettings();
                        },
                        activeColor: const Color(0xFF8B2192),
                        activeTrackColor:
                            const Color(0xFF8B2192).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      SwitchListTile(
                        title: const Text('Precise Location'),
                        subtitle: const Text('Use GPS for exact coordinates'),
                        value: _preciseLocation,
                        onChanged: (value) {
                          setState(() {
                            _preciseLocation = value;
                          });
                          _saveSettings();
                        },
                        activeColor: const Color(0xFF8B2192),
                        activeTrackColor:
                            const Color(0xFF8B2192).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Notification Preferences
                  _buildSection(
                    'Notification Preferences',
                    [
                      SwitchListTile(
                        title: const Text('Enable Notifications'),
                        subtitle: const Text('Receive push notifications'),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                          _saveSettings();
                        },
                        activeColor: const Color(0xFF8B2192),
                        activeTrackColor:
                            const Color(0xFF8B2192).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      SwitchListTile(
                        title: const Text('Outage Alerts'),
                        subtitle: const Text('Get notified of power outages'),
                        value: _outageAlerts,
                        onChanged: (value) {
                          setState(() {
                            _outageAlerts = value;
                          });
                          _saveSettings();
                        },
                        activeColor: const Color(0xFF8B2192),
                        activeTrackColor:
                            const Color(0xFF8B2192).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      SwitchListTile(
                        title: const Text('AI Predictions'),
                        subtitle:
                            const Text('Get AI-powered outage predictions'),
                        value: _aiPredictions,
                        onChanged: (value) {
                          setState(() {
                            _aiPredictions = value;
                          });
                          _saveSettings();
                        },
                        activeColor: const Color(0xFF8B2192),
                        activeTrackColor:
                            const Color(0xFF8B2192).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      SwitchListTile(
                        title: const Text('Community Reports'),
                        subtitle:
                            const Text('Get notified of community reports'),
                        value: _communityReports,
                        onChanged: (value) {
                          setState(() {
                            _communityReports = value;
                          });
                          _saveSettings();
                        },
                        activeColor: const Color(0xFF8B2192),
                        activeTrackColor:
                            const Color(0xFF8B2192).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      SwitchListTile(
                        title: const Text('Weather Alerts'),
                        subtitle:
                            const Text('Get weather-related outage alerts'),
                        value: _weatherAlerts,
                        onChanged: (value) {
                          setState(() {
                            _weatherAlerts = value;
                          });
                          _saveSettings();
                        },
                        activeColor: const Color(0xFF8B2192),
                        activeTrackColor:
                            const Color(0xFF8B2192).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Delivery Methods
                  _buildSection(
                    'Delivery Methods',
                    [
                      SwitchListTile(
                        title: const Text('Push Notifications'),
                        subtitle: const Text('Receive notifications on device'),
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() {
                            _pushNotifications = value;
                          });
                          _saveSettings();
                        },
                        activeColor: const Color(0xFF8B2192),
                        activeTrackColor:
                            const Color(0xFF8B2192).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      SwitchListTile(
                        title: const Text('SMS Notifications'),
                        subtitle: const Text('Receive notifications via SMS'),
                        value: _smsNotifications,
                        onChanged: (value) {
                          setState(() {
                            _smsNotifications = value;
                          });
                          _saveSettings();
                        },
                        activeColor: const Color(0xFF8B2192),
                        activeTrackColor:
                            const Color(0xFF8B2192).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      SwitchListTile(
                        title: const Text('Email Notifications'),
                        subtitle: const Text('Receive notifications via email'),
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() {
                            _emailNotifications = value;
                          });
                          _saveSettings();
                        },
                        activeColor: const Color(0xFF8B2192),
                        activeTrackColor:
                            const Color(0xFF8B2192).withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  GradientButton(
                    onPressed: _saveSettings,
                    child: const Text(
                      'Save Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'English',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                  _saveSettings();
                },
              ),
            ),
            ListTile(
              title: const Text('Swahili'),
              leading: Radio<String>(
                value: 'Swahili',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                  _saveSettings();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
