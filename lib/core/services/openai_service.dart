import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../models/ai_chat_message.dart';
import '../models/battery.dart';
import '../models/drone.dart';
import '../models/fly_score.dart';
import '../models/kp_index.dart';
import '../models/location_snapshot.dart';
import '../models/weather_snapshot.dart';

abstract class OpenAIService {
  Future<String> ask({
    required String message,
    required List<AiChatMessage> history,
    required WeatherSnapshot weather,
    required LocationSnapshot location,
    required KpIndex kp,
    required FlyScore flyScore,
    required Drone drone,
    required List<Drone> drones,
    required DroneBattery battery,
    required String pilotLevel,
    required double totalFlightHours,
  });
}

class OpenAIServiceException implements Exception {
  const OpenAIServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OpenAIChatService implements OpenAIService {
  OpenAIChatService({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey ?? AppConstants.openAiApiKey;

  final http.Client _client;
  final String _apiKey;

  @override
  Future<String> ask({
    required String message,
    required List<AiChatMessage> history,
    required WeatherSnapshot weather,
    required LocationSnapshot location,
    required KpIndex kp,
    required FlyScore flyScore,
    required Drone drone,
    required List<Drone> drones,
    required DroneBattery battery,
    required String pilotLevel,
    required double totalFlightHours,
  }) async {
    if (_apiKey.isEmpty) {
      return MockOpenAIService().ask(
        message: message,
        history: history,
        weather: weather,
        location: location,
        kp: kp,
        flyScore: flyScore,
        drone: drone,
        drones: drones,
        battery: battery,
        pilotLevel: pilotLevel,
        totalFlightHours: totalFlightHours,
      );
    }

    final context =
        '''
Mensaje exacto del usuario: $message
Ubicacion: ${location.city} (${location.coordinates}), precision ${location.accuracyMeters.round()} m.
Clima: ${weather.temperatureC.round()} C, viento ${weather.windKmh.round()} km/h, rachas ${weather.gustKmh.round()} km/h, lluvia ${weather.rainChance}%, visibilidad ${weather.visibilityKm} km, nubes ${weather.cloudCover}%.
KP: ${kp.value} (${kp.risk}).
Fly Score: ${flyScore.value}, estado ${flyScore.status}. Recomendacion: ${flyScore.recommendation}.
Dron activo: ${drone.brand} ${drone.model}, tipo ${drone.type}, ${drone.weightGrams} g.
Drones del usuario: ${drones.map((item) => '${item.brand} ${item.model}').join(', ')}.
Bateria activa: ${battery.name}, nivel ${battery.level}%, salud ${battery.health}%, ciclos ${battery.cycles}.
Nivel del piloto: $pilotLevel. Horas totales de vuelo: ${totalFlightHours.toStringAsFixed(1)}.
''';
    final conversation = history
        .where((item) => item.text.trim().isNotEmpty)
        .map((item) => '${item.isUser ? 'user' : 'assistant'}: ${item.text}')
        .join('\n');

    try {
      final response = await _client
          .post(
            Uri.https('api.openai.com', '/v1/responses'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': AppConstants.openAiModel,
              'instructions':
                  'Eres Aura IA, un copiloto inteligente para pilotos de drones. Responde especificamente al mensaje exacto del usuario, sin repetir respuestas anteriores. Usa contexto real de clima, ubicacion, KP, Fly Score, dron activo, bateria y nivel del piloto. Limita la respuesta a 4-6 lineas cortas para movil. Si pregunta "hola", saluda corto. Si pregunta si puede volar hoy, analiza clima y Fly Score. Si pregunta que ND usar, recomienda filtro segun luz/hora. Si pide tomas, crea shotlist. Si pregunta riesgos, explica riesgos. Nunca recomiendes volar si las condiciones son peligrosas o ilegales.',
              'input':
                  '$context\nHistorial reciente:\n$conversation\n\nResponde ahora al usuario: $message',
              'temperature': 0.45,
              'max_output_tokens': 260,
            }),
          )
          .timeout(const Duration(seconds: 18));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OpenAIServiceException(
          'OpenAI ${response.statusCode}: ${response.body}',
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final answer = json['output_text'] as String? ?? _extractOutputText(json);
      return answer?.trim().isNotEmpty == true
          ? answer!.trim()
          : 'No recibi una respuesta util. Revisa tu conexion e intenta de nuevo.';
    } on OpenAIServiceException {
      rethrow;
    } catch (error) {
      throw OpenAIServiceException('No se pudo conectar con OpenAI: $error');
    }
  }

  String? _extractOutputText(Map<String, dynamic> json) {
    final output = json['output'] as List<dynamic>? ?? [];
    final chunks = <String>[];
    for (final item in output) {
      final content =
          (item as Map<String, dynamic>)['content'] as List<dynamic>? ?? [];
      for (final contentItem in content) {
        final contentMap = contentItem as Map<String, dynamic>;
        final text = contentMap['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          chunks.add(text.trim());
        }
      }
    }
    return chunks.isEmpty ? null : chunks.join('\n');
  }
}

class MockOpenAIService implements OpenAIService {
  @override
  Future<String> ask({
    required String message,
    required List<AiChatMessage> history,
    required WeatherSnapshot weather,
    required LocationSnapshot location,
    required KpIndex kp,
    required FlyScore flyScore,
    required Drone drone,
    required List<Drone> drones,
    required DroneBattery battery,
    required String pilotLevel,
    required double totalFlightHours,
  }) async {
    final text = message.toLowerCase();
    final prefix = 'Modo demo IA\n';
    if (text.contains('hola') || text == 'buenas') {
      return '${prefix}Hola, Aldo. Listo para revisar tu vuelo.\nPreguntame clima, riesgos, ND o tomas.';
    }
    if (text.contains('puedo volar') || text.contains('volar hoy')) {
      return '${prefix}Fly Score ${flyScore.value}: ${flyScore.status}.\nViento ${weather.windKmh.round()} km/h, rachas ${weather.gustKmh.round()} km/h.\nKP ${kp.value} y bateria ${battery.level}%.\n${flyScore.recommendation}';
    }
    if (text.contains('nd') || text.contains('filtro')) {
      return '${prefix}Para ${location.city}, empieza con ND16 si hay sol fuerte.\nSi estas cerca de atardecer, prueba ND8.\nMantén ISO 100 y shutter 1/120 en 60fps.\nAjusta si el histograma se va a altas luces.';
    }
    if (text.contains('tomas') ||
        text.contains('shot') ||
        text.contains('shotlist')) {
      return '${prefix}Shotlist rapido:\n- Reveal bajo y lento.\n- Orbit amplio del sujeto.\n- Top down para contexto.\n- Dolly out para cierre.';
    }
    if (text.contains('riesgo') || text.contains('peligro')) {
      final alerts = flyScore.negativeFactors.isEmpty
          ? 'Sin alertas criticas detectadas.'
          : flyScore.negativeFactors.take(3).join('\n- ');
      return '${prefix}Riesgos principales:\n- $alerts\nRevisa zona, personas y regreso con bateria.';
    }
    return '${prefix}Entiendo: "$message".\nCon Fly Score ${flyScore.value}, viento ${weather.windKmh.round()} km/h y bateria ${battery.level}%, mi consejo es volar conservador.\nPuedo afinar clima, ND, riesgos o tomas.';
  }
}
