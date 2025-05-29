import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../widgets/weather_card.dart';
import '../widgets/hourly_chart.dart';
import '../widgets/daily_forecast.dart';
import '../widgets/search_bar.dart';
import '../widgets/floating_bottom_nav.dart';
import 'weekly_forecast_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin {
  WeatherData? _weatherData;
  bool _isLoading = true;
  bool _showSearch = false;
  int _selectedNavIndex = 0;
  String _currentCityName = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadWeatherData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherData() async {
    setState(() => _isLoading = true);

    try {
      // Try to get current location first
      final position = await LocationService.getCurrentLocation();
      WeatherData? weather;

      if (position != null) {
        // Get city name from coordinates
        final cityName = await LocationService.getCityFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (cityName != null) {
          // Use city name to get weather data
          weather = await WeatherService.getWeatherByCity(cityName);
          _currentCityName = cityName;
        }
      }

      if (weather == null) {
        // Fallback to last saved city or default city
        final lastCity = StorageService.getLastCity() ?? 'London';
        weather = await WeatherService.getWeatherByCity(lastCity);
        _currentCityName = lastCity;
      }

      if (weather != null) {
        await StorageService.saveWeatherData(weather);
        await StorageService.saveLastCity(_currentCityName);
        setState(() {
          _weatherData = weather;
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        // Load saved data if available
        final savedWeather = StorageService.getSavedWeatherData();
        setState(() {
          _weatherData = savedWeather;
          _isLoading = false;
        });
        if (savedWeather != null) {
          _currentCityName = savedWeather.cityName;
          _animationController.forward();
        }
      }
    } catch (e) {
      print('Error loading weather data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCurrentLocationWeather() async {
    setState(() => _isLoading = true);

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        // Get city name from coordinates
        final cityName = await LocationService.getCityFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (cityName != null) {
          // Use city name to get weather data
          final weather = await WeatherService.getWeatherByCity(cityName);

          if (weather != null) {
            await StorageService.saveWeatherData(weather);
            await StorageService.saveLastCity(cityName);
            setState(() {
              _weatherData = weather;
              _currentCityName = cityName;
              _isLoading = false;
            });
            _animationController.reset();
            _animationController.forward();
          } else {
            setState(() => _isLoading = false);
            _showErrorSnackBar('Unable to get weather for current location');
          }
        } else {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Unable to identify city from current location');
        }
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Location permission denied');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error getting current location weather');
    }
  }

  Future<void> _searchCity(String cityName) async {
    setState(() => _isLoading = true);

    try {
      final weather = await WeatherService.getWeatherByCity(cityName);
      if (weather != null) {
        await StorageService.saveWeatherData(weather);
        await StorageService.saveLastCity(cityName);
        setState(() {
          _weatherData = weather;
          _currentCityName = cityName;
          _isLoading = false;
          _showSearch = false;
        });
        _animationController.reset();
        _animationController.forward();
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackBar('City not found');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error fetching weather data');
    }
  }

  void _onNavItemTapped(int index) {
    setState(() => _selectedNavIndex = index);

    switch (index) {
      case 0: // Home
      // Already on home screen
        break;
      case 1: // Location
        _loadCurrentLocationWeather();
        break;
      case 2: // Notifications
        _showErrorSnackBar('Notifications feature coming soon!');
        break;
      case 3: // Profile
        _showErrorSnackBar('Profile feature coming soon!');
        break;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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

  String _getUVLevel(double uvIndex) {
    if (uvIndex <= 2) return 'Low';
    if (uvIndex <= 5) return 'Moderate';
    if (uvIndex <= 7) return 'High';
    if (uvIndex <= 10) return 'Very High';
    return 'Extreme';
  }

  void _showWeeklyForecast() {
    if (_currentCityName.isNotEmpty) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => WeeklyForecastScreen(
            cityName: _currentCityName,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      _showErrorSnackBar('City information not available for weekly forecast');
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
          child: Stack(
            children: [
              _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : _weatherData == null
                  ? _buildErrorState()
                  : _buildWeatherContent(),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FloatingBottomNav(
                  selectedIndex: _selectedNavIndex,
                  onItemTapped: _onNavItemTapped,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load weather data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadWeatherData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF87CEEB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildMainWeatherInfo(),
            const SizedBox(height: 30),
            _buildWeatherMetrics(),
            const SizedBox(height: 30),
            _buildTodaySection(),
            const SizedBox(height: 30),
            _buildDailyForecast(),
            const SizedBox(height: 20),
            _buildNextWeekButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() => _showSearch = !_showSearch);
          },
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
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainWeatherInfo() {
    return Column(
      children: [
        if (_showSearch)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: WeatherSearchBar(
              onSearch: _searchCity,
              onClose: () => setState(() => _showSearch = false),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_weatherData!.temperature.round()}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_weatherData!.cityName}, ${_weatherData!.country}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_weatherData!.temperature.round()}°/${_weatherData!.feelsLike.round()}° Feels like ${_weatherData!.feelsLike.round()}°',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    DateFormat('E, hh:mm a').format(_weatherData!.dateTime),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    _getWeatherEmoji(_weatherData!.icon),
                    style: const TextStyle(fontSize: 80),
                  ),
                  if (_weatherData!.description.contains('rain'))
                    const Text(
                      '🌧️💧💧💧',
                      style: TextStyle(fontSize: 24),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherMetrics() {
    return Row(
      children: [
        Expanded(
          child: WeatherCard(
            title: 'UV Index',
            value: _getUVLevel(_weatherData!.uvIndex),
            icon: '☀️',
            subtitle: _weatherData!.uvIndex.toStringAsFixed(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: WeatherCard(
            title: 'Humidity',
            value: '${_weatherData!.humidity}%',
            icon: '💧',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: WeatherCard(
            title: 'Wind',
            value: '${_weatherData!.windSpeed.round()} km/h',
            icon: '💨',
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        if (_weatherData!.hourlyForecast.isNotEmpty)
          HourlyChart(hourlyData: _weatherData!.hourlyForecast)
        else
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Hourly forecast not available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDailyForecast() {
    if (_weatherData!.dailyForecast.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Daily forecast not available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Row(
      children: _weatherData!.dailyForecast.take(3).map((daily) {
        final isToday = daily.date.day == DateTime.now().day;
        final dayName = isToday
            ? 'Today'
            : DateFormat('E').format(daily.date);

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: DailyForecastCard(
              day: dayName,
              temperature: '${daily.maxTemp.round()}°',
              icon: _getWeatherEmoji(daily.icon),
              isSelected: isToday,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextWeekButton() {
    return Center(
      child: GestureDetector(
        onTap: _showWeeklyForecast,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Next Week',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}