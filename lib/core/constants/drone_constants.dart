class DroneConstants {
  const DroneConstants._();

  static const defaultDroneType = 'Multirotor';
  static const defaultDroneStatus = 'Listo';

  static const droneTypes = [
    'Multirotor',
    'FPV',
    'Ala fija',
    'Cinewhoop',
    'Helicóptero',
    'Otro',
  ];

  static const droneStatuses = ['Listo', 'Revisar', 'Mantenimiento'];

  static String normalizeDroneType(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return defaultDroneType;

    final normalized = _fold(raw);
    final aliases = {
      'multirotor': 'Multirotor',
      'multirrotor': 'Multirotor',
      'multi rotor': 'Multirotor',
      'multi-rotor': 'Multirotor',
      'ligero': 'Multirotor',
      'mediano': 'Multirotor',
      'quad': 'Multirotor',
      'quadcopter': 'Multirotor',
      'fpv': 'FPV',
      'ala fija': 'Ala fija',
      'ala-fija': 'Ala fija',
      'fixed wing': 'Ala fija',
      'fixed-wing': 'Ala fija',
      'cinewhoop': 'Cinewhoop',
      'helicoptero': 'Helicóptero',
      'helicopter': 'Helicóptero',
      'heli': 'Helicóptero',
      'otro': 'Otro',
      'other': 'Otro',
    };

    return aliases[normalized] ??
        droneTypes.firstWhere(
          (item) => _fold(item) == normalized,
          orElse: () => defaultDroneType,
        );
  }

  static String normalizeDroneStatus(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return defaultDroneStatus;

    final normalized = _fold(raw);
    return droneStatuses.firstWhere(
      (item) => _fold(item) == normalized,
      orElse: () => defaultDroneStatus,
    );
  }

  static List<String> unique(List<String> values) {
    return {...values}.toList(growable: false);
  }

  static String safeDroneTypeSelection(String? value) {
    return safeSelection(normalizeDroneType(value), droneTypes);
  }

  static String safeDroneStatusSelection(String? value) {
    return safeSelection(normalizeDroneStatus(value), droneStatuses);
  }

  static String safeSelection(String? value, List<String> items) {
    final uniqueItems = unique(items);
    if (uniqueItems.isEmpty) return '';

    final normalized = value?.trim();
    return normalized != null && uniqueItems.contains(normalized)
        ? normalized
        : uniqueItems.first;
  }

  static String _fold(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }
}
