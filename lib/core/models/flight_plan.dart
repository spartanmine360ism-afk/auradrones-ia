class FlightPlan {
  const FlightPlan({
    required this.name,
    required this.location,
    required this.time,
    required this.type,
    required this.drone,
    required this.estimatedMinutes,
    required this.shots,
  });

  final String name;
  final String location;
  final String time;
  final String type;
  final String drone;
  final int estimatedMinutes;
  final List<ShotIdea> shots;
}

class ShotIdea {
  const ShotIdea({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.risk,
    required this.camera,
    required this.tip,
  });

  final String name;
  final String description;
  final String difficulty;
  final String risk;
  final String camera;
  final String tip;
}
