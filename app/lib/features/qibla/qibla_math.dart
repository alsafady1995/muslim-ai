import 'dart:math' as math;

/// The Kaaba, Makkah.
const kaabaLat = 21.422487;
const kaabaLng = 39.826206;

double _rad(double d) => d * math.pi / 180;
double _deg(double r) => r * 180 / math.pi;

/// Initial great-circle bearing from (lat, lng) to the Kaaba, in degrees clockwise from true north [0, 360).
double qiblaBearing(double lat, double lng) {
  final phi1 = _rad(lat);
  final phi2 = _rad(kaabaLat);
  final dLambda = _rad(kaabaLng - lng);
  final y = math.sin(dLambda);
  final x = math.cos(phi1) * math.tan(phi2) - math.sin(phi1) * math.cos(dLambda);
  return (_deg(math.atan2(y, x)) + 360) % 360;
}

/// Great-circle distance to the Kaaba in kilometres (haversine).
double distanceToKaabaKm(double lat, double lng) {
  const r = 6371.0;
  final dPhi = _rad(kaabaLat - lat);
  final dLambda = _rad(kaabaLng - lng);
  final a = math.pow(math.sin(dPhi / 2), 2) +
      math.cos(_rad(lat)) * math.cos(_rad(kaabaLat)) * math.pow(math.sin(dLambda / 2), 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(a)));
}

/// Signed angle in (-180, 180] to turn from [heading] to [target]; positive = turn right.
double turnAngle(double heading, double target) {
  final d = (target - heading + 540) % 360 - 180;
  return d == -180 ? 180 : d;
}
