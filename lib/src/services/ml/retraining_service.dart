import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stima_sense/src/services/weather_service.dart';
import 'dart:convert';
import 'dart:io';

class RetrainingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Data collection for retraining
  static Future<Map<String, dynamic>> collectTrainingData() async {
    try {
      debugPrint('Collecting training data...');

      // Collect reports data
      final reportsSnapshot = await _firestore
          .collection('reports')
          .where('timestamp',
              isGreaterThan: DateTime.now().subtract(const Duration(days: 90)))
          .get();

      // Collect weather data (if available)
      final weatherData = await _collectWeatherData();

      // Collect historical patterns
      final historicalData = await _collectHistoricalData();

      // Structure data for training
      final trainingData = {
        'reports': reportsSnapshot.docs.map((doc) => doc.data()).toList(),
        'weather': weatherData,
        'historical': historicalData,
        'metadata': {
          'collectedAt': DateTime.now().toIso8601String(),
          'totalReports': reportsSnapshot.docs.length,
          'dateRange': {
            'start': DateTime.now()
                .subtract(const Duration(days: 90))
                .toIso8601String(),
            'end': DateTime.now().toIso8601String(),
          },
        },
      };

      debugPrint('Training data collected: ${trainingData['metadata']}');
      return trainingData;
    } catch (e) {
      debugPrint('Error collecting training data: $e');
      rethrow;
    }
  }

  // Collect weather data using WeatherService
  static Future<List<Map<String, dynamic>>> _collectWeatherData() async {
    try {
      // For now, use mock weather data
      // In production, you would get user locations and fetch real weather data
      final mockWeather = WeatherService.getMockWeatherData();
      final mockForecast = WeatherService.getMockForecastData();

      // Combine current weather and forecast
      final weatherData = [mockWeather, ...mockForecast];

      debugPrint('Weather data collected: ${weatherData.length} records');
      return weatherData;

      // TODO: Implement real weather data collection
      // 1. Get user locations from Firestore
      // 2. Fetch weather data for each location
      // 3. Store weather data with outage reports
    } catch (e) {
      debugPrint('Error collecting weather data: $e');
      return [];
    }
  }

  // Collect historical outage patterns
  static Future<List<Map<String, dynamic>>> _collectHistoricalData() async {
    try {
      final outagesSnapshot = await _firestore
          .collection('outages')
          .where('timestamp',
              isGreaterThan: DateTime.now().subtract(const Duration(days: 365)))
          .get();

      return outagesSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error collecting historical data: $e');
      return [];
    }
  }

  // Trigger retraining process
  static Future<bool> triggerRetraining() async {
    try {
      debugPrint('Triggering retraining process...');

      // 1. Collect training data
      final trainingData = await collectTrainingData();

      // 2. Save training data to Firebase
      await _saveTrainingData(trainingData);

      // 3. Trigger cloud function for retraining
      await _triggerCloudFunction();

      // 4. Monitor retraining progress
      await _monitorRetrainingProgress();

      debugPrint('Retraining triggered successfully');
      return true;
    } catch (e) {
      debugPrint('Error triggering retraining: $e');
      return false;
    }
  }

  // Save training data to Firebase
  static Future<void> _saveTrainingData(
      Map<String, dynamic> trainingData) async {
    try {
      await _firestore.collection('ml_training').doc('latest_dataset').set({
        'data': trainingData,
        'status': 'ready_for_training',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Training data saved to Firebase');
    } catch (e) {
      debugPrint('Error saving training data: $e');
      rethrow;
    }
  }

  // Trigger cloud function for retraining
  static Future<void> _triggerCloudFunction() async {
    try {
      // This would call your Firebase Cloud Function
      // For now, we'll simulate the trigger
      await _firestore.collection('ml_training').doc('training_job').set({
        'status': 'triggered',
        'triggeredAt': FieldValue.serverTimestamp(),
        'modelName': 'outage_model',
        'trainingConfig': {
          'epochs': 100,
          'batchSize': 32,
          'learningRate': 0.001,
          'validationSplit': 0.2,
        },
      });

      debugPrint('Cloud function triggered for retraining');
    } catch (e) {
      debugPrint('Error triggering cloud function: $e');
      rethrow;
    }
  }

  // Monitor retraining progress
  static Future<void> _monitorRetrainingProgress() async {
    try {
      // Listen to training progress
      _firestore
          .collection('ml_training')
          .doc('training_job')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          final status = data?['status'];

          debugPrint('Training status: $status');

          if (status == 'completed') {
            debugPrint('Training completed successfully');
            _notifyModelUpdate();
          } else if (status == 'failed') {
            debugPrint('Training failed: ${data?['error']}');
          }
        }
      });
    } catch (e) {
      debugPrint('Error monitoring training progress: $e');
    }
  }

  // Notify app about model update
  static void _notifyModelUpdate() {
    debugPrint('New model available - app will download on next prediction');
    // The app will automatically download the new model
    // when MLService.loadFirebaseModel() is called
  }

  // Schedule automatic retraining
  static Future<void> scheduleRetraining({
    required int daysInterval,
    required int hourOfDay,
  }) async {
    try {
      await _firestore.collection('ml_config').doc('retraining_schedule').set({
        'enabled': true,
        'daysInterval': daysInterval,
        'hourOfDay': hourOfDay,
        'lastRetraining': FieldValue.serverTimestamp(),
        'nextRetraining': _calculateNextRetraining(daysInterval, hourOfDay),
      });

      debugPrint(
          'Retraining scheduled: every $daysInterval days at $hourOfDay:00');
    } catch (e) {
      debugPrint('Error scheduling retraining: $e');
    }
  }

  // Calculate next retraining date
  static DateTime _calculateNextRetraining(int daysInterval, int hourOfDay) {
    final now = DateTime.now();
    final nextDate = now.add(Duration(days: daysInterval));
    return DateTime(nextDate.year, nextDate.month, nextDate.day, hourOfDay);
  }

  // Check if retraining is due
  static Future<bool> isRetrainingDue() async {
    try {
      final scheduleDoc = await _firestore
          .collection('ml_config')
          .doc('retraining_schedule')
          .get();

      if (!scheduleDoc.exists) return false;

      final data = scheduleDoc.data();
      final enabled = data?['enabled'] ?? false;
      final nextRetraining = data?['nextRetraining']?.toDate();

      if (!enabled || nextRetraining == null) return false;

      return DateTime.now().isAfter(nextRetraining);
    } catch (e) {
      debugPrint('Error checking retraining schedule: $e');
      return false;
    }
  }

  // Get retraining statistics
  static Future<Map<String, dynamic>> getRetrainingStats() async {
    try {
      final trainingJobs = await _firestore
          .collection('ml_training')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final stats = {
        'totalJobs': trainingJobs.docs.length,
        'successfulJobs': trainingJobs.docs
            .where((doc) => doc.data()['status'] == 'completed')
            .length,
        'failedJobs': trainingJobs.docs
            .where((doc) => doc.data()['status'] == 'failed')
            .length,
        'lastTraining': trainingJobs.docs.isNotEmpty
            ? trainingJobs.docs.first.data()['createdAt']
            : null,
        'averageAccuracy': 0.85, // Mock - calculate from actual results
      };

      return stats;
    } catch (e) {
      debugPrint('Error getting retraining stats: $e');
      return {};
    }
  }
}
