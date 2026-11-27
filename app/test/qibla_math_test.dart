import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_ai/features/qibla/qibla_math.dart';

void main() {
  test('qibla bearing matches published values', () {
    // Reference bearings (true north) from standard qibla tables, ±1°.
    expect(qiblaBearing(51.5074, -0.1278), closeTo(118.99, 1)); // London
    expect(qiblaBearing(40.7128, -74.0060), closeTo(58.48, 1)); // New York
    expect(qiblaBearing(-6.2088, 106.8456), closeTo(295.15, 1)); // Jakarta
    expect(qiblaBearing(24.7136, 46.6753), closeTo(244.0, 1)); // Riyadh
  });

  test('distance to the Kaaba', () {
    expect(distanceToKaabaKm(kaabaLat, kaabaLng), closeTo(0, 0.01));
    expect(distanceToKaabaKm(51.5074, -0.1278), closeTo(4790, 30));
  });

  test('turn angle wraps around north', () {
    expect(turnAngle(350, 10), 20);
    expect(turnAngle(10, 350), -20);
    expect(turnAngle(0, 180), 180);
    expect(turnAngle(90, 90), 0);
  });
}
