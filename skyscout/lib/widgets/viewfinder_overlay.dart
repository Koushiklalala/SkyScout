import 'package:flutter/material.dart';

/// Minimal, unobstructed holographic viewfinder brackets.
/// Replaces the intrusive center spinning circle so the night sky is crystal clear.
class ViewfinderOverlay extends StatelessWidget {
  final Color themeColor;
  final bool isScanning;

  const ViewfinderOverlay({
    super.key,
    required this.themeColor,
    this.isScanning = false,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 220,
          height: 220,
          child: CustomPaint(
            painter: _ViewfinderPainter(
              color: isScanning ? const Color(0xFFFF2A6D) : themeColor,
              isScanning: isScanning,
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final Color color;
  final bool isScanning;

  _ViewfinderPainter({required this.color, required this.isScanning});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bracketPaint = Paint()
      ..color = color.withValues(alpha: isScanning ? 0.9 : 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    const double cornerLen = 18.0;
    final Rect rect = Offset.zero & size;

    // Top-Left
    canvas.drawLine(rect.topLeft, Offset(rect.left + cornerLen, rect.top), bracketPaint);
    canvas.drawLine(rect.topLeft, Offset(rect.left, rect.top + cornerLen), bracketPaint);

    // Top-Right
    canvas.drawLine(rect.topRight, Offset(rect.right - cornerLen, rect.top), bracketPaint);
    canvas.drawLine(rect.topRight, Offset(rect.right, rect.top + cornerLen), bracketPaint);

    // Bottom-Left
    canvas.drawLine(rect.bottomLeft, Offset(rect.left + cornerLen, rect.bottom), bracketPaint);
    canvas.drawLine(rect.bottomLeft, Offset(rect.left, rect.bottom - cornerLen), bracketPaint);

    // Bottom-Right
    canvas.drawLine(rect.bottomRight, Offset(rect.right - cornerLen, rect.bottom), bracketPaint);
    canvas.drawLine(rect.bottomRight, Offset(rect.right, rect.bottom - cornerLen), bracketPaint);

    // Subtle Center Target Crosshair Dot
    final Paint centerPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(rect.center, 2.5, centerPaint);

    // Crosshair tick marks
    final Paint tickPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(rect.center.dx - 12, rect.center.dy), Offset(rect.center.dx - 5, rect.center.dy), tickPaint);
    canvas.drawLine(Offset(rect.center.dx + 5, rect.center.dy), Offset(rect.center.dx + 12, rect.center.dy), tickPaint);
    canvas.drawLine(Offset(rect.center.dx, rect.center.dy - 12), Offset(rect.center.dx, rect.center.dy - 5), tickPaint);
    canvas.drawLine(Offset(rect.center.dx, rect.center.dy + 5), Offset(rect.center.dx, rect.center.dy + 12), tickPaint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isScanning != isScanning;
  }
}
