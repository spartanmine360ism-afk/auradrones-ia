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
        _apiKey = apiKey ?? AppConstants.geminiApiKey;

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

    final context = '''
Eres Aura IA, un copiloto inteligente para pilotos de drones.

Responde en español, claro y breve.
No repitas respuestas anteriores.
No inventes datos.
Nunca recomiendes volar si las condiciones son peligrosas o ilegales.
Limita la respuesta a 4-6 líneas cortas para móvil.

Mensaje exacto del usuario: $message

Datos reales:
- Ubicación: ${location.city} (${location.coordinates}), precisión ${location.accuracyMeters.round()} m.
- Clima: ${weather.temperatureC.round()} C, viento ${weather.windKmh.round()} km/h, rachas ${weather.gustKmh.round()} km/h, lluvia ${weather.rainChance}%, visibilidad ${weather.visibilityKm} km, nubes ${weather.cloudCover}%.
- KP: ${kp.value} (${kp.risk}).
- Fly Score: ${flyScore.value}, estado ${flyScore.status}. Recomendación: ${flyScore.recommendation}.
- Dron activo: ${drone.brand} ${drone.model}, tipo ${drone.type}, ${drone.weightGrams} g.
- Drones del usuario: ${drones.map((item) => '${item.brand} ${item.model}').join(', ')}.
- Batería activa: ${battery.name}, nivel ${battery.level}%, salud ${battery.health}%, ciclos ${battery.cycles}.
- Nivel del piloto: $pilotLevel.
- Horas totales de vuelo: ${totalFlightHours.toStringAsFixed(1)}.

Reglas:
- Si pregunta "hola", saluda corto.
- Si pregunta si puede volar hoy, analiza clima, KP, Fly Score y batería.
- Si pregunta qué ND usar, recomienda filtro según luz/hora.
- Si pide tomas o shotlist, crea una lista de tomas.
- Si pregunta riesgos, explica riesgos principales.
''';

    final conversation = history
        .where((item) => item.text.trim().isNotEmpty)
        .take(8)
        .map((item) => '${item.isUser ? 'Usuario' : 'Aura IA'}: ${item.text}')
        .join('\n');

    final prompt =
        '$context\nHistorial reciente:\n$conversation\n\nResponde ahora al usuario: $message';

    try {
      final response = await _client
          .post(
            Uri.https(
              'generativelanguage.googleapis.com',
              '/v1beta/models/${AppConstants.geminiModel}:generateContent',
              {'key': _apiKey},
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'maxOutputTokens': 260,
                'temperature': 0.7,
                'topP': 0.9,
              },
            }),
          )
          .timeout(const Duration(seconds: 18));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OpenAIServiceException(
          'Aura IA no pudo responder ahora (Gemini ${response.statusCode}). Modo local activado.',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final answer = _extractGeminiText(json);

      return answer?.trim().isNotEmpty == true
          ? answer!.trim()
          : 'No recibí una respuesta útil. Intenta de nuevo.';
    } on OpenAIServiceException {
      rethrow;
    } catch (_) {
      throw const OpenAIServiceException(
        'Aura IA no pudo conectarse. Modo local activado.',
      );
    }
  }

  String? _extractGeminiText(Map<String, dynamic> json) {
    final candidates = json['candidates'] as List<dynamic>? ?? [];
    final chunks = <String>[];

    for (final candidate in candidates) {
      final content = (candidate as Map<String, dynamic>)['content']
          as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>? ?? [];

      for (final part in parts) {
        final text = (part as Map<String, dynamic>)['text'] as String?;
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
    const prefix = 'Modo demo IA\n';

    if (text.contains('hola') || text == 'buenas') {
      return '${prefix}Hola, piloto. Listo para revisar tu vuelo.\nPregúntame clima, riesgos, ND o tomas.';
    }

    if (text.contains('puedo volar') || text.contains('volar hoy')) {
      return '${prefix}Fly Score ${flyScore.value}: ${flyScore.status}.\nViento ${weather.windKmh.round()} km/h, rachas ${weather.gustKmh.round()} km/h.\nKP ${kp.value} y batería ${battery.level}%.\n${flyScore.recommendation}';
    }

    if (text.contains('nd') || text.contains('filtro')) {
      return '${prefix}Para ${location.city}, empieza con ND16 si hay sol fuerte.\nSi estás cerca de atardecer, prueba ND8.\nMantén ISO 100 y shutter 1/120 en 60fps.';
    }

    if (text.contains('tomas') ||
        text.contains('shot') ||
        text.contains('shotlist')) {
      return '${prefix}Shotlist rápido:\n- Reveal bajo y lento.\n- Orbit amplio del sujeto.\n- Top down para contexto.\n- Dolly out para cierre.';
    }

    if (text.contains('riesgo') || text.contains('peligro')) {
      final alerts = flyScore.negativeFactors.isEmpty
          ? 'Sin alertas críticas detectadas.'
          : flyScore.negativeFactors.take(3).join('\n- ');

      return '${prefix}Riesgos principales:\n- $alerts\nRevisa zona, personas y regreso con batería.';
    }

    return '${prefix}Entiendo: "$message".\nCon Fly Score ${flyScore.value}, viento ${weather.windKmh.round()} km/h y batería ${battery.level}%, mi consejo es volar conservador.\nPuedo afinar clima, ND, riesgos o tomas.';
  }
}