import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static const String _geocodingApiKey = 'b6e78df6bba44db07b9789eff3d3d3c1'; // Same as weather API key

  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  static Future<String?> getCityFromCoordinates(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$_geocodingApiKey'
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final cityData = data[0];
          final cityName = cityData['name'] ?? '';
          final country = cityData['country'] ?? '';
          return country.isNotEmpty ? '$cityName, $country' : cityName;
        }
      }
    } catch (e) {
      print('Error getting city from coordinates: $e');
    }
    return null;
  }

  static Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }
}