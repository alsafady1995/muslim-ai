import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'qibla_math.dart';

enum _LocState { loading, serviceOff, denied, deniedForever, ready, error }

/// Qibla compass. The location is read once, on the device, and never sent anywhere:
/// the bearing to the Kaaba is computed locally.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});
  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  _LocState _state = _LocState.loading;
  double? _bearing;
  double? _distanceKm;
  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading;
  bool _noSensor = false;
  bool _aligned = false;

  @override
  void initState() {
    super.initState();
    _locate();
    final events = FlutterCompass.events;
    if (events == null) {
      _noSensor = true;
    } else {
      _compassSub = events.listen((e) {
        if (!mounted) return;
        if (e.heading == null) {
          setState(() => _noSensor = true);
          return;
        }
        setState(() => _heading = e.heading);
        _checkAligned();
      }, onError: (_) {
        if (mounted) setState(() => _noSensor = true);
      });
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  void _checkAligned() {
    if (_bearing == null || _heading == null) return;
    final aligned = turnAngle(_heading!, _bearing!).abs() <= 3;
    if (aligned && !_aligned) HapticFeedback.mediumImpact();
    _aligned = aligned;
  }

  Future<void> _locate() async {
    setState(() => _state = _LocState.loading);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _state = _LocState.serviceOff);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        setState(() => _state = _LocState.denied);
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => _state = _LocState.deniedForever);
        return;
      }
      // City-level accuracy is plenty: 10 km off moves the qibla by far less than a degree.
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 20)),
      );
      if (!mounted) return;
      setState(() {
        _bearing = qiblaBearing(pos!.latitude, pos.longitude);
        _distanceKm = distanceToKaabaKm(pos.latitude, pos.longitude);
        _state = _LocState.ready;
      });
    } catch (_) {
      if (mounted) setState(() => _state = _LocState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qiblaTitle)),
      body: SafeArea(
        child: switch (_state) {
          _LocState.loading => const LoadingView(),
          _LocState.serviceOff => _Problem(
              icon: Icons.location_off,
              text: l10n.qiblaLocationOff,
              action: l10n.openSettings,
              onAction: () async {
                await Geolocator.openLocationSettings();
                _locate();
              }),
          _LocState.denied => _Problem(icon: Icons.location_disabled, text: l10n.qiblaPermission, action: l10n.retry, onAction: _locate),
          _LocState.deniedForever => _Problem(
              icon: Icons.location_disabled,
              text: l10n.qiblaPermission,
              action: l10n.openSettings,
              onAction: () async {
                await Geolocator.openAppSettings();
                _locate();
              }),
          _LocState.error => _Problem(icon: Icons.cloud_off, text: l10n.qiblaLocationError, action: l10n.retry, onAction: _locate),
          _LocState.ready => _compass(context),
        },
      ),
    );
  }

  Widget _compass(BuildContext context) {
    final l10n = context.l10n;
    final bearing = _bearing!;
    final heading = _noSensor ? null : _heading;
    final turn = heading == null ? null : turnAngle(heading, bearing);
    final aligned = turn != null && turn.abs() <= 3;
    final color = aligned ? AppColors.success : Theme.of(context).colorScheme.primary;
    final String guidance;
    if (heading == null) {
      guidance = l10n.qiblaNoSensor(bearing.round());
    } else if (aligned) {
      guidance = l10n.qiblaFacing;
    } else {
      // In RTL "right" is still the user's physical right.
      guidance = turn! > 0 ? l10n.qiblaTurnRight(turn.round()) : l10n.qiblaTurnLeft((-turn).round());
    }
    return ListView(padding: const EdgeInsets.all(24), children: [
      Text(guidance,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: aligned ? AppColors.success : null)),
      const SizedBox(height: 24),
      AspectRatio(
        aspectRatio: 1,
        child: Directionality(
          // The dial is a physical object: never mirror it.
          textDirection: TextDirection.ltr,
          child: Transform.rotate(
            angle: -(heading ?? 0) * math.pi / 180,
            child: CustomPaint(
              painter: _DialPainter(
                bearing: bearing,
                color: color,
                ink: Theme.of(context).colorScheme.onSurface,
                faint: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text(l10n.qiblaBearing(bearing.round()), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
      Text(l10n.qiblaDistance(_distanceKm!.round()), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      if (heading != null)
        Text(l10n.qiblaCalibrate, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(l10n.qiblaPrivacy, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.icon, required this.text, required this.action, required this.onAction});
  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(action)),
          ]),
        ),
      );
}

/// North-up dial with the Kaaba marker at [bearing]. The whole dial is rotated by -heading.
class _DialPainter extends CustomPainter {
  _DialPainter({required this.bearing, required this.color, required this.ink, required this.faint});
  final double bearing;
  final Color color;
  final Color ink;
  final Color faint;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 8;
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = faint);
    for (var d = 0; d < 360; d += 10) {
      final a = d * math.pi / 180;
      final len = d % 90 == 0 ? 18.0 : (d % 30 == 0 ? 12.0 : 6.0);
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(c + dir * r, c + dir * (r - len), Paint()
        ..strokeWidth = d % 90 == 0 ? 3 : 1.5
        ..color = d == 0 ? AppColors.error : ink.withValues(alpha: 0.6));
    }
    // N marker
    final tp = TextPainter(
      text: TextSpan(text: 'N', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: r * 0.12)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c + Offset(-tp.width / 2, -r + 22));

    // Qibla needle
    final a = bearing * math.pi / 180;
    final dir = Offset(math.sin(a), -math.cos(a));
    final normal = Offset(-dir.dy, dir.dx);
    final tip = c + dir * (r - 30);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((c + normal * 14).dx, (c + normal * 14).dy)
      ..lineTo((c - dir * 20).dx, (c - dir * 20).dy)
      ..lineTo((c - normal * 14).dx, (c - normal * 14).dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(c, 6, Paint()..color = ink);

    // Kaaba marker at the tip
    final k = c + dir * (r - 4);
    final rect = Rect.fromCenter(center: k, width: 22, height: 22);
    canvas.save();
    canvas.translate(k.dx, k.dy);
    canvas.rotate(a);
    canvas.translate(-k.dx, -k.dy);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), Paint()..color = const Color(0xFF1B1B1B));
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top + 5, rect.width, 3), Paint()..color = AppColors.gold);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.bearing != bearing || old.color != color || old.ink != ink;
}
