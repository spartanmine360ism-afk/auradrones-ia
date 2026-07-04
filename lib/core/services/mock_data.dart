import '../models/battery.dart';
import '../models/drone.dart';
import '../models/flight_plan.dart';
import '../models/kp_index.dart';
import '../models/lesson.dart';
import '../models/weather_snapshot.dart';

class MockData {
  const MockData._();

  static const weather = WeatherSnapshot(
    city: 'Ciudad de Mexico',
    coordinates: '19.4326, -99.1332',
    temperatureC: 22,
    feelsLikeC: 23,
    windKmh: 12,
    gustKmh: 21,
    windDirection: 'NE',
    humidity: 46,
    visibilityKm: 13,
    cloudCover: 28,
    rainChance: 12,
    sunrise: '06:03',
    sunset: '19:18',
    hourly: [
      HourlyForecast('17:00', 22, 12, 12),
      HourlyForecast('18:00', 21, 10, 8),
      HourlyForecast('19:00', 20, 9, 6),
      HourlyForecast('20:00', 19, 8, 5),
    ],
  );

  static const kp = KpIndex(
    value: 2.3,
    risk: 'GPS estable',
    recommendation: 'Condiciones buenas para vuelos visuales y tomas largas.',
  );

  static final drones = [
    Drone(
      id: 'mini4',
      brand: 'DJI',
      model: 'Mini 4 Pro',
      serialNumber: 'AURA-M4P-2026',
      weightGrams: 249,
      type: 'Ligero',
      flightHours: 18.5,
      flightsCount: 27,
      status: 'Listo',
      nextMaintenance: 'Revisar helices en 6 vuelos',
      purchaseDate: null,
      notes: '',
      photoUrl: null,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
    Drone(
      id: 'air3',
      brand: 'DJI',
      model: 'Air 3',
      serialNumber: 'AURA-A3-9012',
      weightGrams: 720,
      type: 'Mediano',
      flightHours: 42,
      flightsCount: 51,
      status: 'Optimo',
      nextMaintenance: 'Limpieza de sensores pendiente',
      purchaseDate: null,
      notes: '',
      photoUrl: null,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];

  static final batteries = [
    DroneBattery(
      id: 'b1',
      name: 'Bateria 1',
      compatibleModel: 'Mini 4 Pro',
      droneId: 'mini4',
      cycles: 34,
      health: 96,
      lastCharge: 'Hoy',
      lastUse: 'Ayer',
      level: 92,
      status: 'Buena',
      notes: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
    DroneBattery(
      id: 'b2',
      name: 'Bateria 2',
      compatibleModel: 'Mini 4 Pro',
      droneId: 'mini4',
      cycles: 112,
      health: 78,
      lastCharge: 'Hace 8 dias',
      lastUse: 'Hace 21 dias',
      level: 28,
      status: 'Revisar',
      notes: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];

  static const plan = FlightPlan(
    name: 'Plan local de vuelo',
    location: 'Ubicacion actual',
    time: 'Hora local',
    type: 'Objetivo del usuario',
    drone: 'Dron activo',
    estimatedMinutes: 24,
    shots: [
      ShotIdea(
        name: 'Reveal',
        description: 'Sube detras de un primer plano y revela la avenida.',
        difficulty: 'Media',
        risk: 'Bajo',
        camera: '4K 60fps, ISO 100, ND16, D-Log M',
        tip: 'Mantiene velocidad baja y corrige horizonte antes de grabar.',
      ),
      ShotIdea(
        name: 'Orbit',
        description: 'Orbita lenta alrededor del sujeto principal.',
        difficulty: 'Media',
        risk: 'Medio',
        camera: '4K 30fps, shutter 1/60, WB fijo',
        tip: 'Ensaya radio amplio y revisa personas alrededor.',
      ),
      ShotIdea(
        name: 'Top Down',
        description: 'Plano cenital para patrones urbanos.',
        difficulty: 'Baja',
        risk: 'Bajo',
        camera: '4K 30fps, ISO 100, perfil normal',
        tip: 'Evita sombras de edificios y mantente dentro de linea visual.',
      ),
    ],
  );

  static const lessons = [
    Lesson(
      title: 'Que revisar antes de despegar',
      category: 'Seguridad',
      level: 'Principiante',
      minutes: 8,
      description: 'Checklist critica para despegar con control y criterio.',
    ),
    Lesson(
      title: 'Como entender el viento',
      category: 'Clima para drones',
      level: 'Principiante',
      minutes: 10,
      description: 'Diferencia entre viento sostenido, rachas y turbulencia.',
    ),
    Lesson(
      title: 'Como hacer una toma Orbit',
      category: 'Movimientos cinematograficos',
      level: 'Intermedio',
      minutes: 12,
      description: 'Movimiento circular suave con encuadre consistente.',
    ),
    Lesson(
      title: 'Como usar filtros ND',
      category: 'Configuracion de camara',
      level: 'Intermedio',
      minutes: 9,
      description: 'Control de shutter, exposicion y motion blur natural.',
    ),
    Lesson(
      title: 'Composicion para revelar ubicaciones',
      category: 'Composicion',
      level: 'Principiante',
      minutes: 7,
      description: 'Encuadres simples para mostrar sujeto, escala y contexto.',
    ),
    Lesson(
      title: 'Edicion rapida para redes',
      category: 'Edicion',
      level: 'Intermedio',
      minutes: 11,
      description: 'Seleccion, ritmo y color para publicar sin perder calidad.',
    ),
    Lesson(
      title: 'Normativa basica antes de volar',
      category: 'Normativa',
      level: 'Principiante',
      minutes: 8,
      description: 'Permisos, zonas sensibles y responsabilidad del piloto.',
    ),
    Lesson(
      title: 'Mantenimiento preventivo',
      category: 'Mantenimiento',
      level: 'Principiante',
      minutes: 9,
      description: 'Revision de helices, baterias, sensores y limpieza.',
    ),
  ];
}
