import 'package:flutter/material.dart';
import 'package:stima_sense/src/components/shared/bottom_nav_bar.dart';
import 'package:stima_sense/src/components/shared/gradient_button.dart';
import 'package:stima_sense/src/services/firebase_service.dart';
import 'package:stima_sense/src/services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _notificationsEnabled = true;
  double _aiConfidence = 92.0; // Mock data - replace with real AI prediction

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAIPrediction();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await FirebaseService.getCurrentUserProfile();
      if (user != null) {
        setState(() {
          _notificationsEnabled = user['notificationsEnabled'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Already on dashboard
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
        Navigator.pushReplacementNamed(context, '/account');
        break;
    }
  }

  Future<void> _toggleNotifications() async {
    setState(() {
      _notificationsEnabled = !_notificationsEnabled;
    });

    await NotificationService.toggleNotifications(_notificationsEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _notificationsEnabled
                ? 'Notifications enabled'
                : 'Notifications disabled',
          ),
          backgroundColor: _notificationsEnabled ? Colors.green : Colors.orange,
        ),
      );
    }

    // Save to Firebase
    try {
      await FirebaseService.updateCurrentUserProfile({
        'notificationsEnabled': _notificationsEnabled,
      });
    } catch (e) {
      debugPrint('Error saving notification preference: $e');
    }
  }

  Color _getConfidenceColor() {
    if (_aiConfidence >= 80) return Colors.green;
    if (_aiConfidence >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getConfidenceStatus() {
    if (_aiConfidence >= 80) return 'Power is stable';
    if (_aiConfidence >= 50) return 'Moderate risk';
    return 'Unstable - Outage likely';
  }

  IconData _getConfidenceIcon() {
    if (_aiConfidence >= 80) return Icons.check_circle;
    if (_aiConfidence >= 50) return Icons.warning;
    return Icons.error;
  }

  Future<void> _loadAIPrediction() async {
    try {
      final predictionData = {
        'Event Month': DateTime.now().month,
        'Event Hour': DateTime.now().hour,
        'Outage Duration (hrs)': 2.0,
      };

      final prediction = await FirebaseService.predictOutage(predictionData);
      if (prediction.containsKey('confidence')) {
        setState(() {
          _aiConfidence = prediction['confidence'] * 100;
        });
      }
    } catch (e) {
      debugPrint('Error loading AI prediction: $e');
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
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF8B2192),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _notificationsEnabled
                  ? Icons.notifications
                  : Icons.notifications_off,
              color:
                  _notificationsEnabled ? const Color(0xFF8B2192) : Colors.grey,
            ),
            onPressed: _toggleNotifications,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF6850), Color(0xFF8B2192)],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stay informed about power outages in your area',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Confidence Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getConfidenceIcon(),
                          color: _getConfidenceColor(),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'AI Prediction',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_aiConfidence.toStringAsFixed(0)}% AI Confidence',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getConfidenceStatus(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _getConfidenceColor(),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _getConfidenceColor().withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getConfidenceIcon(),
                            color: _getConfidenceColor(),
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GradientButton(
              onPressed: () {
                Navigator.pushNamed(context, '/reports');
              },
              child: const Text(
                'Report Outage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Community Activity
            const Text(
              'Community Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF8B2192),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: const Text('Recent outage reported'),
                      subtitle: const Text('Westlands area - 2 hours ago'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(context, '/reports');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                      title: const Text('Power restored'),
                      subtitle: const Text('Kileleshwa area - 1 hour ago'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(context, '/reports');
                      },
                    ),
                  ],
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
}
