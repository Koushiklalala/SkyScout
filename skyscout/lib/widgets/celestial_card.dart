import 'package:flutter/material.dart';
import 'audio_visualizer.dart';

/// Holographic modal card displaying matched constellation details,
/// mythology, astrophysics telemetry, and server audio playback controls.
class CelestialCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String mythology;
  final String science;
  final String hemisphere;
  final bool isPlayingAudio;
  final bool isMuted;
  final VoidCallback onToggleAudio;
  final VoidCallback onRewind;
  final VoidCallback onToggleMute;
  final VoidCallback onDismiss;
  final Color themeColor;

  const CelestialCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.mythology,
    required this.science,
    required this.hemisphere,
    required this.isPlayingAudio,
    required this.isMuted,
    required this.onToggleAudio,
    required this.onRewind,
    required this.onToggleMute,
    required this.onDismiss,
    this.themeColor = const Color(0xFF00F2FE),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF070B18).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.2),
            blurRadius: 20.0,
            spreadRadius: 2.0,
          ),
          const BoxShadow(
            color: Colors.black,
            blurRadius: 30.0,
            spreadRadius: 5.0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Constellation Name, Badge & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: themeColor,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: themeColor.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            hemisphere.toUpperCase(),
                            style: TextStyle(
                              color: themeColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: themeColor.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Mythology & Lore Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.6,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories, size: 13, color: themeColor),
                    const SizedBox(width: 6),
                    Text(
                      "MYTHOLOGY & ANCIENT HISTORY",
                      style: TextStyle(
                        color: themeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  mythology,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.biotech, size: 13, color: Color(0xFFFFD000)),
                    const SizedBox(width: 6),
                    const Text(
                      "ASTROPHYSICAL DATA",
                      style: TextStyle(
                        color: Color(0xFFFFD000),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  science,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Audio Narration & Waveform Player Controls (Play, Pause, Rewind, Mute)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 0.8),
            ),
            child: Row(
              children: [
                // Waveform Visualizer - takes available width flexibly
                Expanded(
                  child: AudioVisualizer(
                    isPlaying: isPlayingAudio,
                    themeColor: themeColor,
                  ),
                ),

                const SizedBox(width: 8),

                // Control Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rewind 10s
                    InkWell(
                      onTap: onRewind,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.replay_10, size: 18, color: Colors.white70),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Mute / Unmute
                    InkWell(
                      onTap: onToggleMute,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          isMuted ? Icons.volume_off : Icons.volume_up,
                          size: 18,
                          color: isMuted ? const Color(0xFFFF5252) : Colors.white70,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Play / Pause Button
                    InkWell(
                      onTap: onToggleAudio,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPlayingAudio ? Icons.pause : Icons.play_arrow,
                              size: 14,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isPlayingAudio ? "PAUSE" : "PLAY",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
