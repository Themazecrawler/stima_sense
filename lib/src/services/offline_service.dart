import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stima_sense/src/services/firebase_service.dart';

class OfflineService {
  static const String _reportsKey = 'offline_reports';
  static const String _userDataKey = 'user_data';
  static const String _outagesKey = 'outages_data';
  static const String _lastSyncKey = 'last_sync';

  // Save report for offline submission
  static Future<void> saveOfflineReport(Map<String, dynamic> reportData) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = prefs.getStringList(_reportsKey) ?? [];

    final reportWithId = {
      ...reportData,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'offline': true,
      'timestamp': DateTime.now().toIso8601String(),
    };

    reports.add(jsonEncode(reportWithId));
    await prefs.setStringList(_reportsKey, reports);
  }

  // Get offline reports
  static Future<List<Map<String, dynamic>>> getOfflineReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reports = prefs.getStringList(_reportsKey) ?? [];

    return reports
        .map((report) => jsonDecode(report) as Map<String, dynamic>)
        .toList();
  }

  // Sync offline reports with Firebase
  static Future<void> syncOfflineReports() async {
    final offlineReports = await getOfflineReports();
    final prefs = await SharedPreferences.getInstance();

    for (final report in offlineReports) {
      try {
        await FirebaseService.submitReport(report);
        // Remove from offline storage after successful sync
        final reports = prefs.getStringList(_reportsKey) ?? [];
        reports.remove(jsonEncode(report));
        await prefs.setStringList(_reportsKey, reports);
      } catch (e) {
        print('Failed to sync report: $e');
      }
    }

    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // Save user data locally
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  // Get user data from local storage
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);

    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  // Save outages data locally
  static Future<void> saveOutagesData(
      List<Map<String, dynamic>> outages) async {
    final prefs = await SharedPreferences.getInstance();
    final outagesJson = outages.map((outage) => jsonEncode(outage)).toList();
    await prefs.setStringList(_outagesKey, outagesJson);
  }

  // Get outages data from local storage
  static Future<List<Map<String, dynamic>>> getOutagesData() async {
    final prefs = await SharedPreferences.getInstance();
    final outagesJson = prefs.getStringList(_outagesKey) ?? [];

    return outagesJson
        .map((outage) => jsonDecode(outage) as Map<String, dynamic>)
        .toList();
  }

  // Check if data is stale (older than 1 hour)
  static Future<bool> isDataStale() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);

    if (lastSyncString == null) return true;

    final lastSync = DateTime.parse(lastSyncString);
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    return difference.inHours > 1;
  }

  // Clear all offline data
  static Future<void> clearOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reportsKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_outagesKey);
    await prefs.remove(_lastSyncKey);
  }

  // Check if user is online
  static Future<bool> isOnline() async {
    try {
      // Simple connectivity check - you might want to use connectivity_plus package
      final result = await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      return false;
    }
  }
}
