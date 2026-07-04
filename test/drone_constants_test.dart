import 'package:aura_drones_ia/core/constants/drone_constants.dart';
import 'package:aura_drones_ia/core/models/drone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drone type constants are unique', () {
    expect(
      DroneConstants.droneTypes.toSet().length,
      DroneConstants.droneTypes.length,
    );
  });

  test('normalizes legacy multirotor variants', () {
    expect(DroneConstants.normalizeDroneType('multirotor'), 'Multirotor');
    expect(DroneConstants.normalizeDroneType('MULTIROTOR'), 'Multirotor');
    expect(DroneConstants.normalizeDroneType('Multirrotor'), 'Multirotor');
    expect(DroneConstants.normalizeDroneType('multirrotor'), 'Multirotor');
  });

  test('falls back to a valid drone type for unknown values', () {
    expect(DroneConstants.normalizeDroneType('experimental'), 'Multirotor');
    expect(
      DroneConstants.droneTypes.contains(
        DroneConstants.safeDroneTypeSelection('experimental'),
      ),
      isTrue,
    );
  });

  test('normalizes Firestore drone data on read', () {
    final drone = Drone.fromMap('d1', {
      'brand': 'DJI',
      'model': 'Mini',
      'type': 'MULTIROTOR',
      'status': 'listo',
    });

    expect(drone.type, 'Multirotor');
    expect(drone.status, 'Listo');
  });
}
