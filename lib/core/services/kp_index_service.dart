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
          'NOAA SWPC respondio ${response.statusCode}: ${response.body}',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List<dynamic>) {
        throw const KpIndexServiceException(
          'NOAA SWPC devolvio formato inesperado.',
        );
      }
      final latest = decoded.whereType<List<dynamic>>().lastWhere(
        _isValidKpRow,
        orElse: () => const [],
      );
      if (latest.isEmpty) {
        throw const KpIndexServiceException('NOAA SWPC no devolvio datos KP.');
      }
      final value = double.parse('${latest[1]}');
      final kp = KpIndex(
        value: value,
        risk: _risk(value),
        recommendation: _recommendation(value),
      );
      _lastKnown = kp;
      return kp;
    } on KpIndexServiceException {
      return _fallback();
    } catch (error) {
      return _fallback();
    }
  }

  bool _isValidKpRow(List<dynamic> row) {
    if (row.length < 2) return false;
    final time = DateTime.tryParse('${row[0]}');
    final kp = double.tryParse('${row[1]}');
    return time != null && kp != null;
  }

  KpIndex _fallback() {
    final lastKnown = _lastKnown;
    if (lastKnown != null) {
      return KpIndex(
        value: lastKnown.value,
        risk: 'KP no disponible temporalmente',
        recommendation:
            'Usando ultimo KP conocido (${lastKnown.value.toStringAsFixed(1)}). Reintenta antes de despegar.',
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
    if (value >= 4) return 'Precaucion';
    return 'Estable';
  }

  String _recommendation(double value) {
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
