import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'services/api_service.dart';
import 'screens/cosmic_hud_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Discover device cameras
  try {
    globalCameras = await availableCameras();
  } catch (e) {
    debugPrint('Notice during camera discovery: $e');
  }

  // 2. Load persisted session & profile from local storage
  await ApiService.instance.initLocalStorage();

  runApp(const SkyScoutApp());
}

class SkyScoutApp extends StatelessWidget {
  const SkyScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Intelligent launch router based on mobile local storage:
    // If logged in & profile complete -> opens directly to 4K sky capture screen!
    Widget initialScreen;
    if (ApiService.instance.isAuthenticated && ApiService.instance.isProfileCompleted) {
      initialScreen = const CosmicHudScreen();
    } else if (ApiService.instance.isAuthenticated) {
      initialScreen = const ProfileSetupScreen();
    } else {
      initialScreen = const LoginScreen();
    }

    return MaterialApp(
      title: 'SkyScout Stargazer AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FE),
          secondary: Color(0xFFFFD000),
          surface: Colors.black,
        ),
      ),
      home: initialScreen,
    );
  }
}
