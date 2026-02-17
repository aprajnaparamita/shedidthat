import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class ApiService {
  static const String _baseUrl = kDebugMode ? 'http://127.0.0.1:8080' : 'https://api.shedidthat.app';
  static const String _appSecret = String.fromEnvironment('APP_SECRET');

  static Future<Map<String, dynamic>> sendMessage(List<Message> messages, String deviceToken) async {
    final url = Uri.parse('$_baseUrl/chat');
    print('[ApiService] Sending message to $url');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-app-secret': _appSecret,
          'x-device-token': deviceToken,
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
