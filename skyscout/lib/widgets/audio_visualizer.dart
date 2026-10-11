import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Holographic soundwave frequency bars for Jarvis narration.
class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color themeColor;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.themeColor = const Color(0xFF00F2FE),
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 120.0;
        final barCount = (availableWidth / 6.0).floor().clamp(6, 24);

        return AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(barCount, (index) {
                double height = 4.0;
                if (widget.isPlaying) {
                  final double t = _waveController.value * 2 * math.pi;
                  final double wave = math.sin(t + index * 0.45).abs();
                  final double wave2 = math.cos(t * 1.5 + index * 0.3).abs();
                  height = 6.0 + (wave * 0.6 + wave2 * 0.4) * 22.0;
                }

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.2),
                  width: 2.8,
                  height: height,
                  decoration: BoxDecoration(
                    color: widget.isPlaying
                        ? (index % 4 == 0 ? Colors.white : widget.themeColor)
                        : widget.themeColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2.0),
                    boxShadow: widget.isPlaying
                        ? [
                            BoxShadow(
                              color: widget.themeColor.withValues(alpha: 0.6),
                              blurRadius: 3.0,
                              spreadRadius: 1.0,
                            )
                          ]
                        : null,
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}
