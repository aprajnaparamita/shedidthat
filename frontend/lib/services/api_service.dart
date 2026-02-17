import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  static const String _baseUrl = kDebugMode ? 'http://localhost:8080' : 'https://api.shedidthat.app';
  static const String _appSecret = 'REPLACE_WITH_YOUR_SECRET'; // TODO: Replace with your actual secret

  static Future<String> sendMessage(List<Message> messages, String deviceToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'x-app-secret': _appSecret,
          'x-device-token': deviceToken,
        },
        body: jsonEncode({'messages': messages.map((m) => m.toJson()).toList()}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['reply'];
      } else if (response.statusCode == 429) {
        return 'Easy there! Come back tomorrow with more stories.';
      } else {
        return 'Jess is having a moment — try again';
      }
    } catch (e) {
      return 'Jess is having a moment — try again';
    }
  }
}
