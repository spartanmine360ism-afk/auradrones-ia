import 'package:http/http.dart' as http;

import '../models/kp_index.dart';
import 'kp_index_service.dart';
import 'space_weather_engine.dart';

export 'kp_index_service.dart' show KpIndexService;

class AuraKpIndexService implements KpIndexService {
  AuraKpIndexService({AuraSpaceWeatherEngine? engine, http.Client? client})
    : _engine = engine ?? AuraSpaceWeatherEngine(client: client);

  final AuraSpaceWeatherEngine _engine;
  static KpIndex? _lastKnown;

  @override
  Future<KpIndex> current() async {
    final kp = await _engine.current();

    if (kp.sources.any((source) => source.available)) {
      _lastKnown = kp;
      return kp;
    }

    final cached = _lastKnown;
    if (cached != null) {
      return KpIndex(
        value: cached.value,
        average: cached.average,
        recommended: cached.recommended,
        confidence: 'Baja',
        standardDeviation: cached.standardDeviation,
        median: cached.median,
        minimum: cached.minimum,
        maximum: cached.maximum,
        updatedAt: cached.updatedAt,
        sources: kp.sources,
        dataOrigins: cached.dataOrigins,
        risk: 'KP no disponible temporalmente',
        recommendation:
            'Usando ultimo KP Aura conocido (${cached.recommended.toStringAsFixed(1)}). Reintenta antes de despegar.',
      );
    }

    return kp;
  }
}
