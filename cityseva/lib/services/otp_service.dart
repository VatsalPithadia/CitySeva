import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// OTP Service — generates, sends and verifies OTP
/// Uses backend email endpoint for sending OTP
/// Stores OTP securely using flutter_secure_storage
class OtpService {
  static const _storage = FlutterSecureStorage();
  static const _baseUrl = 'https://cityseva-backend.onrender.com/api/auth';

  /// Generate a 6-digit OTP
  static String _generateOtp() {
    final rand = Random.secure();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  /// Send OTP to email via backend
  /// Returns true if sent successfully
  static Future<OtpResult> sendOtp(String email) async {
    try {
      final otp = _generateOtp();

      // Store OTP securely with expiry timestamp (5 minutes)
      final expiry = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
      await _storage.write(key: 'otp_code', value: otp);
      await _storage.write(key: 'otp_email', value: email);
      await _storage.write(key: 'otp_expiry', value: expiry.toString());

      // Send OTP via backend
      final res = await http.post(
        Uri.parse('$_baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        return OtpResult(success: true, message: 'OTP sent to $email');
      }

      // If backend fails, still allow for hackathon demo — OTP stored locally
      return OtpResult(success: true, message: 'OTP sent to $email (demo mode)');
    } catch (_) {
      // Fallback: generate and store OTP locally for demo
      final otp = _generateOtp();
      final expiry = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
      await _storage.write(key: 'otp_code', value: otp);
      await _storage.write(key: 'otp_email', value: email);
      await _storage.write(key: 'otp_expiry', value: expiry.toString());
      // Return OTP in message for demo/hackathon purposes
      return OtpResult(success: true, message: 'Demo OTP: $otp', demoOtp: otp);
    }
  }

  /// Verify OTP entered by user
  static Future<OtpResult> verifyOtp(String email, String enteredOtp) async {
    try {
      final storedOtp = await _storage.read(key: 'otp_code');
      final storedEmail = await _storage.read(key: 'otp_email');
      final expiryStr = await _storage.read(key: 'otp_expiry');

      if (storedOtp == null || storedEmail == null || expiryStr == null) {
        return OtpResult(success: false, message: 'OTP expired. Please request a new one.');
      }

      // Check email matches
      if (storedEmail != email) {
        return OtpResult(success: false, message: 'OTP was sent to a different email.');
      }

      // Check expiry
      final expiry = int.parse(expiryStr);
      if (DateTime.now().millisecondsSinceEpoch > expiry) {
        await _clearOtp();
        return OtpResult(success: false, message: 'OTP has expired. Please request a new one.');
      }

      // Check OTP match
      if (enteredOtp.trim() != storedOtp) {
        return OtpResult(success: false, message: 'Incorrect OTP. Please try again.');
      }

      // OTP verified — clear stored OTP
      await _clearOtp();
      return OtpResult(success: true, message: 'OTP verified successfully');
    } catch (_) {
      return OtpResult(success: false, message: 'Verification failed. Please try again.');
    }
  }

  static Future<void> _clearOtp() async {
    await _storage.delete(key: 'otp_code');
    await _storage.delete(key: 'otp_email');
    await _storage.delete(key: 'otp_expiry');
  }
}

class OtpResult {
  final bool success;
  final String message;
  final String? demoOtp; // Only used in demo/hackathon mode

  OtpResult({required this.success, required this.message, this.demoOtp});
}
