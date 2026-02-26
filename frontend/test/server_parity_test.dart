import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shedidthat/local_server/local_server.dart';

import 'package:shedidthat/services/storage_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {

  late LocalServer localServer;
  final file = File('test/fixtures/server_test_cases.json');
  final testCases = jsonDecode(file.readAsStringSync()) as List<dynamic>;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    await storageService.setIsLocalModeForTest(true);
    localServer = LocalServer(deepseekApiKey: 'dummy', googleApiKey: 'dummy');
    await localServer.start();
  });

  tearDownAll(() {
    localServer.stop();
  });

  for (final testCase in testCases) {
    test(testCase['name'], () async {
      final request = testCase['request'];
      final url = Uri.parse('http://localhost:8788${request['path']}');

      if (request['method'] == 'POST') {
        final response = await http.post(
          url,
          headers: Map<String, String>.from(request['headers'] ?? {}),
          body: jsonEncode(request['body']),
        );

        if (testCase['expected_response'] != null) {
          print('Response body: ${response.body}');
          expect(response.statusCode, testCase['expected_response']['status']);
          expect(jsonDecode(response.body), testCase['expected_response']['body']);
        }

        if (testCase['expected_stream_chunks'] != null) {
          final client = http.Client();
          final requestStream = http.Request('POST', url)
            ..headers.addAll(Map<String, String>.from(request['headers'] ?? {}))
            ..body = jsonEncode(request['body']);
          final responseStream = await client.send(requestStream);

          final chunks = await responseStream.stream.transform(utf8.decoder).transform(const LineSplitter()).toList();
          int chunkIndex = 0;
          for (final line in chunks) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data == '[DONE]') {
                continue;
              }
              final json = jsonDecode(data);
              if (json['done'] != null) {
                expect(json['done'], testCase['expected_final_chunk']['done']);
                expect(json['speechUrl'], isNotNull);
              } else {
                expect(json, testCase['expected_stream_chunks'][chunkIndex]);
                chunkIndex++;
              }
            }
          }
        }
      }
    });
  }
}
