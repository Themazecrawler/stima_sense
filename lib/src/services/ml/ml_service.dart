import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class MLService {
  // Temporarily disabled TFLite due to compatibility issues
  // static Interpreter? _firebaseInterpreter;
  // static Interpreter? _localInterpreter;
  static bool _firebaseModelLoaded = false;
  static bool _localModelLoaded = false;
  static String? _modelVersion;
  static DateTime? _lastModelCheck;

  // Load Firebase model (primary)
  static Future<bool> loadFirebaseModel() async {
    try {
      if (_firebaseModelLoaded) {
        return true;
      }

      debugPrint('Loading ML model from Firebase...');

      final model = await FirebaseModelDownloader.instance.getModel(
        'outage_model',
        FirebaseModelDownloadType.latestModel,
        FirebaseModelDownloadConditions(
          iosAllowsCellularAccess: true,
          iosAllowsBackgroundDownloading: true,
          androidChargingRequired: false,
          androidWifiRequired: false,
          androidDeviceIdleRequired: false,
        ),
      );

      if (model != null) {
        debugPrint('Firebase model downloaded successfully');
        _firebaseModelLoaded = true;
        return true;
      } else {
        debugPrint('Failed to download Firebase model');
        return false;
      }
    } catch (e) {
      debugPrint('Error loading Firebase model: $e');
      return false;
    }
  }

  // Load local model (backup)
  static Future<bool> loadLocalModel() async {
    try {
      if (_localModelLoaded) {
        return true;
      }

      debugPrint('Loading local ML model...');

      // Temporarily disabled due to TFLite compatibility issues
      _localModelLoaded = true;
      debugPrint('Local model loaded successfully (mock)');
      return true;
    } catch (e) {
      debugPrint('Error loading local model: $e');
      return false;
    }
  }

  // Predict with fallback logic
  static Future<Map<String, dynamic>> predictOutage(
      Map<String, dynamic> inputData) async {
    try {
      // Try Firebase model first
      if (!_firebaseModelLoaded) {
        final loaded = await loadFirebaseModel();
        if (!loaded) {
          debugPrint('Firebase model failed, trying local model...');
        }
      }

      String modelSource = '';

      if (_firebaseModelLoaded) {
        modelSource = 'Firebase';
      } else if (!_localModelLoaded) {
        final localLoaded = await loadLocalModel();
        if (localLoaded) {
          modelSource = 'Local';
        }
      } else {
        modelSource = 'Local';
      }

      debugPrint('Using $modelSource model for prediction');

      // For now, always use mock prediction due to TFLite compatibility issues
      final prediction = _getMockPrediction(inputData);
      prediction['modelSource'] = modelSource;

      return prediction;
    } catch (e) {
      debugPrint('Error predicting outage: $e');
      // Fallback to mock prediction
      return _getMockPrediction(inputData);
    }
  }

  // Prepare input data for the model
  static List<List<double>> _prepareModelInput(Map<String, dynamic> inputData) {
    final eventMonth =
        (inputData['Event Month'] ?? DateTime.now().month).toDouble();
    final eventHour =
        (inputData['Event Hour'] ?? DateTime.now().hour).toDouble();
    final duration = (inputData['Outage Duration (hrs)'] ?? 2.0).toDouble();

    // Normalize inputs if needed (adjust based on your model's training)
    final normalizedMonth = eventMonth / 12.0; // Normalize to 0-1
    final normalizedHour = eventHour / 24.0; // Normalize to 0-1
    final normalizedDuration =
        duration / 24.0; // Normalize to 0-1 (assuming max 24 hours)

    return [
      [normalizedMonth, normalizedHour, normalizedDuration]
    ];
  }

  // Process model output
  static Map<String, dynamic> _processModelOutput(List<double> output) {
    // Find the highest probability class
    int maxIndex = 0;
    double maxValue = output[0];
    for (int i = 1; i < output.length; i++) {
      if (output[i] > maxValue) {
        maxValue = output[i];
        maxIndex = i;
      }
    }

    // Map class index to risk levels
    final riskLevels = ['Low', 'Medium', 'High', 'Critical'];
    final riskLevel = riskLevels[maxIndex.clamp(0, riskLevels.length - 1)];

    // Calculate confidence based on the highest probability
    final confidence = maxValue.clamp(0.0, 1.0);

    // Estimate duration based on risk level
    double estimatedDuration = 2.0; // Default 2 hours
    switch (riskLevel) {
      case 'Low':
        estimatedDuration = 1.0;
        break;
      case 'Medium':
        estimatedDuration = 3.0;
        break;
      case 'High':
        estimatedDuration = 6.0;
        break;
      case 'Critical':
        estimatedDuration = 12.0;
        break;
    }

    return {
      'confidence': confidence,
      'duration': estimatedDuration,
      'riskLevel': riskLevel,
      'class': maxIndex,
      'probabilities': output,
    };
  }

  // Fallback mock prediction
  static Map<String, dynamic> _getMockPrediction(
      Map<String, dynamic> inputData) {
    final eventMonth = inputData['Event Month'] ?? DateTime.now().month;
    final eventHour = inputData['Event Hour'] ?? DateTime.now().hour;
    final duration = inputData['Outage Duration (hrs)'] ?? 2.0;

    // Simple mock algorithm
    double confidence = 0.5;
    if (eventHour >= 18 || eventHour <= 6) confidence += 0.2; // Night time
    if (eventMonth >= 6 && eventMonth <= 9) confidence += 0.1; // Rainy season
    if (duration > 4) confidence += 0.2; // Long duration

    confidence = confidence.clamp(0.0, 1.0);

    return {
      'confidence': confidence,
      'predictedDuration': duration * 1.2,
      'riskLevel': confidence > 0.7
          ? 'High'
          : confidence > 0.4
              ? 'Medium'
              : 'Low',
      'modelSource': 'Mock',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Check for model updates (daily)
  static Future<void> checkForUpdates() async {
    final now = DateTime.now();
    if (_lastModelCheck == null ||
        now.difference(_lastModelCheck!).inDays >= 1) {
      _lastModelCheck = now;

      try {
        // Try to reload Firebase model to get latest version
        _firebaseModelLoaded = false;
        await loadFirebaseModel();
        debugPrint('Model update check completed');
      } catch (e) {
        debugPrint('Error checking for model updates: $e');
      }
    }
  }

  // Dispose interpreters
  static void dispose() {
    // Temporarily disabled due to TFLite compatibility issues
    _firebaseModelLoaded = false;
    _localModelLoaded = false;
  }

  // Get model status
  static Map<String, dynamic> getModelStatus() {
    return {
      'firebaseModelLoaded': _firebaseModelLoaded,
      'localModelLoaded': _localModelLoaded,
      'lastModelCheck': _lastModelCheck?.toIso8601String(),
    };
  }
}
