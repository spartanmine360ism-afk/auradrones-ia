import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/kp_index.dart';

abstract class KpIndexService {
  Future<KpIndex> current();
}

class KpIndexServiceException implements Exception {
  const KpIndexServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NoaaKpIndexService implements KpIndexService {
  NoaaKpIndexService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static KpIndex? _lastKnown;

  @override
  Future<KpIndex> current() async {
    final uri = Uri.https(
      'services.swpc.noaa.gov',
      '/products/noaa-planetary-k-index.json',
    );

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw KpIndexServiceException(
          'NOAA SWPC respondio ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const KpIndexServiceException(
          'NOAA SWPC devolvio formato inesperado.',
        );
      }

      final nowUtc = DateTime.now().toUtc();
      final records =
          decoded
              .map(_parseRecord)
              .whereType<_KpRecord>()
              .where((record) => !record.timeUtc.isAfter(nowUtc))
              .toList()
            ..sort((a, b) => a.timeUtc.compareTo(b.timeUtc));

      if (records.isEmpty) {
        throw const KpIndexServiceException(
          'NOAA SWPC no devolvio datos KP validos.',
        );
      }

      final selected = records.last;
      final kp = _buildKp(selected);
      _lastKnown = kp;
      return kp;
    } catch (_) {
      return _fallback();
    }
  }

  static _KpRecord? _parseRecord(dynamic item) {
    if (item is Map<String, dynamic>) {
      final time = _parseNoaaTime(
        item['time_tag'] ?? item['time'] ?? item['datetime'],
      );
      final value = double.tryParse(
        '${item['Kp'] ?? item['kp'] ?? item['kp_index']}',
      );

      if (time != null && value != null) {
        return _KpRecord(timeUtc: time, value: value);
      }
    }

    if (item is List && item.length >= 2) {
      final time = _parseNoaaTime(item[0]);
      final value = double.tryParse('${item[1]}');

      if (time != null && value != null) {
        return _KpRecord(timeUtc: time, value: value);
      }
    }

    return null;
  }

  static DateTime? _parseNoaaTime(dynamic raw) {
    if (raw == null) return null;

    final text = '$raw'.trim();
    if (text.isEmpty || text.toLowerCase().contains('time')) return null;

    final normalized = text.contains('T') ? text : text.replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return null;

    return parsed.isUtc
        ? parsed.toUtc()
        : DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
          );
  }

  static KpIndex _buildKp(_KpRecord selected) {
    return KpIndex(
      value: selected.value,
      average: selected.value,
      recommended: selected.value,
      confidence: 'Baja',
      standardDeviation: 0,
      median: selected.value,
      minimum: selected.value,
      maximum: selected.value,
      updatedAt: selected.timeUtc,
      sources: [
        KpSource(
          source: 'NOAA Planetary K Index',
          value: selected.value,
          timestamp: selected.timeUtc,
          available: true,
        ),
      ],
      dataOrigins: const ['NOAA Planetary K Index'],
      risk: _risk(selected.value),
      recommendation: _recommendation(selected.value),
    );
  }

  static KpIndex _fallback() {
    final lastKnown = _lastKnown;
    if (lastKnown != null) {
      final recommended = lastKnown.recommended == 0
          ? lastKnown.value
          : lastKnown.recommended;

      return KpIndex(
        value: lastKnown.value,
        average: lastKnown.average == 0 ? lastKnown.value : lastKnown.average,
        recommended: recommended,
        confidence: 'Baja',
        standardDeviation: lastKnown.standardDeviation,
        median: lastKnown.median == 0 ? lastKnown.value : lastKnown.median,
        minimum: lastKnown.minimum == 0 ? lastKnown.value : lastKnown.minimum,
        maximum: lastKnown.maximum == 0 ? lastKnown.value : lastKnown.maximum,
        updatedAt: lastKnown.updatedAt,
        sources: lastKnown.sources,
        dataOrigins: lastKnown.dataOrigins,
        risk: 'KP no disponible temporalmente',
        recommendation:
            'Usando ultimo KP conocido (${recommended.toStringAsFixed(1)}). Reintenta antes de despegar.',
      );
    }

    return const KpIndex(
      value: 0,
      risk: 'KP no disponible temporalmente',
      recommendation:
          'No se pudo leer NOAA SWPC. Reintenta antes de despegar y vuela conservador.',
    );
  }

  static String _risk(double value) {
    if (value >= 6) return 'No recomendado para vuelos largos';
    if (value >= 5) return 'Riesgo GPS';
    if (value >= 4) return 'Precaucion';
    return 'Estable';
  }

  static String _recommendation(double value) {
    if (value >= 6) {
      return 'Evita vuelos largos y misiones GPS criticas.';
    }

    if (value >= 5) {
      return 'Riesgo GPS elevado; vuela solo si es necesario y cerca.';
    }

    if (value >= 4) {
      return 'Vuela cerca, revisa satelites y mantente listo para regresar.';
    }

    return 'Condiciones geomagneticas favorables para volar.';
  }
}

class _KpRecord {
  const _KpRecord({required this.timeUtc, required this.value});

  final DateTime timeUtc;
  final double value;
}
