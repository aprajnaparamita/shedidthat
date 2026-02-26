import 'dart:async';
import 'dart:isolate';

import 'package:shedidthat/local_server/local_server.dart';

class LocalServerManager {
  static final LocalServerManager _instance = LocalServerManager._internal();
  factory LocalServerManager() => _instance;
  LocalServerManager._internal();

  Isolate? _serverIsolate;
  ReceivePort? _receivePort;

  Future<void> startServer({
    required String deepseekApiKey,
    required String googleApiKey,
  }) async {
    if (_serverIsolate != null) {
      print('[LocalServerManager] Server is already running.');
      return;
    }

    print('[LocalServerManager] Spawning server isolate...');
    final completer = Completer<void>();

    // Timeout after 10 seconds if the server doesn't confirm startup.
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.completeError('Server startup timed out after 10 seconds');
      }
    });

    _receivePort = ReceivePort();
    _serverIsolate = await Isolate.spawn(
      _serverEntryPoint,
      {
        'sendPort': _receivePort!.sendPort,
        'deepseekApiKey': deepseekApiKey,
        'googleApiKey': googleApiKey,
      },
    );

    _receivePort!.listen((message) {
      if (message == 'started') {
        print('[LocalServerManager] Received server started confirmation from isolate.');
        if (!completer.isCompleted) {
          completer.complete();
        }
      } else if (message is String && message.startsWith('error:')) {
        print('[LocalServerManager] Server isolate reported error: $message');
        if (!completer.isCompleted) {
          completer.completeError(message);
        }
      }
    });

    return completer.future;
  }

  void stopServer() {
    if (_serverIsolate != null) {
      print('[LocalServerManager] Stopping server isolate...');
      _serverIsolate!.kill(priority: Isolate.immediate);
      _serverIsolate = null;
    }
    if (_receivePort != null) {
      _receivePort!.close();
      _receivePort = null;
    }
  }
}

void _serverEntryPoint(Map<String, dynamic> message) {
  final sendPort = message['sendPort'] as SendPort;
  final deepseekApiKey = message['deepseekApiKey'] as String;
  final googleApiKey = message['googleApiKey'] as String;

  final server = LocalServer(
    deepseekApiKey: deepseekApiKey,
    googleApiKey: googleApiKey,
  );

  server.start();
  sendPort.send('started');
}
