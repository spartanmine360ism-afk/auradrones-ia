import '../models/fly_score.dart';
import '../models/kp_index.dart';
import '../models/location_snapshot.dart';
import '../models/weather_snapshot.dart';

class FlyScoreService {
  FlyScore calculate({
    required WeatherSnapshot weather,
    required KpIndex kp,
    required LocationSnapshot location,
    required int batteryLevel,
    required bool isRestrictedZone,
    required String pilotLevel,
    required String droneType,
  }) {
    var score = 100;
    final positives = <String>[];
    final negatives = <String>[];
    final isLightDrone = droneType.toLowerCase().contains('ligero');

    if (weather.windKmh <= 12) {
      positives.add('Viento bajo');
    } else if (weather.windKmh <= 20) {
      score -= isLightDrone ? 14 : 8;
      negatives.add('Viento medio: exige mas margen en drones ligeros');
    } else {
      score -= isLightDrone ? 28 : 20;
      negatives.add('Viento fuerte para vuelo recreativo o tomas suaves');
    }

    if (weather.gustKmh <= 20) {
      positives.add('Rachas controlables');
    } else if (weather.gustKmh <= 30) {
      score -= 14;
      negatives.add('Rachas moderadas, evita altura excesiva');
    } else {
      score -= 30;
      negatives.add('Rachas fuertes, alto riesgo de deriva');
    }

    if (weather.rainChance <= 15) {
      positives.add('Sin lluvia detectada');
    } else if (weather.rainChance <= 35) {
      score -= 10;
      negatives.add('Posible lluvia, monitorea cambios por hora');
    } else {
      score -= 28;
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
      score -= 22;
      negatives.add('Visibilidad baja, dificil mantener control visual');
    }

    if (kp.value <= 3) {
      positives.add('KP estable');
    } else if (kp.value < 5) {
      score -= 10;
      negatives.add('KP con precaucion: verifica satelites antes de despegar');
    } else if (kp.value < 6) {
      score -= 22;
      negatives.add('KP alto: posible degradacion de GPS');
    } else {
      score -= 35;
      negatives.add('KP muy alto: evita vuelos largos o autonomos');
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

    if (location.accuracyMeters > 100) {
      score -= 6;
      negatives.add(
        'Precision de ubicacion baja; confirma mapa y zona manualmente',
      );
    } else {
      positives.add('Ubicacion precisa');
    }

    if (isRestrictedZone) {
      score = score > 25 ? 25 : score;
      negatives.add('Zona marcada como restringida o sensible');
    }

    final bounded = score.clamp(0, 100);
    final status = switch (bounded) {
      >= 80 => 'Excelente para volar',
      >= 60 => 'Vuela con precaucion',
      >= 40 => 'Riesgo moderado',
      _ => 'No recomendado',
    };
    final recommendation = _recommendation(
      bounded,
      negatives,
      isRestrictedZone,
    );

    return FlyScore(
      value: bounded,
      status: status,
      explanation: '${location.city}: $status.',
      positiveFactors: positives,
      negativeFactors: negatives,
      recommendation: recommendation,
    );
  }

  String _recommendation(int score, List<String> negatives, bool restricted) {
    if (restricted) {
      return 'No despegues hasta confirmar permisos y normativa local vigente.';
    }
    if (score >= 80) {
      return 'Buen momento para volar. Mantente dentro de linea visual y reserva bateria para regreso.';
    }
    if (score >= 60) {
      return 'Puedes volar con precaucion: manten el dron cerca, evita altura excesiva y revisa rachas antes de despegar.';
    }
    if (score >= 40) {
      return 'Solo vuela si es necesario, en zona abierta y con plan de emergencia. Mejor esperar mejores condiciones para contenido cinematico.';
    }
    return 'No recomendado. ${negatives.isEmpty ? 'Las condiciones no dan margen suficiente.' : negatives.first}';
  }
}
