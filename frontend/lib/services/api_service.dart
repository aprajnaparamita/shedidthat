import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shedidthat/services/api_exceptions.dart';
import 'package:shedidthat/services/device_service.dart';
import 'package:shedidthat/services/storage_service.dart';

import '../models/message.dart';

class ApiService {
  static final StorageService _storageService = StorageService();

  static const String _prodBaseUrl = 'https://api.shedidthat.app';
  static const String _localBaseUrl = 'http://127.0.0.1:8789';
  static const String _devIp = String.fromEnvironment('DEV_IP', defaultValue: '127.0.0.1');
  static final String _wranglerBaseUrl = 'http://$_devIp:8788';

  /// Returns the base URL for all API calls.
  /// - Local mode (user toggle)  → http://127.0.0.1:8789  (local Dart server, loopback)
  /// - Non-local + debug build   → http://<DEV_IP>:8788    (wrangler, set DEV_IP at run time)
  /// - Non-local + release / web → https://api.shedidthat.app (production)
  static Future<String> getBaseUrl() async {
    final isLocalMode = await _storageService.getIsLocalMode();
    if (isLocalMode) return _localBaseUrl;
    if (kDebugMode) return _wranglerBaseUrl;
    return _prodBaseUrl;
  }

  // In local mode the server uses a hardcoded secret (see local_server.dart).
  // In production the secret must be supplied via --dart-define=APP_SECRET=...
  static const String _localSecret = 'a-super-secret-key';
  static const String _prodSecret = String.fromEnvironment('APP_SECRET');

  static Future<String> _getAppSecret() async {
    final isLocalMode = await _storageService.getIsLocalMode();
    return isLocalMode ? _localSecret : _prodSecret;
  }

  static Future<String> getSpeechUrl(String speechPath) async {
    final baseUrl = await getBaseUrl();
    // The speechPath already contains the leading slash.
    return '$baseUrl$speechPath';
  }

  static Future<void> triggerSentryTest() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/sentrytest');
    final deviceId = await DeviceService.getDeviceToken();

    final appSecret = await _getAppSecret();
    if (appSecret.isEmpty) {
      print('APP_SECRET environment variable not set. Cannot trigger server error.');
      return;
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-device-id': deviceId,
          'x-app-secret': appSecret,
        },
      );

      if (response.statusCode >= 400) {
        print('Sentry test endpoint returned status ${response.statusCode}');
      } else {
        print('Sentry test endpoint returned status ${response.statusCode}. Expected an error.');
      }
    } catch (e) {
      print('Sentry test call failed: $e');
    }
  }

  static Future<bool> validateDeepseekKey(String key) async {
    final url = Uri.parse('https://api.deepseek.com/v1/models');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $key'},
    );
    return response.statusCode == 200;
  }

  static Future<bool> validateGoogleTtsKey(String key) async {
    final url = Uri.parse('https://texttospeech.googleapis.com/v1/voices');
    final response = await http.get(
      url,
      headers: {'X-Goog-Api-Key': key},
    );
    return response.statusCode == 200;
  }

  static Stream<String> chat(List<Message> messages, String deviceToken) async* {
    String lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('lang')) {
        lang = uri.queryParameters['lang']!;
        print('[ApiService] Overriding language with lang=$lang from URL');
      }
    }

    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/chat?lang=$lang');
    print('[ApiService] Sending chat request to $url');

    final client = http.Client();
    try {
      final request = http.Request('POST', url);
      print('[ApiService] Using device ID for chat header: "$deviceToken"');
      final appSecret = await _getAppSecret();
      request.headers.addAll({
        'Content-Type': 'application/json',
        'x-app-secret': appSecret,
        'x-device-id': deviceToken,
      });
      request.body = jsonEncode({'messages': messages.map((m) => m.toJson()).toList()});

      final response = await client.send(request);

      if (response.statusCode == 200) {
        print('[ApiService] Received successful chat response stream.');
        final prefs = await SharedPreferences.getInstance();
        int requestCount = (prefs.getInt('requestCount') ?? 0) + 1;
        await prefs.setInt('requestCount', requestCount);

        await for (var chunk in response.stream.transform(utf8.decoder)) {
          print('[ApiService] Received chunk: $chunk');
          yield chunk;
        }
        print('[ApiService] Finished receiving chat stream.');
      } else if (response.statusCode == 401) {
        await DeviceService.markAsUnregistered();
        final errorBody = await response.stream.bytesToString();
        final decodedBody = jsonDecode(errorBody);
        final errorMessage = decodedBody['error'] ?? 'Authorization error';
        print('[ApiService] Authorization error: $errorMessage');
        throw RegistrationException(errorMessage);
      } else if (response.statusCode == 429) {
        print('[ApiService] Rate limit exceeded.');
        throw RateLimitException('Easy there! Come back tomorrow with more stories.');
      } else {
        final errorBody = await response.stream.bytesToString();
        print('[ApiService] API Error: Status ${response.statusCode}, Body: $errorBody');
        throw NetworkException('API returned an error: $errorBody');
      }
    } on SocketException catch (e) {
      print('[ApiService] Network connection error: $e');
      throw NetworkException('Please check your network connection.');
    } catch (e) {
      print('[ApiService] An unexpected exception occurred during the chat request: $e');
      if (e is! NetworkException && e is! RegistrationException && e is! RateLimitException) {
        throw NetworkException('An unexpected error occurred.');
      }
      rethrow;
    } finally {
      client.close();
    }
  }
}
