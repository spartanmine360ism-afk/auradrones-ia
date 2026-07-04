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
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 12),
          );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw KpIndexServiceException(
          'NOAA SWPC respondió ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw const KpIndexServiceException(
          'NOAA SWPC devolvió formato inesperado.',
        );
      }

      final nowUtc = DateTime.now().toUtc();
      final records = <_KpRecord>[];

      for (final item in decoded) {
        final record = _parseRecord(item);
        if (record != null) records.add(record);
      }

      records.sort((a, b) => a.timeUtc.compareTo(b.timeUtc));

      final validRecords = records
          .where((record) => !record.timeUtc.isAfter(nowUtc))
          .toList();

      final selected = validRecords.isNotEmpty
          ? validRecords.last
          : records.isNotEmpty
              ? records.first
              : null;

      if (selected == null) {
        throw const KpIndexServiceException(
          'NOAA SWPC no devolvió datos KP válidos.',
        );
      }

      final kp = KpIndex(
        value: selected.value,
        risk: _risk(selected.value),
        recommendation: _recommendation(selected.value),
      );

      _lastKnown = kp;
      return kp;
    } catch (_) {
      return _fallback();
    }
  }

  _KpRecord? _parseRecord(dynamic item) {
    if (item is Map<String, dynamic>) {
      final timeRaw = item['time_tag'] ?? item['time'] ?? item['datetime'];
      final kpRaw = item['Kp'] ?? item['kp'] ?? item['kp_index'];

      final time = _parseNoaaTime(timeRaw);
      final value = double.tryParse('$kpRaw');

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

  DateTime? _parseNoaaTime(dynamic raw) {
    if (raw == null) return null;

    final text = '$raw'.trim();
    if (text.isEmpty || text.toLowerCase().contains('time')) return null;

    final normalized = text.contains('T')
        ? text
        : text.replaceFirst(' ', 'T');

    final parsed = DateTime.tryParse(normalized);

    if (parsed == null) return null;

    return parsed.isUtc ? parsed : DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    );
  }

  KpIndex _fallback() {
    final lastKnown = _lastKnown;

    if (lastKnown != null) {
      return KpIndex(
        value: lastKnown.value,
        risk: 'KP no disponible temporalmente',
        recommendation:
            'Usando último KP conocido (${lastKnown.value.toStringAsFixed(1)}). Reintenta antes de despegar.',
      );
    }

    return const KpIndex(
      value: 0,
      risk: 'KP no disponible temporalmente',
      recommendation:
          'No se pudo leer NOAA SWPC. Reintenta antes de despegar y vuela conservador.',
    );
  }

  String _risk(double value) {
    if (value >= 6) return 'No recomendado para vuelos largos';
    if (value >= 5) return 'Riesgo GPS';
    if (value >= 4) return 'Precaución';
    return 'Estable';
  }

  String _recommendation(double value) {
    if (value >= 6) {
      return 'Evita vuelos largos y misiones GPS críticas.';
    }

    if (value >= 5) {
      return 'Riesgo GPS elevado; vuela solo si es necesario y cerca.';
    }

    if (value >= 4) {
      return 'Vuela cerca, revisa satélites y mantente listo para regresar.';
    }

    return 'Condiciones geomagnéticas favorables para volar.';
  }
}

class _KpRecord {
  const _KpRecord({
    required this.timeUtc,
    required this.value,
  });

  final DateTime timeUtc;
  final double value;
}