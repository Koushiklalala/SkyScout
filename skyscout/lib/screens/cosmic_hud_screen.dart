import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

import '../widgets/cosmic_background.dart';
import '../widgets/viewfinder_overlay.dart';
import '../widgets/telemetry_hud.dart';
import '../widgets/arc_reactor_button.dart';
import '../widgets/celestial_card.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

List<CameraDescription> globalCameras = [];

class CosmicHudScreen extends StatefulWidget {
  const CosmicHudScreen({super.key});

  @override
  State<CosmicHudScreen> createState() => _CosmicHudScreenState();
}

class _CosmicHudScreenState extends State<CosmicHudScreen> {
  CameraController? _cameraController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Sensor Telemetry
  double _heading = 0.0;
  double _pitch = 0.0;
  Position? _currentPosition;

  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;

  // App States
  bool _isCameraMode = true; // Default to live camera lens
  bool _isScanning = false;
  bool _isPlayingAudio = false;
  bool _isMuted = false;
  bool _cameraReady = false;

  // Active Story & Stargaze Data from Server
  Map<String, String>? _activeCelestial;
  String? _serverAudioUrl;

  // Theme Colors
  int _themeIndex = 0;
  final List<Color> _themes = const [
    Color(0xFF00F2FE), // Cyan
    Color(0xFFFF2A6D), // Crimson Night-Vision
    Color(0xFFFFD000), // Gold
    Color(0xFFA855F7), // Nebula Violet
  ];

  Color get _currentTheme => _themes[_themeIndex];

