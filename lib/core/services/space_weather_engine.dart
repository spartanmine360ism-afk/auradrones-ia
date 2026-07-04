import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/kp_index.dart';
import 'kp_compare_engine.dart';

/// Aura Space Weather Engine downloads each free provider independently and
/// produces one transparent KP value with confidence and dispersion metrics.
class AuraSpaceWeatherEngine {
  AuraSpaceWeatherEngine({http.Client? client, KpCompareEngine? compareEngine})
    : _client = client ?? http.Client(),
      _compareEngine = compareEngine ?? KpCompareEngine();

  final http.Client _client;
  final KpCompareEngine _compareEngine;

  Future<KpIndex> current() async {
    final sources = await Future.wait([
      _noaaPlanetaryKIndex(),
      _noaaSwpcOneMinuteKp(),
      _gfzPotsdamKp(),
      _noaaSolarWindKpProxy(),
      _noaaOvationKpProxy(),
      _spaceWeatherLiveUnavailable(),
    ]);

    return _compareEngine.compare(sources);
  }

  Future<KpSource> _noaaPlanetaryKIndex() async {
    return _guard('NOAA Planetary K Index', () async {
      final response = await _client
          .get(
            Uri.https(
              'services.swpc.noaa.gov',
              '/products/noaa-planetary-k-index.json',
            ),
          )
          .timeout(const Duration(seconds: 10));
      _ensureOk(response);

      final decoded = jsonDecode(response.body);
      final row = _lastListRow(decoded);
      final value = double.parse('${row[1]}');
      final timestamp =
          DateTime.tryParse('${row[0]}Z') ?? DateTime.now().toUtc();
      return _available('NOAA Planetary K Index', value, timestamp);
    });
  }

  Future<KpSource> _noaaSwpcOneMinuteKp() async {
    return _guard('NOAA SWPC 1m KP', () async {
      final response = await _client
          .get(
            Uri.https(
              'services.swpc.noaa.gov',
              '/json/planetary_k_index_1m.json',
            ),
          )
          .timeout(const Duration(seconds: 10));
      _ensureOk(response);

      final decoded = jsonDecode(response.body);
      final item = _lastMap(decoded);
      final value = _firstNumber(item, ['kp_index', 'Kp', 'kp']);
      final timestamp = _firstDate(item, ['time_tag', 'time', 'datetime']);
      return _available('NOAA SWPC 1m KP', value, timestamp);
    });
  }

  Future<KpSource> _gfzPotsdamKp() async {
    return _guard('GFZ Potsdam', () async {
      final now = DateTime.now().toUtc();
      final start = now.subtract(const Duration(days: 3));
      final response = await _client
          .get(
            Uri.https('kp.gfz-potsdam.de', '/app/json/', {
              'start': start.toIso8601String(),
              'end': now.toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));
      _ensureOk(response);

      final decoded = jsonDecode(response.body);
      final item = _lastMap(decoded);
      final value = _firstNumber(item, ['Kp', 'kp', 'value']);
      final timestamp = _firstDate(item, ['time', 'datetime', 'timestamp']);
      return _available('GFZ Potsdam', value, timestamp);
    });
  }

  Future<KpSource> _noaaSolarWindKpProxy() async {
    return _guard('NOAA Solar Wind', () async {
      final plasma = await _client
          .get(
            Uri.https(
              'services.swpc.noaa.gov',
              '/products/solar-wind/plasma-7-day.json',
            ),
          )
          .timeout(const Duration(seconds: 10));
      final mag = await _client
          .get(
            Uri.https(
              'services.swpc.noaa.gov',
              '/products/solar-wind/mag-7-day.json',
            ),
          )
          .timeout(const Duration(seconds: 10));
      _ensureOk(plasma);
      _ensureOk(mag);

      final plasmaRow = _lastListRow(jsonDecode(plasma.body));
      final magRow = _lastListRow(jsonDecode(mag.body));
      final speed = double.parse('${plasmaRow[2]}');
      final bz = double.parse('${magRow[3]}');
      final value = _solarWindToKp(speed, bz);
      final timestamp =
          DateTime.tryParse('${plasmaRow[0]}Z') ?? DateTime.now().toUtc();
      return _available('NOAA Solar Wind', value, timestamp);
    });
  }

  Future<KpSource> _noaaOvationKpProxy() async {
    return _guard('NOAA Ovation', () async {
      final response = await _client
          .get(
            Uri.https(
              'services.swpc.noaa.gov',
              '/json/ovation_aurora_latest.json',
            ),
          )
          .timeout(const Duration(seconds: 10));
      _ensureOk(response);

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final coordinates = decoded['coordinates'] as List<dynamic>? ?? [];
      final powers = coordinates
          .whereType<List<dynamic>>()
          .where((row) => row.length >= 3)
          .map((row) => double.tryParse('${row[2]}') ?? 0)
          .toList();
      if (powers.isEmpty) throw const FormatException('empty ovation');

      powers.sort();
      final percentile95 =
          powers[(powers.length * .95).floor().clamp(0, powers.length - 1)];
      final value = (percentile95 / 12).clamp(0, 9).toDouble();
      final rawTime = decoded['Observation Time'] ?? decoded['Forecast Time'];
      final timestamp =
          DateTime.tryParse('${rawTime ?? ''}Z') ?? DateTime.now().toUtc();
      return _available('NOAA Ovation', value, timestamp);
    });
  }

  Future<KpSource> _spaceWeatherLiveUnavailable() async {
    return KpSource(
      source: 'SpaceWeatherLive',
      value: 0,
      timestamp: DateTime.now().toUtc(),
      available: false,
      error: 'Sin API publica gratuita estable; scraping deshabilitado.',
    );
  }

  Future<KpSource> _guard(
    String source,
    Future<KpSource> Function() request,
  ) async {
    try {
      return await request();
    } catch (error) {
      return KpSource(
        source: source,
        value: 0,
        timestamp: DateTime.now().toUtc(),
        available: false,
        error: '$error',
      );
    }
  }

  KpSource _available(String source, double value, DateTime timestamp) {
    return KpSource(
      source: source,
      value: value.clamp(0, 9).toDouble(),
      timestamp: timestamp,
      available: true,
    );
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException('HTTP ${response.statusCode}');
    }
  }

  List<dynamic> _lastListRow(dynamic decoded) {
    if (decoded is! List) throw const FormatException('expected list');
    for (final row in decoded.reversed) {
      if (row is List &&
          row.length >= 2 &&
          double.tryParse('${row[1]}') != null) {
        return row;
      }
    }
    throw const FormatException('no numeric rows');
  }

  Map<String, dynamic> _lastMap(dynamic decoded) {
    final list = decoded is List
        ? decoded
        : decoded is Map<String, dynamic>
        ? (decoded['data'] as List<dynamic>? ??
              decoded['observations'] as List<dynamic>? ??
              [])
        : const [];
    for (final item in list.reversed) {
      if (item is Map<String, dynamic>) return item;
    }
    throw const FormatException('no object rows');
  }

  double _firstNumber(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = double.tryParse('${item[key]}');
      if (value != null) return value;
    }
    throw const FormatException('no numeric value');
  }

  DateTime _firstDate(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = DateTime.tryParse('${item[key]}');
      if (value != null) return value.toUtc();
    }
    return DateTime.now().toUtc();
  }

  double _solarWindToKp(double speedKms, double bzNt) {
    final speedScore = max(0, (speedKms - 320) / 90);
    final southwardBzScore = bzNt < 0 ? bzNt.abs() / 2.8 : 0;
    return (speedScore + southwardBzScore).clamp(0, 9).toDouble();
  }
}
