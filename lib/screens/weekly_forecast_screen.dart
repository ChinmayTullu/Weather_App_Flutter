import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeeklyForecastScreen extends StatefulWidget {
  final String cityName;

  const WeeklyForecastScreen({
    super.key,
    required this.cityName,
  });

  @override
  State<WeeklyForecastScreen> createState() => _WeeklyForecastScreenState();
}

class _WeeklyForecastScreenState extends State<WeeklyForecastScreen>
    with TickerProviderStateMixin {
  List<DailyWeather> weeklyForecast = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _loadWeeklyForecast();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWeeklyForecast() async {
    try {
      // Try to get real weather data for the city first
      final weather = await WeatherService.getWeatherByCity(widget.cityName);

      if (weather != null && weather.dailyForecast.isNotEmpty) {
        // Use real forecast data if available
        setState(() {
          weeklyForecast = weather.dailyForecast;
          isLoading = false;
        });
      } else {
        // Generate enhanced mock weekly data based on current city
        final List<DailyWeather> forecast = [];
        final now = DateTime.now();

        // Base temperatures that vary by city name (simple hash-based variation)
        final cityHash = widget.cityName.hashCode.abs();
        final baseTemp = 15 + (cityHash % 20); // Temperature between 15-35°C

        for (int i = 0; i < 7; i++) {
          final date = now.add(Duration(days: i));
          final tempVariation = (cityHash + i * 7) % 15; // Variation 0-15°C
          final weatherPattern = (cityHash + i * 3) % 7;

          forecast.add(DailyWeather(
            date: date,
            maxTemp: (baseTemp + tempVariation + (i % 3 == 0 ? 3 : 0)).toDouble(),
            minTemp: (baseTemp + tempVariation - 5 + (i % 2 == 0 ? 2 : 0)).toDouble(),
            icon: ['01d', '02d', '03d', '10d', '11d', '13d', '50d'][weatherPattern],
            description: [
              'Sunny',
              'Partly Cloudy',
              'Cloudy',
              'Light Rain',
              'Thunderstorm',
              'Snow',
              'Foggy'
            ][weatherPattern],
          ));
        }

        setState(() {
          weeklyForecast = forecast;
          isLoading = false;
        });
      }

      _animationController.forward();
    } catch (e) {
      print('Error loading weekly forecast: $e');
      setState(() => isLoading = false);
    }
  }

  String _getWeatherEmoji(String iconCode) {
    switch (iconCode.substring(0, 2)) {
      case '01': return '☀️';
      case '02': return '⛅';
      case '03': return '☁️';
      case '04': return '☁️';
      case '09': return '🌧️';
      case '10': return '🌦️';
      case '11': return '⛈️';
      case '13': return '❄️';
      case '50': return '🌫️';
      default: return '🌤️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB),
              Color(0xFF98D8E8),
              Color(0xFFB8E6F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : _buildWeeklyForecast(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '7-Day Forecast',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.cityName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyForecast() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: weeklyForecast.length,
          itemBuilder: (context, index) {
            final forecast = weeklyForecast[index];
            final isToday = index == 0;
            final dayName = isToday
                ? 'Today'
                : DateFormat('EEEE').format(forecast.date);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isToday ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(isToday ? 0.4 : 0.2),
                  width: 1,
                ),
                boxShadow: isToday ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ] : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isToday ? 18 : 16,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd').format(forecast.date),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          forecast.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _getWeatherEmoji(forecast.icon),
                        style: TextStyle(
                          fontSize: isToday ? 50 : 40,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${forecast.maxTemp.round()}°',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isToday ? 24 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${forecast.minTemp.round()}°',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: isToday ? 18 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}