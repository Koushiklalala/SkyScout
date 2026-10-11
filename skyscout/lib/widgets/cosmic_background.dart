import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated cosmic background featuring deep space nebulae,
/// rotating spiral galaxies, glowing solar flares, twinkling starfield,
/// and constellation nodal filaments.
class CosmicBackground extends StatefulWidget {
  final Widget? child;
  final double parallaxHeading;
  final double parallaxPitch;
  final Color themeColor;

  const CosmicBackground({
    super.key,
    this.child,
    this.parallaxHeading = 0.0,
    this.parallaxPitch = 0.0,
    this.themeColor = const Color(0xFF00F2FE),
  });

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _twinkleController;
  late AnimationController _meteorController;

  final List<StarData> _stars = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();

    // Slow rotation of galaxies and cosmic dust (90s full revolution)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    )..repeat();

    // Fast twinkle pulsation (3.5s cycle)
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    // Periodic shooting star trigger (7s cycle)
    _meteorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();

    // Generate 150 unique stars
    for (int i = 0; i < 150; i++) {
      _stars.add(StarData(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: _random.nextDouble() * 2.2 + 0.6,
        alphaOffset: _random.nextDouble() * 2 * math.pi,
        colorType: _random.nextInt(4),
      ));
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _twinkleController.dispose();
    _meteorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _rotationController,
        _twinkleController,
        _meteorController,
      ]),
      builder: (context, _) {
        return CustomPaint(
          painter: _CosmicPainter(
            rotation: _rotationController.value * 2 * math.pi,
            twinkle: _twinkleController.value,
            meteorProgress: _meteorController.value,
            heading: widget.parallaxHeading,
            pitch: widget.parallaxPitch,
            stars: _stars,
            themeColor: widget.themeColor,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class StarData {
  final double x;
  final double y;
  final double radius;
  final double alphaOffset;
  final int colorType;

  StarData({
    required this.x,
    required this.y,
    required this.radius,
    required this.alphaOffset,
    required this.colorType,
  });
}

class _CosmicPainter extends CustomPainter {
  final double rotation;
  final double twinkle;
  final double meteorProgress;
  final double heading;
  final double pitch;
  final List<StarData> stars;
  final Color themeColor;

  _CosmicPainter({
    required this.rotation,
    required this.twinkle,
    required this.meteorProgress,
    required this.heading,
    required this.pitch,
    required this.stars,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Deep Space Void Gradient
    final Rect rect = Offset.zero & size;
    final Paint spacePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.2),
        radius: 1.4,
        colors: [
          Color(0xFF0C1024),
          Color(0xFF050711),
          Color(0xFF020307),
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, spacePaint);

    // Parallax translation based on compass & pitch
    final double px = (heading % 360) * 0.4;
    final double py = pitch.clamp(-90.0, 90.0) * 1.5;

    // 2. Violet & Cyan Nebula Dust Clouds
    final Paint nebulaPaint1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.4, -0.4),
        radius: 0.8,
        colors: [
          const Color(0xFF6B21A8).withValues(alpha: 0.18),
          const Color(0xFF3B0764).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, nebulaPaint1);

    final Paint nebulaPaint2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, 0.3),
        radius: 0.7,
        colors: [
          themeColor.withValues(alpha: 0.14),
          const Color(0xFF0369A1).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, nebulaPaint2);

    // 3. Rotating Spiral Galaxy Core
    final Offset galaxyCenter = Offset(
      size.width * 0.75 + math.sin(heading * 0.01) * 20,
      size.height * 0.28 + py * 0.2,
    );
    canvas.save();
    canvas.translate(galaxyCenter.dx, galaxyCenter.dy);
    canvas.rotate(rotation);

    // Galaxy core glow
    final Paint galaxyCorePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          themeColor.withValues(alpha: 0.6),
          const Color(0xFF9333EA).withValues(alpha: 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 80));
    canvas.drawCircle(Offset.zero, 80, galaxyCorePaint);

    // Spiral arms with celestial dust particles
    final Paint armPaint = Paint()..style = PaintingStyle.fill;
    for (int arm = 0; arm < 3; arm++) {
      final double armOffset = arm * (2 * math.pi / 3);
      for (int i = 5; i < 40; i++) {
        final double dist = i * 2.2;
        final double angle = armOffset + (dist * 0.06);
        final double dotX = math.cos(angle) * dist;
        final double dotY = math.sin(angle) * dist;
        final double alpha = (1.0 - (i / 40.0)).clamp(0.1, 0.8);
        armPaint.color = (i % 2 == 0 ? themeColor : const Color(0xFFD8B4FE))
            .withValues(alpha: alpha * 0.6);
        canvas.drawCircle(Offset(dotX, dotY), 1.2 + (i % 3) * 0.4, armPaint);
      }
    }
    canvas.restore();

    // 4. Glowing Solar Corona / Sun Disc
    final Offset sunCenter = Offset(
      size.width * 0.18 + px * 0.1,
      size.height * 0.72 + py * 0.3,
    );
    // Outer solar flares
    final Paint coronaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.45),
          const Color(0xFFFF8C00).withValues(alpha: 0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 65));
    canvas.drawCircle(sunCenter, 65, coronaPaint);

    // Inner bright solar core
    final Paint sunCorePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFFFE57F),
          const Color(0xFFFF9E80),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 18));
    canvas.drawCircle(sunCenter, 18, sunCorePaint);

    // 5. Twinkling Starfield
    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    for (final star in stars) {
      final double sx = (star.x * size.width + px) % size.width;
      final double sy = (star.y * size.height + py) % size.height;

      final double twinkleAlpha = (0.35 +
              0.65 *
                  math.sin(twinkle * 2 * math.pi + star.alphaOffset).abs())
          .clamp(0.15, 1.0);

      Color baseColor;
      switch (star.colorType) {
        case 0:
          baseColor = Colors.white;
          break;
        case 1:
          baseColor = themeColor;
          break;
        case 2:
          baseColor = const Color(0xFFFFE082); // Warm star
          break;
        default:
          baseColor = const Color(0xFFBAE6FD); // Blue giant
      }

      starPaint.color = baseColor.withValues(alpha: twinkleAlpha);
      canvas.drawCircle(Offset(sx, sy), star.radius, starPaint);

      // Star cross flare for large stars
      if (star.radius > 2.0 && twinkleAlpha > 0.7) {
        final Paint flarePaint = Paint()
          ..color = baseColor.withValues(alpha: twinkleAlpha * 0.5)
          ..strokeWidth = 0.8;
        canvas.drawLine(
          Offset(sx - 4, sy),
          Offset(sx + 4, sy),
          flarePaint,
        );
        canvas.drawLine(
          Offset(sx, sy - 4),
          Offset(sx, sy + 4),
          flarePaint,
        );
      }
    }

    // 6. Constellation Lines (Orion's Belt & Major Stars Simulation)
    _drawConstellation(canvas, size, px, py);

    // 7. Shooting Star / Meteor Streak
    if (meteorProgress > 0.1 && meteorProgress < 0.35) {
      final double mNorm = (meteorProgress - 0.1) / 0.25;
      final double startX = size.width * 0.9 - mNorm * (size.width * 0.7);
      final double startY = size.height * 0.1 + mNorm * (size.height * 0.3);
      final double trailLen = 60.0;

      final Paint meteorPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            themeColor.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0.95),
          ],
        ).createShader(
          Rect.fromPoints(
            Offset(startX + trailLen * 0.7, startY - trailLen * 0.3),
            Offset(startX, startY),
          ),
        )
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(startX + trailLen * 0.7, startY - trailLen * 0.3),
        Offset(startX, startY),
        meteorPaint,
      );
    }
  }

  void _drawConstellation(Canvas canvas, Size size, double px, double py) {
    final double cx = (size.width * 0.5 + px * 0.5) % size.width;
    final double cy = (size.height * 0.45 + py * 0.5) % size.height;

    // Simulated Orion / Asterism nodes
    final List<Offset> nodes = [
      Offset(cx - 35, cy - 45), // Betelgeuse
      Offset(cx + 35, cy - 40), // Bellatrix
      Offset(cx - 15, cy - 5),  // Alnitak
      Offset(cx, cy - 2),       // Alnilam
      Offset(cx + 15, cy + 1),  // Mintaka
      Offset(cx - 30, cy + 45), // Saiph
      Offset(cx + 35, cy + 48), // Rigel
    ];

    final Paint linePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Skeleton connections
    canvas.drawLine(nodes[0], nodes[2], linePaint);
    canvas.drawLine(nodes[1], nodes[4], linePaint);
    canvas.drawLine(nodes[2], nodes[3], linePaint);
    canvas.drawLine(nodes[3], nodes[4], linePaint);
    canvas.drawLine(nodes[2], nodes[5], linePaint);
    canvas.drawLine(nodes[4], nodes[6], linePaint);

    // Glowing anchor nodes
    final Paint nodeGlow = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < nodes.length; i++) {
      final Offset pt = nodes[i];
      nodeGlow.color = (i == 0 ? const Color(0xFFFF7043) : themeColor)
          .withValues(alpha: 0.85);
      canvas.drawCircle(pt, 2.8, nodeGlow);
      nodeGlow.color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(pt, 1.2, nodeGlow);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.twinkle != twinkle ||
        oldDelegate.meteorProgress != meteorProgress ||
        oldDelegate.heading != heading ||
        oldDelegate.pitch != pitch ||
        oldDelegate.themeColor != themeColor;
  }
}
