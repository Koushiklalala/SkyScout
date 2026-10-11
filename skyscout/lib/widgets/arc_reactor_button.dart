import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Holographic Arc-Reactor button with rotating energy rings,
/// breathing reactor core, and outward scan waves.
class ArcReactorButton extends StatefulWidget {
  final bool isScanning;
  final VoidCallback onTap;
  final Color themeColor;

  const ArcReactorButton({
    super.key,
    required this.isScanning,
    required this.onTap,
    this.themeColor = const Color(0xFF00F2FE),
  });

  @override
  State<ArcReactorButton> createState() => _ArcReactorButtonState();
}

class _ArcReactorButtonState extends State<ArcReactorButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, _) {
        final double pulse = _pulseController.value;
        final double angle = _rotationController.value * 2 * math.pi;

        return GestureDetector(
          onTap: widget.isScanning ? null : widget.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Arc Reactor Core Container
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Expanding Glow Waves
                    Container(
                      width: 86 + (pulse * 10),
                      height: 86 + (pulse * 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.themeColor.withValues(
                            alpha: (0.3 - pulse * 0.2).clamp(0.0, 1.0),
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),

                    // Rotating Cyber Segments Ring
                    Transform.rotate(
                      angle: widget.isScanning ? angle * 3 : angle,
                      child: CustomPaint(
                        size: const Size(82, 82),
                        painter: _ArcRingsPainter(
                          color: widget.themeColor,
                          isScanning: widget.isScanning,
                        ),
                      ),
                    ),

                    // Counter-rotating Inner Ring
                    Transform.rotate(
                      angle: -angle * 1.5,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.themeColor.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),

                    // Center Solid Reactor Disc with Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white,
                            widget.themeColor,
                            const Color(0xFF070B18),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.themeColor.withValues(
                              alpha: widget.isScanning ? 0.9 : 0.6,
                            ),
                            blurRadius: widget.isScanning ? 24 : 14,
                            spreadRadius: widget.isScanning ? 4 : 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: widget.isScanning
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.radar,
                                color: Colors.black.withValues(alpha: 0.85),
                                size: 26,
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Tactical Action Text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.themeColor.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isScanning ? Icons.sync : Icons.camera_alt,
                      size: 13,
                      color: widget.themeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isScanning
                          ? "ANALYZING 4K SKY IMAGE..."
                          : "CAPTURE SKY PHOTO & ANALYZE",
                      style: TextStyle(
                        color: widget.themeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArcRingsPainter extends CustomPainter {
  final Color color;
  final bool isScanning;

  _ArcRingsPainter({required this.color, required this.isScanning});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    final Paint arcPaint = Paint()
      ..color = (isScanning ? const Color(0xFFFF0055) : color)
          .withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Draw 3 arc notches
    for (int i = 0; i < 3; i++) {
      final double startAngle = (i * 2 * math.pi / 3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.pi / 2.2,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcRingsPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isScanning != isScanning;
  }
}
