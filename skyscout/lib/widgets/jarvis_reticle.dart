import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Holographic Jarvis-style targeting reticle, compass ring,
/// pitch ladder, and radar sweep.
class JarvisReticle extends StatefulWidget {
  final double heading;
  final double pitch;
  final bool isScanning;
  final Color themeColor;

  const JarvisReticle({
    super.key,
    required this.heading,
    required this.pitch,
    this.isScanning = false,
    this.themeColor = const Color(0xFF00F2FE),
  });

  @override
  State<JarvisReticle> createState() => _JarvisReticleState();
}

class _JarvisReticleState extends State<JarvisReticle>
    with TickerProviderStateMixin {
  late AnimationController _radarSweepController;
  late AnimationController _pulseController;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();

    _radarSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _radarSweepController.dispose();
    _pulseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _radarSweepController,
        _pulseController,
        _spinController,
      ]),
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _JarvisReticlePainter(
            heading: widget.heading,
            pitch: widget.pitch,
            isScanning: widget.isScanning,
            radarAngle: _radarSweepController.value * 2 * math.pi,
            pulse: _pulseController.value,
            spinAngle: _spinController.value * 2 * math.pi,
            themeColor: widget.themeColor,
          ),
        );
      },
    );
  }
}

class _JarvisReticlePainter extends CustomPainter {
  final double heading;
  final double pitch;
  final bool isScanning;
  final double radarAngle;
  final double pulse;
  final double spinAngle;
  final Color themeColor;

  _JarvisReticlePainter({
    required this.heading,
    required this.pitch,
    required this.isScanning,
    required this.radarAngle,
    required this.pulse,
    required this.spinAngle,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 0.46);
    final double baseRadius = math.min(size.width, size.height) * 0.32;

    // 1. Radar Sweep Arc (when active)
    final Paint radarPaint = Paint()
      ..shader = SweepGradient(
        center: FractionalOffset(center.dx / size.width, center.dy / size.height),
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          Colors.transparent,
          themeColor.withValues(alpha: isScanning ? 0.35 : 0.12),
        ],
        transform: GradientRotation(radarAngle),
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius));
    canvas.drawCircle(center, baseRadius, radarPaint);

    // 2. Rotating Outer Cyber HUD Ring with Degree Ticks
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * math.pi / 180); // Locks compass North!

    final Paint ringPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, baseRadius, ringPaint);

    // Cardinal Points & Ticks
    final Paint tickPaint = Paint()..strokeWidth = 1.2;
    for (int deg = 0; deg < 360; deg += 10) {
      final double rad = deg * math.pi / 180;
      final bool isCardinal = deg % 90 == 0;
      final bool isMajor = deg % 30 == 0;
      final double len = isCardinal ? 12.0 : (isMajor ? 8.0 : 4.0);

      tickPaint.color = isCardinal
          ? (deg == 0 ? const Color(0xFFFF5252) : themeColor)
          : themeColor.withValues(alpha: isMajor ? 0.6 : 0.25);

      final double startR = baseRadius - len;
      final double endR = baseRadius;
      canvas.drawLine(
        Offset(math.cos(rad) * startR, math.sin(rad) * startR),
        Offset(math.cos(rad) * endR, math.sin(rad) * endR),
        tickPaint,
      );
    }
    canvas.restore();

    // 3. Counter-Rotating Inner Tech Segments
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(spinAngle);

    final Paint segmentPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final double segRadius = baseRadius * 0.72;
    // Draw 4 curved techno-brackets
    for (int i = 0; i < 4; i++) {
      final double startA = (i * math.pi / 2) + 0.15;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: segRadius),
        startA,
        math.pi / 3.2,
        false,
        segmentPaint,
      );
    }
    canvas.restore();

    // 4. Center Holographic Crosshairs & Reticle Box
    final double crossRadius = baseRadius * 0.35;
    final Paint crossPaint = Paint()
      ..color = (isScanning ? const Color(0xFFFF0055) : themeColor)
          .withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Corner brackets [ + ]
    final double boxSize = 24.0 + (isScanning ? pulse * 8.0 : 0.0);
    final double cornerLen = 7.0;
    final Paint cornerPaint = Paint()
      ..color = (isScanning ? Colors.white : themeColor)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Top-Left
    canvas.drawLine(Offset(center.dx - boxSize, center.dy - boxSize + cornerLen), Offset(center.dx - boxSize, center.dy - boxSize), cornerPaint);
    canvas.drawLine(Offset(center.dx - boxSize, center.dy - boxSize), Offset(center.dx - boxSize + cornerLen, center.dy - boxSize), cornerPaint);
    // Top-Right
    canvas.drawLine(Offset(center.dx + boxSize - cornerLen, center.dy - boxSize), Offset(center.dx + boxSize, center.dy - boxSize), cornerPaint);
    canvas.drawLine(Offset(center.dx + boxSize, center.dy - boxSize), Offset(center.dx + boxSize, center.dy - boxSize + cornerLen), cornerPaint);
    // Bottom-Left
    canvas.drawLine(Offset(center.dx - boxSize, center.dy + boxSize - cornerLen), Offset(center.dx - boxSize, center.dy + boxSize), cornerPaint);
    canvas.drawLine(Offset(center.dx - boxSize, center.dy + boxSize), Offset(center.dx - boxSize + cornerLen, center.dy + boxSize), cornerPaint);
    // Bottom-Right
    canvas.drawLine(Offset(center.dx + boxSize - cornerLen, center.dy + boxSize), Offset(center.dx + boxSize, center.dy + boxSize), cornerPaint);
    canvas.drawLine(Offset(center.dx + boxSize, center.dy + boxSize), Offset(center.dx + boxSize, center.dy + boxSize - cornerLen), cornerPaint);

    // Cross hair lines
    canvas.drawLine(Offset(center.dx - crossRadius, center.dy), Offset(center.dx - boxSize - 4, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx + boxSize + 4, center.dy), Offset(center.dx + crossRadius, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - crossRadius), Offset(center.dx, center.dy - boxSize - 4), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy + boxSize + 4), Offset(center.dx, center.dy + crossRadius), crossPaint);

    // Center pulse dot
    final Paint centerDotPaint = Paint()
      ..color = (isScanning ? const Color(0xFFFF2A6D) : Colors.white)
          .withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.0 + pulse * 2.0, centerDotPaint);

    // 5. Vertical Pitch Ladder (Artificial Horizon Indicator)
    _drawPitchLadder(canvas, center, baseRadius);
  }

  void _drawPitchLadder(Canvas canvas, Offset center, double baseRadius) {
    final double ladderX = center.dx - baseRadius - 20.0;
    final double pitchOffset = pitch.clamp(-90.0, 90.0) * 1.8;

    final Paint ladderPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    for (int deg = -60; deg <= 60; deg += 15) {
      final double y = center.dy - (deg * 1.8) + pitchOffset;
      if (y > center.dy - baseRadius && y < center.dy + baseRadius) {
        final double markLen = (deg == 0) ? 22.0 : 12.0;
        final bool isZero = deg == 0;
        ladderPaint.color = (isZero ? const Color(0xFFFFD700) : themeColor)
            .withValues(alpha: isZero ? 0.8 : 0.4);
        ladderPaint.strokeWidth = isZero ? 1.8 : 1.0;

        canvas.drawLine(
          Offset(ladderX - markLen, y),
          Offset(ladderX, y),
          ladderPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _JarvisReticlePainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.pitch != pitch ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.radarAngle != radarAngle ||
        oldDelegate.pulse != pulse ||
        oldDelegate.spinAngle != spinAngle ||
        oldDelegate.themeColor != themeColor;
  }
}
