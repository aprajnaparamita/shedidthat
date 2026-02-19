import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class DeviceService {
  static const _deviceTokenKey = 'device_token';
  static const _deviceRegisteredKey = 'device_registered';

  static Future<String> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_deviceTokenKey);

    if (token == null) {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor!;
        } else {
          deviceId = 'unknown_platform';
        }
      } catch (e) {
        deviceId = 'error_getting_id';
      }

      final bytes = utf8.encode('she-absolutely:' + deviceId);
      token = sha256.convert(bytes).toString();
      await prefs.setString(_deviceTokenKey, token);
    }

    return token;
  }

  static Future<void> registerDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyRegistered = prefs.getBool(_deviceRegisteredKey) ?? false;

    if (!alreadyRegistered) {
      final token = await getDeviceToken();
      const baseUrl = kDebugMode ? 'http://localhost:8788' : 'https://api.shedidthat.app';
      final url = Uri.parse('$baseUrl/register');
      print('[DeviceService] Attempting to register device at $url');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'deviceId': token}),
        );

        if (response.statusCode == 200) {
          await prefs.setBool(_deviceRegisteredKey, true);
          print('[DeviceService] Device registration successful.');
        } else {
          print('[DeviceService] Device registration failed with status: ${response.statusCode}');
          print('[DeviceService] Response body: ${response.body}');
        }
      } catch (e) {
        // Handle registration error, maybe retry later
        print('[DeviceService] Device registration failed with exception: $e');
      }
    }
  }
  static Future<void> clearRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceRegisteredKey);
    print('[DeviceService] Device registration cleared.');
  }

  static Future<bool> isDeviceRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_deviceRegisteredKey) ?? false;
  }

  static Future<void> markAsUnregistered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deviceRegisteredKey, false);
    print('[DeviceService] Marked device as unregistered.');
  }
}
