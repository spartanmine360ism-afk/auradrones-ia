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
          'NOAA SWPC respondió ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw const KpIndexServiceException(
          'NOAA SWPC devolvió formato inesperado.',
        );
      }

      double? latestValue;

      for (final item in decoded.reversed) {
        if (item is Map<String, dynamic>) {
          latestValue = double.tryParse('${item['Kp'] ?? item['kp']}');
        } else if (item is List && item.length >= 2) {
          latestValue = double.tryParse('${item[1]}');
        }

        if (latestValue != null) break;
      }

      if (latestValue == null) {
        throw const KpIndexServiceException(
          'NOAA SWPC no devolvió datos KP válidos.',
        );
      }

      final kp = KpIndex(
        value: latestValue,
        risk: _risk(latestValue),
        recommendation: _recommendation(latestValue),
      );

      _lastKnown = kp;
      return kp;
    } catch (_) {
      return _fallback();
    }
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
