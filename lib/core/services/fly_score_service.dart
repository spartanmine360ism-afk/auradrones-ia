import '../models/fly_score.dart';
import '../models/kp_index.dart';
import '../models/location_snapshot.dart';
import '../models/weather_snapshot.dart';
import 'risk_engine.dart';

class FlyScoreService {
  FlyScoreService({RiskEngine? riskEngine})
    : _riskEngine = riskEngine ?? RiskEngine();

  final RiskEngine _riskEngine;

  FlyScore calculate({
    required WeatherSnapshot weather,
    required KpIndex kp,
    required LocationSnapshot location,
    required int batteryLevel,
    required bool isRestrictedZone,
    required String pilotLevel,
    required String droneType,
    required int droneWeightGrams,
  }) {
    return _riskEngine.calculate(
      weather: weather,
      kp: kp,
      location: location,
      batteryLevel: batteryLevel,
      isRestrictedZone: isRestrictedZone,
      pilotLevel: pilotLevel,
      droneType: droneType,
      droneWeightGrams: droneWeightGrams,
    );
  }
}