  @override
  void initState() {
    super.initState();
    _initSensorsAndCamera();
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
        });
      }
    });
  }

  Future<void> _initSensorsAndCamera() async {
    // 1. Permissions
    try {
      await [
        Permission.camera,
        Permission.locationWhenInUse,
      ].request();
    } catch (_) {}

    // 2. Camera in 4K / Maximum Hardware Sensor Resolution
    try {
      if (globalCameras.isEmpty) {
        globalCameras = await availableCameras();
      }
      if (globalCameras.isNotEmpty) {
        _cameraController = CameraController(
          globalCameras.first,
          ResolutionPreset.max, // 4K / native original photo size
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _cameraReady = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Camera initialization notice: $e");
    }

    // 3. GPS Location
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("GPS notice: $e");
    }

    // 4. Compass Heading
    try {
      _compassSubscription = FlutterCompass.events?.listen((event) {
        if (mounted && event.heading != null) {
          setState(() {
            _heading = event.heading!;
          });
        }
      });
    } catch (e) {
      debugPrint("Compass notice: $e");
    }

    // 5. Pitch / Tilt
    try {
      _accelSubscription = accelerometerEventStream().listen((event) {
        if (mounted) {
          setState(() {
            _pitch = (event.y * 9.0).clamp(-90.0, 90.0);
          });
        }
      });
    } catch (e) {
      debugPrint("Accelerometer notice: $e");
    }
  }

  void _cycleTheme() {
    setState(() {
      _themeIndex = (_themeIndex + 1) % _themes.length;
    });
  }

  void _toggleViewMode() {
    setState(() {
      _isCameraMode = !_isCameraMode;
    });
  }

  /// High-Quality 4K Photo Capture & Server-Side Star Identification
  Future<void> _handleCaptureAndAnalyze() async {
    setState(() {
      _isScanning = true;
      _activeCelestial = null;
    });

    String? imageBase64;

    // 1. Capture 4K photo in original native size from camera
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile photo = await _cameraController!.takePicture();
        final bytes = await File(photo.path).readAsBytes();
        imageBase64 = base64Encode(bytes);
        debugPrint("[SkyScout] Captured high-resolution photo: ${photo.path} (${bytes.length} bytes)");
      } catch (e) {
        debugPrint("[SkyScout] Capture error: $e");
      }
    }

    final lat = _currentPosition?.latitude ?? 12.26;
    final lng = _currentPosition?.longitude ?? 76.64;

    // 2. Send details to backend server
    final backendResult = await ApiService.instance.lookupStargaze(
      lat: lat,
      lng: lng,
      azimuth: _heading,
      pitch: _pitch,
      imageBase64: imageBase64,
    );

    if (!mounted) return;

    if (backendResult != null && backendResult['storyText'] != null) {
      final storyText = backendResult['storyText'] as String;
      final audioUrl = backendResult['audioUrl'] as String?;
      final matchedName = (backendResult['matchedConstellation'] as String?) ?? "Celestial Sector";

      setState(() {
        _isScanning = false;
        _activeCelestial = {
          "name": matchedName,
          "subtitle": "IDENTIFIED CELESTIAL ALIGNMENT",
          "mythology": storyText,
          "science": "Azimuth: ${_heading.toStringAsFixed(1)}° • Pitch: ${_pitch.toStringAsFixed(1)}°",
          "hemisphere": "Local Sky View",
        };
        _serverAudioUrl = audioUrl;
      });

      // 3. Play Server Generated Audio automatically
      if (audioUrl != null && audioUrl.isNotEmpty) {
        final fullAudioUrl = "${ApiService.instance.baseUrl}$audioUrl";
        debugPrint("[SkyScout] Playing server-generated audio: $fullAudioUrl");
        try {
          await _audioPlayer.stop();
          await _audioPlayer.play(UrlSource(fullAudioUrl));
          setState(() {
            _isPlayingAudio = true;
          });
        } catch (audioErr) {
          debugPrint("[SkyScout] Audio player notice: $audioErr");
        }
      }
    } else {
      // Backend is offline or didn't respond
      setState(() {
        _isScanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF070B18),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFFF5252), width: 1),
          ),
          content: const Row(
            children: [
              Icon(Icons.wifi_off, color: Color(0xFFFF5252), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Backend server offline. Connect phone to laptop hotspot and run backend (port 3000) to receive AI story & audio.",
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Audio Controls
  Future<void> _toggleAudio() async {
    if (_isPlayingAudio) {
      await _audioPlayer.pause();
      setState(() => _isPlayingAudio = false);
    } else {
      if (_serverAudioUrl != null) {
        final fullAudioUrl = "${ApiService.instance.baseUrl}$_serverAudioUrl";
        await _audioPlayer.play(UrlSource(fullAudioUrl));
        setState(() => _isPlayingAudio = true);
      }
    }
  }

  Future<void> _rewindAudio() async {
    final currentPos = await _audioPlayer.getCurrentPosition();
    if (currentPos != null) {
      final newPos = currentPos - const Duration(seconds: 10);
      await _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
    }
  }

  Future<void> _toggleMute() async {
    if (_isMuted) {
      await _audioPlayer.setVolume(1.0);
      setState(() => _isMuted = false);
    } else {
      await _audioPlayer.setVolume(0.0);
      setState(() => _isMuted = true);
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _compassSubscription?.cancel();
    _accelSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ==========================================
          // LAYER 1: BASE VIEW (LIVE 4K CAMERA OR DEEP COSMOS)
          // ==========================================
          if (_isCameraMode && _cameraReady && _cameraController != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1080,
                  height: _cameraController!.value.previewSize?.width ?? 1920,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            Positioned.fill(
              child: CosmicBackground(
                parallaxHeading: _heading,
                parallaxPitch: _pitch,
                themeColor: _currentTheme,
              ),
            ),

          // Gentle Cinema Vignette
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.15,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: _isCameraMode ? 0.35 : 0.65),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ==========================================
          // LAYER 2: MINIMAL UNOBSTRUCTED VIEWFINDER (NO SPINNING CIRCLE)
          // ==========================================
          Positioned.fill(
            child: ViewfinderOverlay(
              themeColor: _currentTheme,
              isScanning: _isScanning,
            ),
          ),

          // ==========================================
          // LAYER 3: TOP STATUS & TELEMETRY HUD
          // ==========================================
          SafeArea(
            child: Column(
              children: [
                // Unified Top Status & Telemetry HUD (Zero Overflow, Sleek Holographic Header)
                TelemetryHud(
                  userName: ApiService.instance.userName,
                  onOpenProfile: _openProfile,
                  latitude: _currentPosition?.latitude,
                  longitude: _currentPosition?.longitude,
                  heading: _heading,
                  pitch: _pitch,
                  isCameraMode: _isCameraMode,
                  onToggleMode: _toggleViewMode,
                  themeColor: _currentTheme,
                  onCycleTheme: _cycleTheme,
                  activeSector: _activeCelestial != null
                      ? _activeCelestial!["name"]!
                      : "OBSERVATORY LOCK",
                ),

                const Spacer(),

                // ==========================================
                // LAYER 4: CELESTIAL ANALYSIS RESULT CARD WITH SERVER AUDIO
                // ==========================================
                if (_activeCelestial != null)
                  CelestialCard(
                    name: _activeCelestial!["name"]!,
                    subtitle: _activeCelestial!["subtitle"]!,
                    mythology: _activeCelestial!["mythology"]!,
                    science: _activeCelestial!["science"]!,
                    hemisphere: _activeCelestial!["hemisphere"]!,
                    isPlayingAudio: _isPlayingAudio,
                    isMuted: _isMuted,
                    onToggleAudio: _toggleAudio,
                    onRewind: _rewindAudio,
                    onToggleMute: _toggleMute,
                    onDismiss: () async {
                      await _audioPlayer.stop();
                      setState(() {
                        _activeCelestial = null;
                        _isPlayingAudio = false;
                      });
                    },
                    themeColor: _currentTheme,
                  ),

                // ==========================================
                // LAYER 5: 4K PHOTO CAPTURE & SERVER ANALYSIS BUTTON
                // ==========================================
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                  child: ArcReactorButton(
                    isScanning: _isScanning,
                    onTap: _handleCaptureAndAnalyze,
                    themeColor: _currentTheme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
