import 'package:aura_drones_ia/core/models/kp_index.dart';
import 'package:aura_drones_ia/core/services/kp_compare_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ignores a KP source that differs by more than two points', () {
    final now = DateTime.utc(2026);
    final result = KpCompareEngine().compare([
      KpSource(source: 'NOAA', value: 5.7, timestamp: now, available: true),
      KpSource(source: 'GFZ', value: 3, timestamp: now, available: true),
      KpSource(
        source: 'SpaceWeatherLive',
        value: 3,
        timestamp: now,
        available: true,
      ),
    ]);

    expect(result.recommended, 3);
    expect(result.confidence, 'Media');
    expect(result.dataOrigins, ['GFZ', 'SpaceWeatherLive']);
  });

  test('reports high confidence with three agreeing sources', () {
    final now = DateTime.utc(2026);
    final result = KpCompareEngine().compare([
      KpSource(source: 'NOAA', value: 3.1, timestamp: now, available: true),
      KpSource(source: 'GFZ', value: 3.3, timestamp: now, available: true),
      KpSource(
        source: 'Solar Wind',
        value: 3.2,
        timestamp: now,
        available: true,
      ),
    ]);

    expect(result.confidence, 'Alta');
    expect(result.minimum, 3.1);
    expect(result.maximum, 3.3);
    expect(result.average, closeTo(3.2, .001));
  });
}
