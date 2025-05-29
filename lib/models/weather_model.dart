class WeatherData {
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final double uvIndex;
  final DateTime dateTime;
  final List<HourlyWeather> hourlyForecast;
  final List<DailyWeather> dailyForecast;

  WeatherData({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.dateTime,
    required this.hourlyForecast,
    required this.dailyForecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'] ?? '',
      country: json['sys']['country'] ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      uvIndex: 0.0, // Will be fetched separately
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      hourlyForecast: [],
      dailyForecast: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'country': country,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'description': description,
      'icon': icon,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'uvIndex': uvIndex,
      'dateTime': dateTime.millisecondsSinceEpoch,
    };
  }
}

class HourlyWeather {
  final DateTime time;
  final double temperature;
  final String icon;
  final int humidity;

  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.icon,
    required this.humidity,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    return HourlyWeather(
      time: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      icon: json['weather'][0]['icon'] ?? '',
      humidity: json['main']['humidity'] ?? 0,
    );
  }
}

class DailyWeather {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String icon;
  final String description;

  DailyWeather({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.icon,
    required this.description,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    return DailyWeather(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      maxTemp: (json['main']['temp_max'] as num).toDouble(),
      minTemp: (json['main']['temp_min'] as num).toDouble(),
      icon: json['weather'][0]['icon'] ?? '',
      description: json['weather'][0]['description'] ?? '',
    );
  }
}