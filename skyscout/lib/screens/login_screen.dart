import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/cosmic_background.dart';
import '../services/api_service.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _statusMessage;
  String? _errorMessage;

  final Color _themeColor = const Color(0xFF00F2FE);

  Future<void> _handleRequestOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = "Please enter a valid email address.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    final res = await ApiService.instance.requestOtp(email);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
        _statusMessage = res['message'] ?? "Verification code dispatched.";
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length < 4) {
      setState(() {
        _errorMessage = "Please enter the full 6-digit OTP code.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.instance.verifyOtp(email, otp);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (res['token'] != null) {
        // Navigate directly to Profile Setup Screen!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
        );
      } else {
        setState(() {
          _errorMessage = res['error'] ?? "Verification failed. Check the code.";
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 32.0,
                      ),
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
                        children: [
                          // App Emblem
                          Container(
                            width: 64,
                            height: 64,
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
                                  color: _themeColor.withValues(alpha: 0.6),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.auto_awesome,
                                color: Colors.black,
                                size: 32,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            "SKYSCOUT",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.0,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "CELESTIAL EXPLORATION",
                            style: TextStyle(
                              color: _themeColor.withValues(alpha: 0.85),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Step 1: Email Input (Clean placeholder, NO default email, NO @ prefix)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _themeColor.withValues(alpha: 0.45),
                                width: 1.0,
                              ),
                            ),
                            child: TextField(
                              controller: _emailController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_isOtpSent,
                              decoration: const InputDecoration(
                                hintText: "Enter Email ID",
                                hintStyle: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),

                          // Step 2: 6-digit OTP Input (Visible after OTP is requested)
                          if (_isOtpSent) ...[
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _themeColor,
                                  width: 1.2,
                                ),
                              ),
                              child: TextField(
                                controller: _otpController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  letterSpacing: 6.0,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: const InputDecoration(
                                  counterText: "",
                                  hintText: "Enter 6-Digit OTP",
                                  hintStyle: TextStyle(
                                    color: Colors.white30,
                                    fontSize: 13,
                                    letterSpacing: 1.0,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          if (_statusMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _statusMessage!,
                              style: TextStyle(
                                color: _themeColor,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFFF5252),
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Button: "SEND OTP" or "VERIFY"
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : (_isOtpSent ? _handleVerifyOtp : _handleRequestOtp),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _themeColor,
                                foregroundColor: Colors.black,
                                elevation: 8,
                                shadowColor: _themeColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.black,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      _isOtpSent ? "VERIFY" : "SEND OTP",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ),

                          if (_isOtpSent) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isOtpSent = false;
                                  _otpController.clear();
                                  _statusMessage = null;
                                  _errorMessage = null;
                                });
                              },
                              child: const Text(
                                "CHANGE EMAIL",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
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
}
