import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/location_snapshot.dart';
import '../models/weather_snapshot.dart';

abstract class WeatherService {
  Future<WeatherSnapshot> current(LocationSnapshot location);
}

class WeatherServiceException implements Exception {
  const WeatherServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WeatherApiService implements WeatherService {
  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static WeatherSnapshot? _lastKnown;

  @override
  Future<WeatherSnapshot> current(LocationSnapshot location) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${location.latitude}',
      'longitude': '${location.longitude}',
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,cloud_cover,visibility,wind_speed_10m,wind_gusts_10m,wind_direction_10m',
      'hourly':
          'temperature_2m,precipitation_probability,wind_speed_10m,wind_gusts_10m',
      'daily': 'sunrise,sunset',
      'timezone': 'auto',
    });

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const WeatherServiceException(
          'Clima no disponible temporalmente',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final snapshot = _fromOpenMeteo(json, location);
      _lastKnown = snapshot;
      return snapshot;
    } on WeatherServiceException {
      final cached = _lastKnown;
      if (cached != null) return cached;
      rethrow;
    } catch (_) {
      final cached = _lastKnown;
      if (cached != null) return cached;
      throw const WeatherServiceException('Clima no disponible temporalmente');
    }
  }

  WeatherSnapshot _fromOpenMeteo(
    Map<String, dynamic> json,
    LocationSnapshot location,
  ) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final hourly = json['hourly'] as Map<String, dynamic>? ?? {};
    final daily = json['daily'] as Map<String, dynamic>? ?? {};

    final hourlyForecast = _hourlyForecast(hourly);

    return WeatherSnapshot(
      city: location.city,
      coordinates: location.coordinates,
      temperatureC: _number(current['temperature_2m']),
      feelsLikeC: _number(current['apparent_temperature']),
      windKmh: _number(current['wind_speed_10m']),
      gustKmh: _number(current['wind_gusts_10m']),
      windDirection: _directionFromDegrees(
        _number(current['wind_direction_10m']),
      ),
      humidity: _number(current['relative_humidity_2m']).round(),
      visibilityKm: (_number(current['visibility']) / 1000)
          .clamp(0, 99)
          .toDouble(),
      cloudCover: _number(current['cloud_cover']).round(),
      rainChance: hourlyForecast.isEmpty
          ? _rainFromPrecipitation(current)
          : hourlyForecast.first.rainChance,
      sunrise: _timeFromDaily(daily['sunrise']),
      sunset: _timeFromDaily(daily['sunset']),
      hourly: hourlyForecast,
    );
  }

  List<HourlyForecast> _hourlyForecast(Map<String, dynamic> hourly) {
    final times = hourly['time'] as List<dynamic>? ?? [];
    final temps = hourly['temperature_2m'] as List<dynamic>? ?? [];
    final rain = hourly['precipitation_probability'] as List<dynamic>? ?? [];
    final wind = hourly['wind_speed_10m'] as List<dynamic>? ?? [];

    if (times.isEmpty || temps.isEmpty || rain.isEmpty || wind.isEmpty) {
      return const [];
    }

    final length = [
      times.length,
      temps.length,
      rain.length,
      wind.length,
    ].fold<int>(8, (max, value) => value < max ? value : max);

    return List.generate(length.clamp(0, 8), (index) {
      final rawTime = times[index].toString();
      final label = rawTime.length >= 16 ? rawTime.substring(11, 16) : 'Hora';
      return HourlyForecast(
        label,
        _number(temps[index]),
        _number(wind[index]),
        _number(rain[index]).round(),
      );
    });
  }

  int _rainFromPrecipitation(Map<String, dynamic> current) {
    final precipitation = _number(current['precipitation']);
    if (precipitation <= 0) return 0;
    if (precipitation < 0.5) return 35;
    if (precipitation < 2) return 65;
    return 90;
  }

  String _timeFromDaily(dynamic value) {
    final list = value as List<dynamic>? ?? [];
    if (list.isEmpty) return '--:--';

    final text = list.first.toString();
    return text.length >= 16 ? text.substring(11, 16) : '--:--';
  }

  double _number(dynamic value) {
    return value is num ? value.toDouble() : 0;
  }

  String _directionFromDegrees(double degrees) {
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    return labels[((degrees + 22.5) ~/ 45) % 8];
  }
}
