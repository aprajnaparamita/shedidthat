import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  static const String _baseUrl = 'https://she-absolutely-just-did-that-api.fly.dev';
  static const String _appSecret = 'REPLACE_WITH_YOUR_SECRET'; // TODO: Replace with your actual secret

  static Future<String> sendMessage(List<Message> messages, String deviceToken) async {
    final url = Uri.parse('$_baseUrl/chat');

    final body = jsonEncode({
      'messages': messages.map((m) => m.toJson()).toList(),
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-app-secret': _appSecret,
        'x-device-token': deviceToken,
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] as String;
    } else if (response.statusCode == 429) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Rate limit exceeded');
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Jess is having a moment — try again');
    }
  }
}
