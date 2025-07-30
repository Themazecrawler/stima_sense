import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stima_sense/src/components/shared/bottom_nav_bar.dart';
import 'package:stima_sense/src/services/firebase_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _currentIndex = 3;
  String _selectedFilter = '24h';
  bool _isLoading = false;
  List<FlSpot> _trendData = [];
  Map<String, dynamic> _userStats = {};

  final List<String> _filters = ['24h', '1 week', '1 month'];

  @override
  void initState() {
    super.initState();
    _loadTrendData();
    _loadUserStats();
  }

  Future<void> _loadTrendData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mock trend data - replace with real Firebase data
      final now = DateTime.now();
      List<FlSpot> spots = [];

      switch (_selectedFilter) {
        case '24h':
          for (int i = 0; i < 24; i++) {
            spots.add(FlSpot(i.toDouble(), (i % 3 + 1).toDouble()));
          }
          break;
        case '1 week':
          for (int i = 0; i < 7; i++) {
            spots.add(FlSpot(i.toDouble(), (i % 4 + 2).toDouble()));
          }
          break;
        case '1 month':
          for (int i = 0; i < 30; i++) {
            spots.add(FlSpot(i.toDouble(), (i % 5 + 1).toDouble()));
          }
          break;
      }

      setState(() {
        _trendData = spots;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading trend data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserStats() async {
    try {
      // Mock user stats - replace with real Firebase data
      setState(() {
        _userStats = {
          'totalOutages': 12,
          'totalDuration': 48,
          'averageDuration': 4.0,
          'mostAffectedArea': 'Westlands',
          'lastOutage': DateTime.now().subtract(const Duration(days: 2)),
        };
      });
    } catch (e) {
      debugPrint('Error loading user stats: $e');
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
        // Already on history
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/account');
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
          'History',
          style: TextStyle(
            color: Color(0xFF8B2192),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Chips
            const Text(
              'Time Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    _loadTrendData();
                  },
                  selectedColor: const Color(0xFF8B2192).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF8B2192),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Outage Trends Chart
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Outage Trends',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(show: true),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                    ),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _trendData,
                                    isCurved: true,
                                    color: const Color(0xFF8B2192),
                                    barWidth: 3,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: const Color(0xFF8B2192)
                                          .withValues(alpha: 0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Personal Impact
            const Text(
              'Personal Impact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildImpactCard(
                    'Total Outages',
                    _userStats['totalOutages']?.toString() ?? '0',
                    Icons.flash_off,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImpactCard(
                    'Total Hours',
                    '${_userStats['totalDuration'] ?? 0}h',
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildImpactCard(
                    'Avg Duration',
                    '${_userStats['averageDuration']?.toStringAsFixed(1) ?? '0.0'}h',
                    Icons.timer,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImpactCard(
                    'Most Affected',
                    _userStats['mostAffectedArea'] ?? 'None',
                    Icons.location_on,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
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
                    _buildActivityItem(
                      'Power restored in Westlands',
                      '2 days ago',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    const Divider(),
                    _buildActivityItem(
                      'Outage reported in Kilimani',
                      '1 week ago',
                      Icons.report,
                      Colors.orange,
                    ),
                    const Divider(),
                    _buildActivityItem(
                      'Power restored in Kileleshwa',
                      '2 weeks ago',
                      Icons.check_circle,
                      Colors.green,
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

  Widget _buildImpactCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
