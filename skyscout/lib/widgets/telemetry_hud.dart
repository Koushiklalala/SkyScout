import 'package:flutter/material.dart';

/// Top telemetry HUD displaying user profile, active sector, mode switcher,
/// and real-time astronomical coordinates (GPS, Compass Azimuth, Tilt Pitch).
class TelemetryHud extends StatelessWidget {
  final String userName;
  final VoidCallback onOpenProfile;
  final double? latitude;
  final double? longitude;
  final double heading;
  final double pitch;
  final bool isCameraMode;
  final VoidCallback onToggleMode;
  final Color themeColor;
  final VoidCallback onCycleTheme;
  final String activeSector;

  const TelemetryHud({
    super.key,
    required this.userName,
    required this.onOpenProfile,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.pitch,
    required this.isCameraMode,
    required this.onToggleMode,
    required this.themeColor,
    required this.onCycleTheme,
    this.activeSector = "CELESTIAL SPHERE",
  });

  String _getCardinal(double deg) {
    deg = (deg % 360 + 360) % 360;
    if (deg >= 337.5 || deg < 22.5) return 'N';
    if (deg >= 22.5 && deg < 67.5) return 'NE';
    if (deg >= 67.5 && deg < 112.5) return 'E';
    if (deg >= 112.5 && deg < 157.5) return 'SE';
    if (deg >= 157.5 && deg < 202.5) return 'S';
    if (deg >= 202.5 && deg < 247.5) return 'SW';
    if (deg >= 247.5 && deg < 292.5) return 'W';
    return 'NW';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ==========================================
        // 1. UNIFIED HEADER BAR (NO DUPLICATES, ZERO OVERFLOW)
        // ==========================================
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.1),
                blurRadius: 10.0,
              ),
            ],
          ),
          child: Row(
            children: [
              // Profile Pill Button
              InkWell(
                onTap: onOpenProfile,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_circle, color: themeColor, size: 15),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: Text(
                          userName.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Active Celestial Sector & Live Status (Expands safely)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00FF66),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FF66).withValues(alpha: 0.8),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          activeSector.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 4K Camera <-> Deep Space Toggle Pill
              InkWell(
                onTap: onToggleMode,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCameraMode
                        ? themeColor.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: themeColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCameraMode ? Icons.camera_alt : Icons.auto_awesome,
                        size: 13,
                        color: isCameraMode ? Colors.white : themeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCameraMode ? "4K CAM" : "SPACE",
                        style: TextStyle(
                          color: isCameraMode ? Colors.white : themeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Theme Hue Switcher Icon Button
              InkWell(
                onTap: onCycleTheme,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    size: 15,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ==========================================
        // 2. LIVE TELEMETRY SENSOR ROW (FLEXIBLE 3 COLUMNS)
        // ==========================================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
          child: Row(
            children: [
              // Left: GPS Coordinates & Satellite Lock
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.satellite_alt,
                  label: "POSITION",
                  value: latitude != null && longitude != null
                      ? "${latitude!.toStringAsFixed(1)}°, ${longitude!.toStringAsFixed(1)}°"
                      : "GPS LOCK...",
                  sub: "ORBITAL",
                ),
              ),

              const SizedBox(width: 6),

              // Center: Azimuth Compass & Direction
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.explore,
                  label: "AZIMUTH",
                  value: "${heading.toStringAsFixed(1)}° [${_getCardinal(heading)}]",
                  sub: "TRUE NORTH",
                  isHighlight: true,
                ),
              ),

              const SizedBox(width: 6),

              // Right: Pitch Tilt Ladder
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.height,
                  label: "PITCH",
                  value: "${pitch.toStringAsFixed(1)}°",
                  sub: pitch > 30 ? "ZENITH SKY" : "HORIZON",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight
              ? themeColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 10,
                color: isHighlight ? themeColor : Colors.white60,
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  color: isHighlight ? themeColor : Colors.white60,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              color: isHighlight
                  ? themeColor.withValues(alpha: 0.7)
                  : Colors.white38,
              fontSize: 7.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
