import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/cosmic_background.dart';
import '../services/api_service.dart';
import 'cosmic_hud_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController(text: "24");

  String _selectedGender = "Male";
  final List<String> _genders = ["Male", "Female", "Other", "Prefer not to say"];

  String _selectedStyle = "Mythological & Folklore";
  final List<String> _styles = [
    "Mythological & Folklore",
    "Astrophysical & Science",
    "Poetic & Ancient Cosmos",
  ];

  final Color _themeColor = const Color(0xFF00F2FE);

  @override
  void initState() {
    super.initState();
    if (ApiService.instance.userName != "Observer") {
      _nameController.text = ApiService.instance.userName;
    }
    _ageController.text = ApiService.instance.userAge;
    _selectedGender = ApiService.instance.userGender;
    _selectedStyle = ApiService.instance.userStoryStyle;
  }

  Future<void> _handleSaveAndProceed() async {
    final name = _nameController.text.trim();
    final age = _ageController.text.trim();

    await ApiService.instance.saveUserProfile(
      name: name.isNotEmpty ? name : "Stargazer",
      age: age.isNotEmpty ? age : "24",
      gender: _selectedGender,
      storyStyle: _selectedStyle,
    );

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const CosmicHudScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Unified Cosmic Background
          const Positioned.fill(
            child: CosmicBackground(),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF070B18).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _themeColor.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _themeColor.withValues(alpha: 0.15),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                          const BoxShadow(
                            color: Colors.black,
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white,
                                        _themeColor,
                                        const Color(0xFF031024),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _themeColor.withValues(alpha: 0.5),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.badge,
                                    color: Colors.black,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "OBSERVER IDENTITY",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Personalize your AI celestial storytelling",
                                  style: TextStyle(
                                    color: _themeColor.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Name Input
                          _buildSectionTitle("YOUR NAME"),
                          const SizedBox(height: 6),
                          Container(
                            decoration: _buildInputBoxDecoration(),
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: "Enter Your Name",
                                hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Age Input
                          _buildSectionTitle("AGE"),
                          const SizedBox(height: 6),
                          Container(
                            decoration: _buildInputBoxDecoration(),
                            child: TextField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: "Enter Age",
                                hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Gender Selection
                          _buildSectionTitle("GENDER"),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _genders.map((g) {
                              final isSelected = _selectedGender == g;
                              return ChoiceChip(
                                label: Text(g),
                                selected: isSelected,
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedGender = g);
                                },
                                selectedColor: _themeColor,
                                backgroundColor: Colors.black.withValues(alpha: 0.6),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected ? _themeColor : Colors.white24,
                                    width: 1,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),

                          // Story Style
                          _buildSectionTitle("PREFERRED STORY NARRATIVE"),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _styles.map((s) {
                              final isSelected = _selectedStyle == s;
                              return ChoiceChip(
                                label: Text(s),
                                selected: isSelected,
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedStyle = s);
                                },
                                selectedColor: _themeColor,
                                backgroundColor: Colors.black.withValues(alpha: 0.6),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected ? _themeColor : Colors.white24,
                                    width: 1,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 28),

                          // Proceed Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _handleSaveAndProceed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _themeColor,
                                foregroundColor: Colors.black,
                                elevation: 8,
                                shadowColor: _themeColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "START STARGAZING",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _themeColor.withValues(alpha: 0.9),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  BoxDecoration _buildInputBoxDecoration() {
    return BoxDecoration(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: _themeColor.withValues(alpha: 0.4),
        width: 1.0,
      ),
    );
  }
}
