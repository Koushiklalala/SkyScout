import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/cosmic_background.dart';
import '../services/api_service.dart';
import 'cosmic_hud_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String? statusNotice;

  const OtpScreen({
    super.key,
    required this.email,
    this.statusNotice,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final Color _themeColor = const Color(0xFF00F2FE);

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length < 4) {
      setState(() {
        _errorMessage = "Please enter the full 6-digit verification code.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.instance.verifyOtp(widget.email, code);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (res['token'] != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CosmicHudScreen()),
          (route) => false,
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
                        color: const Color(0xFF070B18).withValues(alpha: 0.8),
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
                          // Lock Icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _themeColor.withValues(alpha: 0.15),
                              border: Border.all(
                                color: _themeColor.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.lock_open,
                              color: _themeColor,
                              size: 28,
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            "ENTER ACCESS CODE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Dispatched to: ${widget.email}",
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.center,
                          ),

                          if (widget.statusNotice != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _themeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.statusNotice!,
                                style: TextStyle(
                                  color: _themeColor,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // OTP Input field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _themeColor.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _otpController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                letterSpacing: 8.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                counterText: "",
                                hintText: "••••••",
                                hintStyle: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 24,
                                  letterSpacing: 8.0,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFFF5252),
                                fontSize: 11,
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Authenticate Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleVerify,
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
                                  : const Text(
                                      "AUTHENTICATE CORE",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "RE-ENTER EMAIL",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                letterSpacing: 1.0,
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
}
