import '../models/ai_chat_message.dart';
import '../models/battery.dart';
import '../models/drone.dart';
import '../models/fly_score.dart';
import '../models/kp_index.dart';
import '../models/location_snapshot.dart';
import '../models/weather_snapshot.dart';

abstract class AiService {
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
    required String mainGoal,
    required String checklistSummary,
  });
}

class LocalAiService implements AiService {
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
    required String mainGoal,
    required String checklistSummary,
  }) async {
    final text = _normalize(message);

    if (_containsAny(text, ['hola', 'buenas', 'hey'])) {
      return _intro(location, weather, flyScore, drone, battery);
    }

    if (_containsAny(text, ['puedo volar', 'volar hoy', 'conviene volar'])) {
      return _canFly(weather, kp, flyScore, drone, battery, checklistSummary);
    }

    if (_containsAny(text, ['nd', 'filtro', 'shutter', 'exposicion'])) {
      return _ndAdvice(weather, mainGoal);
    }

    if (_containsAny(text, ['tomas', 'shot', 'shotlist', 'plano', 'grab'])) {
      return _shotlist(location, weather, flyScore, drone, battery, mainGoal);
    }

    if (_containsAny(text, ['riesgo', 'peligro', 'alerta', 'seguridad'])) {
      return _risks(weather, kp, flyScore, battery, checklistSummary);
    }

    if (_containsAny(text, ['bateria', 'autonomia'])) {
      return _batteryAdvice(battery, drone, flyScore);
    }

    return _general(
      message: message,
      weather: weather,
      location: location,
      kp: kp,
      flyScore: flyScore,
      drone: drone,
      battery: battery,
      pilotLevel: pilotLevel,
      totalFlightHours: totalFlightHours,
      mainGoal: mainGoal,
    );
  }

  String _intro(
    LocationSnapshot location,
    WeatherSnapshot weather,
    FlyScore flyScore,
    Drone drone,
    DroneBattery battery,
  ) {
    return 'Aura IA Local lista.\n'
        'Estoy leyendo ${location.city}, Fly Score ${flyScore.value}, viento ${weather.windKmh.round()} km/h y bateria ${battery.level}%.\n'
        'Dime si quieres decision de vuelo, riesgos, filtro ND o una shotlist para tu ${drone.brand} ${drone.model}.';
  }

  String _canFly(
    WeatherSnapshot weather,
    KpIndex kp,
    FlyScore flyScore,
    Drone drone,
    DroneBattery battery,
    String checklistSummary,
  ) {
    final decision = _flightDecision(flyScore, weather, kp, battery);
    final alerts = _alerts(weather, kp, flyScore, battery);

    return '$decision\n'
        '- Fly Score: ${flyScore.value} (${flyScore.status}).\n'
        '- Viento: ${weather.windKmh.round()} km/h, rachas ${weather.gustKmh.round()} km/h.\n'
        '- KP: ${kp.value.toStringAsFixed(1)} (${kp.risk}). Lluvia: ${weather.rainChance}%.\n'
        '- Bateria ${battery.name}: ${battery.level}% y salud ${battery.health}%.\n'
        '- Dron activo: ${drone.brand} ${drone.model}. Checklist: $checklistSummary.\n'
        '${alerts.isEmpty ? flyScore.recommendation : 'Atencion: ${alerts.join(' ')}'}';
  }

  String _ndAdvice(WeatherSnapshot weather, String mainGoal) {
    final golden = _goldenHourText(weather);
    final nd = _recommendedNd(weather);
    final shutter = weather.cloudCover > 70
        ? '1/60 en 30fps'
        : '1/120 en 60fps';

    return 'Para $mainGoal usaria $nd como punto de partida.\n'
        '- Luz: nubes ${weather.cloudCover}%, lluvia ${weather.rainChance}%, temperatura ${weather.temperatureC.round()} C.\n'
        '- $golden\n'
        '- Manten ISO 100 y prueba shutter $shutter.\n'
        '- Si el histograma se va a la derecha, sube un paso de ND; si queda oscuro, baja un paso.';
  }

  String _shotlist(
    LocationSnapshot location,
    WeatherSnapshot weather,
    FlyScore flyScore,
    Drone drone,
    DroneBattery battery,
    String mainGoal,
  ) {
    final speed = weather.gustKmh > 28
        ? 'muy lento y cerca'
        : 'suave y constante';
    final batteryNote = battery.level < 45
        ? 'Haz solo 2-3 tomas y guarda regreso.'
        : 'Puedes hacer 4 tomas con margen de regreso.';

    return 'Shotlist local para ${location.city} ($mainGoal):\n'
        '1. Reveal bajo: sube $speed para revelar el lugar. Riesgo: viento/obstaculos.\n'
        '2. Orbit amplio con ${drone.brand} ${drone.model}: radio conservador, sujeto al centro.\n'
        '3. Top down corto: 8-10 segundos para contexto, evita gente y cables.\n'
        '4. Dolly out de cierre durante ${_goldenHourText(weather).toLowerCase()}.\n'
        'Fly Score ${flyScore.value}. Bateria ${battery.level}%. $batteryNote';
  }

  String _risks(
    WeatherSnapshot weather,
    KpIndex kp,
    FlyScore flyScore,
    DroneBattery battery,
    String checklistSummary,
  ) {
    final risks = _alerts(weather, kp, flyScore, battery);
    final list = risks.isEmpty
        ? '- Sin alertas criticas detectadas con los datos actuales.'
        : risks.map((risk) => '- $risk').join('\n');

    return 'Riesgos actuales:\n'
        '$list\n'
        '- Visibilidad: ${weather.visibilityKm.toStringAsFixed(1)} km.\n'
        '- Checklist: $checklistSummary.\n'
        'Recomendacion: ${flyScore.recommendation}';
  }

  String _batteryAdvice(DroneBattery battery, Drone drone, FlyScore flyScore) {
    final reserve = battery.level < 35
        ? 'No despegaria salvo prueba muy corta.'
        : battery.level < 55
        ? 'Vuela cerca y planea regreso temprano.'
        : 'Tienes margen razonable, manteniendo reserva.';

    return 'Bateria activa ${battery.name} en ${battery.level}% para ${drone.brand} ${drone.model}.\n'
        'Salud ${battery.health}%, ciclos ${battery.cycles}, estado ${battery.status}.\n'
        '$reserve Fly Score ${flyScore.value}.';
  }

  String _general({
    required String message,
    required WeatherSnapshot weather,
    required LocationSnapshot location,
    required KpIndex kp,
    required FlyScore flyScore,
    required Drone drone,
    required DroneBattery battery,
    required String pilotLevel,
    required double totalFlightHours,
    required String mainGoal,
  }) {
    return 'Aura IA Local analiza "$message" con tus datos reales:\n'
        '- ${location.city}, ${weather.temperatureC.round()} C, viento ${weather.windKmh.round()} km/h, rachas ${weather.gustKmh.round()} km/h.\n'
        '- KP ${kp.value.toStringAsFixed(1)}, Fly Score ${flyScore.value} (${flyScore.status}).\n'
        '- ${drone.brand} ${drone.model}, bateria ${battery.level}%.\n'
        '- Perfil: $pilotLevel, ${totalFlightHours.toStringAsFixed(1)} h, objetivo $mainGoal.\n'
        'Mi consejo: ${flyScore.recommendation}';
  }

  String _flightDecision(
    FlyScore flyScore,
    WeatherSnapshot weather,
    KpIndex kp,
    DroneBattery battery,
  ) {
    if (flyScore.value < 55 ||
        weather.gustKmh >= 35 ||
        kp.value >= 6 ||
        battery.level < 30 ||
        weather.rainChance >= 70) {
      return 'No lo recomiendo ahora.';
    }

    if (flyScore.value < 75 ||
        weather.gustKmh >= 25 ||
        kp.value >= 4 ||
        battery.level < 50 ||
        weather.rainChance >= 40) {
      return 'Se puede considerar, pero con vuelo corto y conservador.';
    }

    return 'Si la zona es legal y despejada, las condiciones se ven favorables.';
  }

  List<String> _alerts(
    WeatherSnapshot weather,
    KpIndex kp,
    FlyScore flyScore,
    DroneBattery battery,
  ) {
    final alerts = <String>[
      if (weather.gustKmh >= 30)
        'Rachas altas: ${weather.gustKmh.round()} km/h.',
      if (weather.windKmh >= 24)
        'Viento sostenido elevado: ${weather.windKmh.round()} km/h.',
      if (weather.rainChance >= 45)
        'Probabilidad de lluvia ${weather.rainChance}%.',
      if (weather.visibilityKm < 5)
        'Visibilidad baja: ${weather.visibilityKm.toStringAsFixed(1)} km.',
      if (kp.value >= 5) 'KP elevado: ${kp.value.toStringAsFixed(1)}.',
      if (battery.level < 45) 'Bateria baja: ${battery.level}%.',
      ...flyScore.negativeFactors.take(2),
    ];

    return alerts;
  }

  String _recommendedNd(WeatherSnapshot weather) {
    if (weather.cloudCover >= 80 || weather.rainChance >= 50) {
      return 'ND4 o sin ND';
    }
    if (_isGoldenHour(weather)) return 'ND8';
    if (weather.cloudCover >= 45) return 'ND8';
    return 'ND16';
  }

  bool _isGoldenHour(WeatherSnapshot weather) {
    final now = DateTime.now();
    final sunrise = _timeToday(weather.sunrise);
    final sunset = _timeToday(weather.sunset);

    if (sunrise == null || sunset == null) return false;

    final morningEnd = sunrise.add(const Duration(minutes: 60));
    final eveningStart = sunset.subtract(const Duration(minutes: 60));

    return (now.isAfter(sunrise) && now.isBefore(morningEnd)) ||
        (now.isAfter(eveningStart) && now.isBefore(sunset));
  }

  String _goldenHourText(WeatherSnapshot weather) {
    final morningEnd = _addMinutes(weather.sunrise, 60);
    final eveningStart = _addMinutes(weather.sunset, -60);

    return 'Golden hour: manana ${weather.sunrise}-$morningEnd, tarde $eveningStart-${weather.sunset}';
  }

  DateTime? _timeToday(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _addMinutes(String hhmm, int minutes) {
    final base = _timeToday(hhmm);
    if (base == null) return '--:--';

    final next = base.add(Duration(minutes: minutes));
    return '${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}';
  }

  String _normalize(String value) => value.toLowerCase();

  bool _containsAny(String value, List<String> terms) {
    return terms.any(value.contains);
  }
}
