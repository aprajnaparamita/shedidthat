import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

class LocalServer {
  HttpServer? _server;
  final Map<String, String> _deviceKv = {};
  final Map<String, List<int>> _speechCache = {};
  final Map<String, Map<String, dynamic>> _rateLimitKv = {};

  final String _appSecret = 'a-super-secret-key';
  final String _deepseekApiKey;
  final String _googleApiKey;

  LocalServer({
    required String deepseekApiKey,
    required String googleApiKey,
  })  : _deepseekApiKey = deepseekApiKey,
        _googleApiKey = googleApiKey;

  Future<void> start() async {
    final publicRouter = Router();
    publicRouter.get('/', (Request request) {
      return Response.ok('She Absolutely Just Did That - Local backend is running!');
    });
    publicRouter.post('/register', _handleRegister);

    final protectedRouter = Router();
    protectedRouter.get('/api/speech/<uuid>', _handleSpeechRequest);
    protectedRouter.post('/chat', _handleChat);

    final protectedHandler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_rateLimitMiddleware())
        .addMiddleware(_authMiddleware())
        .addHandler(protectedRouter);

    final cascade = Cascade().add(publicRouter).add(protectedHandler);

    _server = await io.serve(cascade.handler, '0.0.0.0', 8789);
    print('[LocalServer] Server started and listening on 0.0.0.0:8789');
  }

  void stop() {
    _server?.close();
  }

  Future<Response> _handleRegister(Request request) async {
    try {
      final body = await request.readAsString();
      final params = jsonDecode(body);
      final deviceId = params['deviceId'];

      if (deviceId == null || deviceId.isEmpty) {
        return Response.badRequest(body: jsonEncode({'error': 'Device ID is required.'}));
      }

      _deviceKv[deviceId] = 'registered';
      return Response.ok(jsonEncode({'status': 'ok'}));
    } catch (e) {
      return Response.internalServerError(body: 'An unexpected error occurred.');
    }
  }

  Middleware _rateLimitMiddleware() {
    return (innerHandler) {
      return (request) {
        final deviceId = request.headers['x-device-id'];
        if (deviceId == null) {
          return innerHandler(request);
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        final windowStart = now - (60 * 60 * 1000); // 1 hour window

        final record = _rateLimitKv[deviceId];
        if (record == null) {
          _rateLimitKv[deviceId] = {'count': 1, 'timestamp': now};
          return innerHandler(request);
        }

        if (record['timestamp'] < windowStart) {
          _rateLimitKv[deviceId] = {'count': 1, 'timestamp': now};
          return innerHandler(request);
        }

        if (record['count'] >= 100) {
          return Response(429, body: jsonEncode({'error': 'Too many requests.'}));
        }

        record['count']++;
        return innerHandler(request);
      };
    };
  }

  Future<Response> _handleSpeechRequest(Request request) async {
    final uuid = request.params['uuid'];
    if (uuid == null) {
      return Response.badRequest(body: 'Missing uuid');
    }

    for (int i = 0; i < 10; i++) {
      if (_speechCache.containsKey(uuid)) {
        final audio = _speechCache[uuid];
        _speechCache.remove(uuid);
        return Response.ok(audio, headers: {'Content-Type': 'audio/mpeg'});
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    return Response.notFound('Speech not found');
  }

  Future<Response> _handleChat(Request request) async {
    final deepseekApiKey = _deepseekApiKey;
    if (deepseekApiKey == null) {
      return Response.internalServerError(body: 'DeepSeek API key not found');
    }

    final body = await request.readAsString();
    final params = jsonDecode(body);
    final messageHistory = params['messageHistory'] as List<dynamic>;
    final lang = request.url.queryParameters['lang'] ?? 'en';

    final systemMessage = {
      'role': 'system',
      'content': _getPersona(lang),
    };

    final messages = [systemMessage, ...messageHistory];

    final deepseekRequest = http.Request('POST', Uri.parse('https://api.deepseek.com/chat/completions'));
    deepseekRequest.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $deepseekApiKey',
    });
    deepseekRequest.body = jsonEncode({
      'model': 'deepseek-chat',
      'messages': messages,
      'stream': true,
    });

    final responseStream = await deepseekRequest.send();

    final streamController = StreamController<List<int>>();
    String fullMessage = '';

    responseStream.stream.listen(
      (chunk) {
        final decoded = utf8.decode(chunk);
        final lines = decoded.split('\n').where((line) => line.isNotEmpty);

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              final speechUuid = const Uuid().v4();
              final doneMessage = {
                'done': true,
                'speechUrl': '/api/speech/$speechUuid',
              };
              streamController.add(utf8.encode('data: ${jsonEncode(doneMessage)}\n\n'));
              streamController.close();
              _handleTTS(fullMessage, speechUuid);
              return;
            }

            try {
              final json = jsonDecode(data);
              final content = json['choices'][0]['delta']['content'] as String?;
              if (content != null) {
                fullMessage += content;
                streamController.add(utf8.encode('data: ${jsonEncode({'content': content})}\n\n'));
              }
            } catch (e) {
              print('Error decoding stream chunk: $e');
            }
          }
        }
      },
      onDone: () {
        if (!streamController.isClosed) {
          streamController.close();
        }
      },
      onError: (error) {
        print('Stream error: $error');
        if (!streamController.isClosed) {
          streamController.close();
        }
      },
    );

    return Response.ok(
      streamController.stream,
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    );
  }

  Future<void> _handleTTS(String text, String uuid) async {
    final googleApiKey = _googleApiKey;
    if (googleApiKey == null) {
      print('Google API key not found');
      return;
    }

    final url = Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize?key=$googleApiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'input': {'text': text},
        'voice': {'languageCode': 'en-US', 'name': 'en-US-Studio-O'},
        'audioConfig': {'audioEncoding': 'MP3'},
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final audioContent = base64Decode(body['audioContent']);
      _speechCache[uuid] = audioContent;
      print('Speech cached for uuid: $uuid');
    } else {
      print('Error generating speech: ${response.body}');
    }
  }

  String _getPersona(String lang) {
    const personas = {
      'en': 'You are a helpful assistant.',
      'th': 'You are a helpful assistant who speaks Thai.',
    };
    return personas[lang] ?? personas['en']!;
  }

  Middleware _authMiddleware() {
    return (innerHandler) {
      return (request) {
        final secret = request.headers['x-app-secret'];
        final deviceId = request.headers['x-device-id'];

        if (secret != _appSecret) {
          return Response.forbidden(jsonEncode({'error': 'Nope.'}));
        }

        if (deviceId == null || deviceId.isEmpty) {
          return Response.badRequest(body: jsonEncode({'error': 'Device ID is required.'}));
        }

        if (!_deviceKv.containsKey(deviceId)) {
          return Response.forbidden(jsonEncode({'error': 'Device not registered.'}));
        }

        final updatedRequest = request.change(context: {
          ...request.context,
          'deviceId': deviceId,
        });

        return innerHandler(updatedRequest);
      };
    };
  }
}