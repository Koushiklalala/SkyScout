import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/cosmic_background.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color _themeColor = const Color(0xFF00F2FE);

  Future<void> _handleLogout() async {
    await ApiService.instance.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = ApiService.instance.userName;
    final age = ApiService.instance.userAge;
    final gender = ApiService.instance.userGender;
    final style = ApiService.instance.userStoryStyle;
    final email = ApiService.instance.userEmail ?? "Not signed in";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Unified Cosmic Background
          const Positioned.fill(
            child: CosmicBackground(),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
                      ),
                      Text(
                        "OBSERVER PROFILE",
                        style: TextStyle(
                          color: _themeColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      IconButton(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout, color: Color(0xFFFF5252), size: 20),
                        tooltip: "Logout",
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Holographic Avatar Badge
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white,
                                _themeColor,
                                const Color(0xFF070B18),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _themeColor.withValues(alpha: 0.5),
                                blurRadius: 24,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_pin_circle,
                              size: 44,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Personalized Observer Details Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF070B18).withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _themeColor.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "PERSONAL STORY PROFILE",
                                        style: TextStyle(
                                          color: _themeColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _editProfile,
                                        child: Text(
                                          "EDIT",
                                          style: TextStyle(
                                            color: _themeColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailRow("Age", "$age years old"),
                                  const Divider(color: Colors.white12, height: 20),
                                  _buildDetailRow("Gender", gender),
                                  const Divider(color: Colors.white12, height: 20),
                                  _buildDetailRow("Storytelling Narrative", style),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Stats Grid (Glassmorphism)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF070B18).withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _themeColor.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem("4K", "CAMERA SENSOR", Icons.camera_alt),
                                  Container(width: 1, height: 36, color: Colors.white12),
                                  _buildStatItem("IAU 88", "DATABASE", Icons.stars),
                                  Container(width: 1, height: 36, color: Colors.white12),
                                  _buildStatItem("AI", "AUDIO STORY", Icons.record_voice_over),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: _handleLogout,
                            icon: const Icon(Icons.logout, color: Color(0xFFFF5252), size: 16),
                            label: const Text(
                              "SIGN OUT",
                              style: TextStyle(
                                color: Color(0xFFFF5252),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0x66FF5252), width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: _themeColor),
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 8,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
