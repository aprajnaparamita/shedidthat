import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import 'device_service.dart';

class ApiService {
  static const String _baseUrl =
      kDebugMode ? 'http://localhost:8788' : 'https://api.shedidthat.app';
  static const String _appSecret = String.fromEnvironment('APP_SECRET');

  static Future<Map<String, dynamic>> sendMessage(
      List<Message> messages, String deviceToken) async {
    // Ensure the device is registered before sending a message.
    final isRegistered = await DeviceService.isDeviceRegistered();
    if (!isRegistered) {
      print('[ApiService] Device not registered. Attempting to register now.');
      await DeviceService.registerDevice();
    }

    final url = Uri.parse('$_baseUrl/chat');
    print('[ApiService] Sending message to $url');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-app-secret': _appSecret,
          'x-device-id': deviceToken,
        },
        body: jsonEncode({'messages': messages.map((m) => m.toJson()).toList()}),
      );

      print('[ApiService] Received response with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        int requestCount = (prefs.getInt('requestCount') ?? 0) + 1;
        await prefs.setInt('requestCount', requestCount);

        final body = jsonDecode(response.body);
        print('[ApiService] Successfully got reply: "${body['reply']}"');
        return {
          'reply': body['reply'],
          'shouldShowNag': requestCount % 3 == 0,
        };
      } else if (response.statusCode == 401) {
        // If unauthorized, the server doesn't recognize our device or secret.
        // Mark as unregistered to force re-registration on the next attempt.
        print('[ApiService] Unauthorized. Marking device as unregistered.');
        await DeviceService.markAsUnregistered();
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error'] ?? 'Authorization error';
        return {
          'reply': 'Jess is having a moment ($errorMessage) — try again',
          'shouldShowNag': false,
        };
      } else if (response.statusCode == 429) {
        print('[ApiService] Rate limit exceeded.');
        return {
          'reply': 'Easy there! Come back tomorrow with more stories.',
          'shouldShowNag': false,
        };
      } else {
        print('[ApiService] API returned an error: ${response.body}');
        return {
          'reply': 'Jess is having a moment — try again',
          'shouldShowNag': false,
        };
      }
    } catch (e) {
      print('[ApiService] Failed to send message with exception: $e');
      return {
        'reply': 'Jess is having a moment — try again',
        'shouldShowNag': false,
      };
    }
  }
}
