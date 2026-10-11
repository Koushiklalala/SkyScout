import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  // Storage keys
  static const String _keyToken = 'skyscout_jwt_token';
  static const String _keyEmail = 'skyscout_user_email';
  static const String _keyName = 'skyscout_user_name';
  static const String _keyAge = 'skyscout_user_age';
  static const String _keyGender = 'skyscout_user_gender';
  static const String _keyStoryStyle = 'skyscout_user_story_style';
  static const String _keyProfileCompleted = 'skyscout_profile_completed';

  // Live Render Production Backend URL
  String baseUrl = "https://skyscout-suf7.onrender.com";

  String? jwtToken;
  String? userEmail;
  
  // Personalized Profile Data
  String userName = "Observer";
  String userAge = "24";
  String userGender = "Male";
  String userStoryStyle = "Astrophysical & Science";
  bool isProfileCompleted = false;

  bool get isAuthenticated => jwtToken != null && jwtToken!.isNotEmpty;

  /// Loads persisted user credentials & profile from mobile local storage
  Future<void> initLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      jwtToken = prefs.getString(_keyToken);
      userEmail = prefs.getString(_keyEmail);
      userName = prefs.getString(_keyName) ?? "Observer";
      userAge = prefs.getString(_keyAge) ?? "24";
      userGender = prefs.getString(_keyGender) ?? "Male";
      userStoryStyle = prefs.getString(_keyStoryStyle) ?? "Astrophysical & Science";
      isProfileCompleted = prefs.getBool(_keyProfileCompleted) ?? false;

      debugPrint("[ApiService] Local storage loaded: authenticated=$isAuthenticated, profileCompleted=$isProfileCompleted, user=$userName");
    } catch (e) {
      debugPrint("[ApiService] Notice loading local storage: $e");
    }
  }

  /// Persists personalized profile data into mobile local storage
  Future<void> saveUserProfile({
    required String name,
    required String age,
    required String gender,
    required String storyStyle,
  }) async {
    userName = name.isNotEmpty ? name : "Observer";
    userAge = age.isNotEmpty ? age : "24";
    userGender = gender;
    userStoryStyle = storyStyle;
    isProfileCompleted = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyName, userName);
      await prefs.setString(_keyAge, userAge);
      await prefs.setString(_keyGender, userGender);
      await prefs.setString(_keyStoryStyle, userStoryStyle);
      await prefs.setBool(_keyProfileCompleted, true);
      debugPrint("[ApiService] Profile persisted to local storage: $userName ($userAge)");
    } catch (e) {
      debugPrint("[ApiService] Error persisting profile: $e");
    }
  }

  /// Request OTP from backend
  Future<Map<String, dynamic>> requestOtp(String email) async {
    userEmail = email;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint("API offline or error: $e");
    }

    return {
      'message': 'OTP dispatched. (If offline: enter any 6 digits to proceed)',
      'isOffline': true,
    };
  }

  /// Verify OTP and persist session to mobile local storage
  Future<Map<String, dynamic>> verifyOtp(String email, String otpCode) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otpCode': otpCode}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        jwtToken = data['token'];
        userEmail = email;

        // Persist token & email to local storage
        final prefs = await SharedPreferences.getInstance();
        if (jwtToken != null) await prefs.setString(_keyToken, jwtToken!);
        await prefs.setString(_keyEmail, email);

        debugPrint("[ApiService] Session authenticated and saved to local storage.");
        return data;
      }
    } catch (e) {
      debugPrint("API verify notice: $e");
    }

    // Fallback token for offline resilience
    jwtToken = "skyscout-auth-${DateTime.now().millisecondsSinceEpoch}";
    userEmail = email;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, jwtToken!);
      await prefs.setString(_keyEmail, email);
    } catch (_) {}

    return {
      'token': jwtToken,
      'isOffline': true,
    };
  }

  /// Stargaze lookup: Sends sensor telemetry + original 4K image + personalized profile to backend
  Future<Map<String, dynamic>?> lookupStargaze({
    required double lat,
    required double lng,
    required double azimuth,
    required double pitch,
    String? imageBase64,
  }) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      if (jwtToken != null) {
        headers['Authorization'] = 'Bearer $jwtToken';
      }

      final Map<String, dynamic> payload = {
        'lat': lat,
        'lng': lng,
        'azimuth': azimuth,
        'pitch': pitch,
        'name': userName,
        'age': userAge,
        'gender': userGender,
        'storyStyle': userStoryStyle,
      };

      if (imageBase64 != null) {
        payload['imageBase64'] = imageBase64.length > 500000 
            ? imageBase64.substring(0, 500000) 
            : imageBase64;
      }

      debugPrint("[ApiService] Sending request to $baseUrl/api/stargaze/lookup...");
      final res = await http.post(
        Uri.parse('$baseUrl/api/stargaze/lookup'),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        debugPrint("[ApiService] Backend response received! Constellation: ${data['matchedConstellation']}, Audio: ${data['audioUrl']}");
        return data;
      } else {
        debugPrint("[ApiService] Server returned HTTP ${res.statusCode}: ${res.body}");
      }
    } catch (e) {
      debugPrint("[ApiService] Stargaze backend connection error: $e");
    }

    return null;
  }

  /// Log out and wipe local storage credentials
  Future<void> logout() async {
    jwtToken = null;
    userEmail = null;
    isProfileCompleted = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyProfileCompleted);
      debugPrint("[ApiService] Logged out. Local session cleared.");
    } catch (e) {
      debugPrint("[ApiService] Error clearing local session: $e");
    }
  }
}
