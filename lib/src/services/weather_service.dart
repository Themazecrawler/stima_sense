import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';

class WeatherService {
  // Using WeatherAPI.com - more generous free tier
  static const String _baseUrl = 'http://api.weatherapi.com/v1';
  static const String _apiKey = '69e2983aee59492cb4a155107252407';

  // Get current weather for a location
  static Future<Map<String, dynamic>?> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/current.json?key=$_apiKey&q=$latitude,$longitude&aqi=no');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherData(data);
      } else {
        debugPrint('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      return null;
    }
  }

  // Get weather forecast for a location
  static Future<List<Map<String, dynamic>>> getWeatherForecast({
    required double latitude,
    required double longitude,
    int days = 5,
  }) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/forecast.json?key=$_apiKey&q=$latitude,$longitude&days=$days&aqi=no&alerts=no');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseForecastData(data);
      } else {
        debugPrint('Weather forecast API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching weather forecast: $e');
      return [];
    }
  }

  // Parse current weather data from WeatherAPI.com
  static Map<String, dynamic> _parseWeatherData(Map<String, dynamic> data) {
    final current = data['current'];
    final location = data['location'];

    return {
      'temperature': current['temp_c']?.toDouble(),
      'humidity': current['humidity']?.toDouble(),
      'windSpeed': current['wind_kph']?.toDouble() ?? 0.0,
      'precipitation': current['precip_mm']?.toDouble() ?? 0.0,
      'description': current['condition']['text'],
      'icon': current['condition']['icon'],
      'location': '${location['name']}, ${location['country']}',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Parse forecast data from WeatherAPI.com
  static List<Map<String, dynamic>> _parseForecastData(
      Map<String, dynamic> data) {
    final List<Map<String, dynamic>> forecast = [];
    final forecastDays = data['forecast']['forecastday'];

    for (var day in forecastDays) {
      final date = DateTime.parse(day['date']);
      final dayData = day['day'];
      final hourData = day['hour'];

      // Add daily forecast
      forecast.add({
        'temperature': dayData['avgtemp_c']?.toDouble(),
        'humidity': dayData['avghumidity']?.toDouble(),
        'windSpeed': dayData['maxwind_kph']?.toDouble() ?? 0.0,
        'precipitation': dayData['totalprecip_mm']?.toDouble() ?? 0.0,
        'description': dayData['condition']['text'],
        'date': date.toIso8601String(),
        'type': 'daily',
      });

      // Add hourly forecasts (every 6 hours)
      for (int i = 0; i < hourData.length; i += 6) {
        final hour = hourData[i];
        forecast.add({
          'temperature': hour['temp_c']?.toDouble(),
          'humidity': hour['humidity']?.toDouble(),
          'windSpeed': hour['wind_kph']?.toDouble() ?? 0.0,
          'precipitation': hour['precip_mm']?.toDouble() ?? 0.0,
          'description': hour['condition']['text'],
          'date': DateTime.parse('${day['date']} ${hour['time']}')
              .toIso8601String(),
          'type': 'hourly',
        });
      }
    }

    return forecast;
  }

  // Get weather conditions that might affect power outages
  static Map<String, dynamic> getOutageRiskFactors(
      Map<String, dynamic> weather) {
    final temp = weather['temperature'] ?? 0.0;
    final humidity = weather['humidity'] ?? 0.0;
    final windSpeed = weather['windSpeed'] ?? 0.0;
    final precipitation = weather['precipitation'] ?? 0.0;

    // Calculate risk factors based on weather conditions
    double riskScore = 0.0;
    List<String> riskFactors = [];

    // High temperature risk (overheating equipment)
    if (temp > 35) {
      riskScore += 0.3;
      riskFactors.add('High temperature');
    }

    // High humidity risk (corrosion, short circuits)
    if (humidity > 80) {
      riskScore += 0.2;
      riskFactors.add('High humidity');
    }

    // High wind risk (fallen trees, damaged lines)
    if (windSpeed > 20) {
      riskScore += 0.4;
      riskFactors.add('High wind speed');
    }

    // Heavy precipitation risk (flooding, equipment damage)
    if (precipitation > 10) {
      riskScore += 0.3;
      riskFactors.add('Heavy precipitation');
    }

    // Storm conditions (multiple factors)
    if (windSpeed > 15 && precipitation > 5) {
      riskScore += 0.2;
      riskFactors.add('Storm conditions');
    }

    return {
      'riskScore': riskScore.clamp(0.0, 1.0),
      'riskFactors': riskFactors,
      'weatherConditions': weather,
    };
  }

  // Mock weather data for development/testing
  static Map<String, dynamic> getMockWeatherData() {
    return {
      'temperature': 25.0,
      'humidity': 70.0,
      'windSpeed': 15.0,
      'precipitation': 0.0,
      'description': 'Partly cloudy',
      'icon': '//cdn.weatherapi.com/weather/64x64/day/116.png',
      'location': 'Nairobi, Kenya',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Mock forecast data for development/testing
  static List<Map<String, dynamic>> getMockForecastData() {
    return List.generate(5, (index) {
      return {
        'temperature': 20.0 + (index * 2),
        'humidity': 65.0 + (index * 3),
        'windSpeed': 10.0 + (index * 1.5),
        'precipitation': index % 2 == 0 ? 5.0 : 0.0,
        'description': index % 2 == 0 ? 'Light rain' : 'Partly cloudy',
        'date': DateTime.now().add(Duration(days: index)).toIso8601String(),
        'type': 'daily',
      };
    });
  }
}
