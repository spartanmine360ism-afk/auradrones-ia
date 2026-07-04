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
      final rows = jsonDecode(response.body) as List<dynamic>;
      final dataRows = rows
          .whereType<List<dynamic>>()
          .where(
            (row) => row.length >= 2 && double.tryParse('${row[1]}') != null,
          )
          .toList();
      if (dataRows.isEmpty) {
        throw const KpIndexServiceException('NOAA SWPC no devolvio datos KP.');
      }
      final latest = dataRows.last;
      final value = double.parse('${latest[1]}');
      return KpIndex(
        value: value,
        risk: _risk(value),
        recommendation: _recommendation(value),
      );
    } on KpIndexServiceException {
      rethrow;
    } catch (error) {
      throw KpIndexServiceException('No se pudo consultar NOAA SWPC: $error');
    }
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
