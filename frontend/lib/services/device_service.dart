import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const String _prodBaseUrl = 'https://app.shedidthat.app';
  static const String _devIp = String.fromEnvironment('DEV_IP', defaultValue: '127.0.0.1');
  static final String _localBaseUrl = 'http://$_devIp:8788';

  static String get _baseUrl => kDebugMode ? _localBaseUrl : _prodBaseUrl;

  static const String _deviceIdKey = 'deviceId';
  static const String _isRegisteredKey = 'isDeviceRegistered';

  static Future<String> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
      print('[DeviceService] New device ID generated: $deviceId');
    }
    return deviceId;
  }

  static Future<bool> isDeviceRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isRegisteredKey) ?? false;
  }

  static Future<void> markAsRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isRegisteredKey, true);
  }

  static Future<void> markAsUnregistered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isRegisteredKey, false);
  }

  static Future<bool> registerDevice() async {
    final deviceId = await getDeviceToken();
    final url = Uri.parse('$_baseUrl/register');
    print('[DeviceService] Attempting to register device at `$url`');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': deviceId}),
      );

      if (response.statusCode == 200) {
        await markAsRegistered();
        print('[DeviceService] Device registered successfully.');
        return true;
      } else {
        print('[DeviceService] Device registration failed with status: ${response.statusCode}, body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[DeviceService] Device registration failed with exception: $e');
      return false;
    }
  }
}
