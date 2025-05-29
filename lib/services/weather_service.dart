import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class WeatherService {
  // Get API key from environment variables
  static String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Validate API key
  static bool get hasValidApiKey => _apiKey.isNotEmpty;

  // Get current weather by coordinates
  static Future<WeatherData?> getWeatherByCoordinates(double lat, double lon) async {
    if (!hasValidApiKey) {
      print('Error: OpenWeather API key not found. Please check your .env file.');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherData.fromJson(data);

        // Get hourly and daily forecasts
        final forecasts = await _getForecast(lat, lon);

        return WeatherData(
          cityName: weather.cityName,
          country: weather.country,
          temperature: weather.temperature,
          feelsLike: weather.feelsLike,
          description: weather.description,
          icon: weather.icon,
          humidity: weather.humidity,
          windSpeed: weather.windSpeed,
          uvIndex: await _getUVIndex(lat, lon),
          dateTime: weather.dateTime,
          hourlyForecast: forecasts['hourly'] as List<HourlyWeather>,
          dailyForecast: forecasts['daily'] as List<DailyWeather>,
        );
      } else {
        print('Weather API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching weather by coordinates: $e');
    }
    return null;
  }

  // Get current weather by city name
  static Future<WeatherData?> getWeatherByCity(String cityName) async {
    if (!hasValidApiKey) {
      print('Error: OpenWeather API key not found. Please check your .env file.');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherData.fromJson(data);

        final lat = data['coord']['lat'];
        final lon = data['coord']['lon'];

        // Get hourly and daily forecasts
        final forecasts = await _getForecast(lat, lon);

        return WeatherData(
          cityName: weather.cityName,
          country: weather.country,
          temperature: weather.temperature,
          feelsLike: weather.feelsLike,
          description: weather.description,
          icon: weather.icon,
          humidity: weather.humidity,
          windSpeed: weather.windSpeed,
          uvIndex: await _getUVIndex(lat, lon),
          dateTime: weather.dateTime,
          hourlyForecast: forecasts['hourly'] as List<HourlyWeather>,
          dailyForecast: forecasts['daily'] as List<DailyWeather>,
        );
      } else {
        print('Weather API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching weather by city: $e');
    }
    return null;
  }

  // Get forecast data
  static Future<Map<String, List<dynamic>>> _getForecast(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['list'];

        // Get hourly forecast (next 24 hours)
        final List<HourlyWeather> hourlyForecast = list
            .take(8)
            .map((item) => HourlyWeather.fromJson(item))
            .toList();

        // Get daily forecast (next 5 days)
        final List<DailyWeather> dailyForecast = <DailyWeather>[];
        final Map<String, Map<String, dynamic>> dailyData = {};

        for (var item in list) {
          final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dateKey = '${date.year}-${date.month}-${date.day}';

          if (!dailyData.containsKey(dateKey)) {
            dailyData[dateKey] = {
              'dt': item['dt'],
              'main': {
                'temp_max': item['main']['temp_max'],
                'temp_min': item['main']['temp_min'],
              },
              'weather': item['weather'],
            };
          } else {
            // Update max/min temperatures
            if (item['main']['temp_max'] > dailyData[dateKey]!['main']['temp_max']) {
              dailyData[dateKey]!['main']['temp_max'] = item['main']['temp_max'];
            }
            if (item['main']['temp_min'] < dailyData[dateKey]!['main']['temp_min']) {
              dailyData[dateKey]!['main']['temp_min'] = item['main']['temp_min'];
            }
          }
        }

        dailyData.values.take(5).forEach((item) {
          dailyForecast.add(DailyWeather.fromJson(item));
        });

        return {
          'hourly': hourlyForecast,
          'daily': dailyForecast,
        };
      }
    } catch (e) {
      print('Error fetching forecast: $e');
    }
    return {
      'hourly': <HourlyWeather>[],
      'daily': <DailyWeather>[],
    };
  }

  // Get UV Index
  static Future<double> _getUVIndex(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/uvi?lat=$lat&lon=$lon&appid=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['value'] as num).toDouble();
      }
    } catch (e) {
      print('Error fetching UV index: $e');
    }
    return 0.0;
  }

  // Get weather icon URL
  static String getIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }
}