
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class DeviceService {
  static const String _tokenKey = 'device_token';
  static const String _registeredKey = 'device_registered';
  static const String _appSalt = 'she-absolutely:';

  static Future<String> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_tokenKey);

    if (token == null) {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;
      try {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } catch (e) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
      }
      
      final bytes = utf8.encode(_appSalt + deviceId);
      token = sha256.convert(bytes).toString();
      await prefs.setString(_tokenKey, token);
    }
    return token;
  }

  static Future<void> registerDevice(String apiBaseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyRegistered = prefs.getBool(_registeredKey) ?? false;

    if (!alreadyRegistered) {
      final token = await getDeviceToken();
      try {
        final response = await http.post(
          Uri.parse('$apiBaseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'deviceToken': token}),
        );

        if (response.statusCode == 200) {
          await prefs.setBool(_registeredKey, true);
          print('Device registered successfully.');
        } else {
          print('Device registration failed: ${response.body}');
        }
      } catch (e) {
        print('Error registering device: $e');
      }
    }
  }
}
