import '../models/fly_score.dart';
import '../models/kp_index.dart';
import '../models/location_snapshot.dart';
import '../models/weather_snapshot.dart';

/// Production flight risk engine. It combines space weather, local weather,
/// aircraft profile, location quality, battery and pilot experience.
class RiskEngine {
  FlyScore calculate({
    required WeatherSnapshot weather,
    required KpIndex kp,
    required LocationSnapshot location,
    required int batteryLevel,
    required bool isRestrictedZone,
    required String pilotLevel,
    required String droneType,
    required int droneWeightGrams,
    int satelliteCount = 0,
    int flightAltitudeMeters = 120,
  }) {
    var score = 100;
    final positives = <String>[];
    final negatives = <String>[];
    final isLightDrone = droneWeightGrams > 0
        ? droneWeightGrams < 300
        : droneType.toLowerCase().contains('ligero');

    if (weather.windKmh <= 12) {
      positives.add('Viento bajo');
    } else if (weather.windKmh <= 20) {
      score -= isLightDrone ? 14 : 8;
      negatives.add('Viento medio: exige mas margen en drones ligeros');
    } else {
      score -= isLightDrone ? 30 : 22;
      negatives.add('Viento fuerte para vuelo recreativo o tomas suaves');
    }

    if (weather.gustKmh <= 20) {
      positives.add('Rachas controlables');
    } else if (weather.gustKmh <= 30) {
      score -= 14;
      negatives.add('Rachas moderadas, evita altura excesiva');
    } else {
      score -= 32;
      negatives.add('Rachas fuertes, alto riesgo de deriva');
    }

    if (weather.rainChance <= 15) {
      positives.add('Sin lluvia detectada');
    } else if (weather.rainChance <= 35) {
      score -= 10;
      negatives.add('Posible lluvia, monitorea cambios por hora');
    } else {
      score -= 30;
      negatives.add(
        'Lluvia probable, no recomendado para drones no protegidos',
      );
    }

    if (weather.visibilityKm >= 8) {
      positives.add('Buena visibilidad');
    } else if (weather.visibilityKm >= 5) {
      score -= 8;
      negatives.add('Visibilidad limitada para tomas lejanas');
    } else {
      score -= 24;
      negatives.add('Visibilidad baja, dificil mantener control visual');
    }

    if (weather.cloudCover >= 85 && weather.visibilityKm < 8) {
      score -= 6;
      negatives.add('Nubosidad alta con visibilidad limitada');
    }

    if (kp.recommended <= 3) {
      positives.add('KP Aura estable');
    } else if (kp.recommended < 5) {
      score -= 10;
      negatives.add('KP Aura con precaucion: verifica satelites');
    } else if (kp.recommended < 6) {
      score -= 22;
      negatives.add('KP Aura alto: posible degradacion de GPS');
    } else {
      score -= 38;
      negatives.add('KP Aura muy alto: evita vuelos largos o autonomos');
    }

    if (kp.confidence == 'Baja') {
      score -= 6;
      negatives.add('Confianza KP baja: valida condiciones manualmente');
    }

    if (satelliteCount > 0 && satelliteCount < 10) {
      score -= 14;
      negatives.add('Pocos satelites disponibles');
    }

    if (batteryLevel >= 70) {
      positives.add('Bateria suficiente');
    } else if (batteryLevel >= 30) {
      score -= 12;
      negatives.add('Bateria media: planea regreso temprano');
    } else {
      score -= 38;
      negatives.add('Bateria por debajo de 30%, no iniciar vuelo');
    }

    if (pilotLevel.toLowerCase().contains('principiante') &&
        weather.windKmh > 12) {
      score -= 8;
      negatives.add(
        'Piloto principiante con viento medio requiere zona amplia',
      );
    }

    if (flightAltitudeMeters > 120) {
      score -= 10;
      negatives.add('Altura propuesta mayor a 120 m; revisa normativa local');
    }

    if (location.accuracyMeters > 100) {
      score -= 6;
      negatives.add('Precision de ubicacion baja; confirma mapa manualmente');
    } else {
      positives.add('Ubicacion precisa');
    }

    if (isRestrictedZone) {
      score = score > 25 ? 25 : score;
      negatives.add('Zona marcada como restringida o sensible');
    }

    final bounded = score.clamp(0, 100);
    final status = switch (bounded) {
      >= 85 => 'Excelente',
      >= 70 => 'Bueno',
      >= 50 => 'Precaucion',
      _ => 'No recomendable',
    };

    return FlyScore(
      value: bounded,
      status: status,
      explanation: '${location.city}: $status para volar.',
      positiveFactors: positives,
      negativeFactors: negatives,
      recommendation: _recommendation(bounded, negatives, isRestrictedZone),
    );
  }

  String _recommendation(int score, List<String> negatives, bool restricted) {
    if (restricted) {
      return 'No despegues hasta confirmar permisos y normativa local vigente.';
    }
    if (score >= 85) {
      return 'Buen momento para volar. Mantente dentro de linea visual y reserva bateria para regreso.';
    }
    if (score >= 70) {
      return 'Condiciones buenas con margen. Revisa rachas y conserva bateria de regreso.';
    }
    if (score >= 50) {
      return 'Vuela con precaucion: manten el dron cerca, evita altura excesiva y prepara regreso manual.';
    }
    return 'No recomendable. ${negatives.isEmpty ? 'Las condiciones no dan margen suficiente.' : negatives.first}';
  }
}
