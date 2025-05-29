import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save weather data
  static Future<void> saveWeatherData(WeatherData weather) async {
    try {
      final weatherJson = json.encode(weather.toJson());
      await _prefs?.setString('weather_data', weatherJson);
      await _prefs?.setString('last_city', weather.cityName);
    } catch (e) {
      print('Error saving weather data: $e');
    }
  }

  // Get saved weather data
  static WeatherData? getSavedWeatherData() {
    try {
      final weatherJson = _prefs?.getString('weather_data');
      if (weatherJson != null) {
        final weatherMap = json.decode(weatherJson);
        return WeatherData(
          cityName: weatherMap['cityName'],
          country: weatherMap['country'],
          temperature: weatherMap['temperature'],
          feelsLike: weatherMap['feelsLike'],
          description: weatherMap['description'],
          icon: weatherMap['icon'],
          humidity: weatherMap['humidity'],
          windSpeed: weatherMap['windSpeed'],
          uvIndex: weatherMap['uvIndex'],
          dateTime: DateTime.fromMillisecondsSinceEpoch(weatherMap['dateTime']),
          hourlyForecast: [],
          dailyForecast: [],
        );
      }
    } catch (e) {
      print('Error getting saved weather data: $e');
    }
    return null;
  }

  // Save last searched city
  static Future<void> saveLastCity(String cityName) async {
    await _prefs?.setString('last_city', cityName);
  }

  // Get last searched city
  static String? getLastCity() {
    return _prefs?.getString('last_city');
  }

  // Save favorite cities
  static Future<void> saveFavoriteCities(List<String> cities) async {
    await _prefs?.setStringList('favorite_cities', cities);
  }

  // Get favorite cities
  static List<String> getFavoriteCities() {
    return _prefs?.getStringList('favorite_cities') ?? [];
  }
}