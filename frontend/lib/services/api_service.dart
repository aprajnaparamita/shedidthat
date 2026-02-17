import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  static const String _baseUrl = kDebugMode ? 'http://127.0.0.1:8080' : 'https://api.shedidthat.app';
  static const String _appSecret = String.fromEnvironment('APP_SECRET');

  static Future<String> sendMessage(List<Message> messages, String deviceToken) async {
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
        final body = jsonDecode(response.body);
        print('[ApiService] Successfully got reply: "${body['reply']}"');
        return body['reply'];
      } else if (response.statusCode == 429) {
        print('[ApiService] Rate limit exceeded.');
        return 'Easy there! Come back tomorrow with more stories.';
      } else {
        print('[ApiService] API returned an error: ${response.body}');
        return 'Jess is having a moment — try again';
      }
    } catch (e) {
      print('[ApiService] Failed to send message with exception: $e');
      return 'Jess is having a moment — try again';
    }
  }
}
