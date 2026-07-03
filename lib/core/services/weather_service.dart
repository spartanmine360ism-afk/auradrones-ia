import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../models/location_snapshot.dart';
import '../models/weather_snapshot.dart';
import 'mock_data.dart';

abstract class WeatherService {
  Future<WeatherSnapshot> current(LocationSnapshot location);
}

class WeatherApiService implements WeatherService {
  WeatherApiService({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey ?? AppConstants.weatherApiKey;

  final http.Client _client;
  final String _apiKey;

  @override
  Future<WeatherSnapshot> current(LocationSnapshot location) async {
    if (_apiKey.isEmpty) return MockWeatherService().current(location);

    final currentUri =
        Uri.https('api.openweathermap.org', '/data/2.5/weather', {
          'lat': '${location.latitude}',
          'lon': '${location.longitude}',
          'appid': _apiKey,
          'units': 'metric',
          'lang': 'es',
        });
    final forecastUri =
        Uri.https('api.openweathermap.org', '/data/2.5/forecast', {
          'lat': '${location.latitude}',
          'lon': '${location.longitude}',
          'appid': _apiKey,
          'units': 'metric',
          'lang': 'es',
        });

    try {
      final responses = await Future.wait([
        _client.get(currentUri).timeout(const Duration(seconds: 12)),
        _client.get(forecastUri).timeout(const Duration(seconds: 12)),
      ]);
      if (responses.any(
        (response) => response.statusCode < 200 || response.statusCode >= 300,
      )) {
        return MockWeatherService().current(location);
      }

      final currentJson =
          jsonDecode(responses.first.body) as Map<String, dynamic>;
      final forecastJson =
          jsonDecode(responses.last.body) as Map<String, dynamic>;
      final main = currentJson['main'] as Map<String, dynamic>;
      final wind = currentJson['wind'] as Map<String, dynamic>? ?? {};
      final clouds = currentJson['clouds'] as Map<String, dynamic>? ?? {};
      final rain = currentJson['rain'] as Map<String, dynamic>? ?? {};
      final sys = currentJson['sys'] as Map<String, dynamic>? ?? {};
      final cityName = (currentJson['name'] as String?)?.trim();

      final hourly = ((forecastJson['list'] as List<dynamic>? ?? []).take(8))
          .map((item) {
            final data = item as Map<String, dynamic>;
            final itemMain = data['main'] as Map<String, dynamic>;
            final itemWind = data['wind'] as Map<String, dynamic>? ?? {};
            final pop = ((data['pop'] as num?) ?? 0) * 100;
            final dtTxt = data['dt_txt'] as String? ?? '';
            final label = dtTxt.length >= 16 ? dtTxt.substring(11, 16) : 'Hora';
            return HourlyForecast(
              label,
              (itemMain['temp'] as num).toDouble(),
              ((itemWind['speed'] as num?) ?? 0).toDouble() * 3.6,
              pop.round(),
            );
          })
          .toList();

      return WeatherSnapshot(
        city: cityName?.isNotEmpty == true ? cityName! : location.city,
        coordinates: location.coordinates,
        temperatureC: (main['temp'] as num).toDouble(),
        feelsLikeC: (main['feels_like'] as num).toDouble(),
        windKmh: ((wind['speed'] as num?) ?? 0).toDouble() * 3.6,
        gustKmh:
            ((wind['gust'] as num?) ?? wind['speed'] ?? 0).toDouble() * 3.6,
        windDirection: _directionFromDegrees((wind['deg'] as num?)?.toDouble()),
        humidity: (main['humidity'] as num).round(),
        visibilityKm:
            ((((currentJson['visibility'] as num?) ?? 0).toDouble() / 1000)
                    .clamp(0, 99))
                .toDouble(),
        cloudCover: ((clouds['all'] as num?) ?? 0).round(),
        rainChance: _estimateRainChance(forecastJson, rain),
        sunrise: _formatEpoch(sys['sunrise'] as num?),
        sunset: _formatEpoch(sys['sunset'] as num?),
        hourly: hourly.isEmpty ? MockData.weather.hourly : hourly,
      );
    } catch (_) {
      return MockWeatherService().current(location);
    }
  }

  int _estimateRainChance(
    Map<String, dynamic> forecastJson,
    Map<String, dynamic> rain,
  ) {
    final list = (forecastJson['list'] as List<dynamic>? ?? []).take(4);
    final maxPop = list.fold<double>(0, (max, item) {
      final pop = (((item as Map<String, dynamic>)['pop'] as num?) ?? 0)
          .toDouble();
      return pop > max ? pop : max;
    });
    final rainVolume = ((rain['1h'] as num?) ?? rain['3h'] ?? 0).toDouble();
    return (maxPop * 100 + (rainVolume > 0 ? 15 : 0)).clamp(0, 100).round();
  }

  String _formatEpoch(num? epoch) {
    if (epoch == null) return '--:--';
    final date = DateTime.fromMillisecondsSinceEpoch(
      epoch.toInt() * 1000,
    ).toLocal();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _directionFromDegrees(double? degrees) {
    if (degrees == null) return 'N/D';
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    return labels[((degrees + 22.5) ~/ 45) % 8];
  }
}

class MockWeatherService implements WeatherService {
  @override
  Future<WeatherSnapshot> current(LocationSnapshot location) async {
    return WeatherSnapshot(
      city: location.city,
      coordinates: location.coordinates,
      temperatureC: MockData.weather.temperatureC,
      feelsLikeC: MockData.weather.feelsLikeC,
      windKmh: MockData.weather.windKmh,
      gustKmh: MockData.weather.gustKmh,
      windDirection: MockData.weather.windDirection,
      humidity: MockData.weather.humidity,
      visibilityKm: MockData.weather.visibilityKm,
      cloudCover: MockData.weather.cloudCover,
      rainChance: MockData.weather.rainChance,
      sunrise: MockData.weather.sunrise,
      sunset: MockData.weather.sunset,
      hourly: MockData.weather.hourly,
    );
  }
}
