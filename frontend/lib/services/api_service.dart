import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import 'api_exceptions.dart';
import 'device_service.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment('API_URI', defaultValue: 'https://api.shedidthat.app');
  static const String _appSecret = String.fromEnvironment('APP_SECRET');

  static Future<Map<String, dynamic>> sendMessage(
      List<Message> messages, String deviceToken) async {
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
        await DeviceService.markAsUnregistered();
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error'] ?? 'Authorization error';
        throw RegistrationException(errorMessage);
      } else if (response.statusCode == 429) {
        throw RateLimitException('Easy there! Come back tomorrow with more stories.');
      } else {
        throw NetworkException('API returned an error: ${response.body}');
      }
    } on SocketException catch (e) {
      print('[ApiService] Failed to send message with SocketException: $e');
      throw NetworkException('Please check your network connection.');
    } catch (e) {
      print('[ApiService] Failed to send message with exception: $e');
      throw NetworkException('An unexpected error occurred.');
    }
  }
}
