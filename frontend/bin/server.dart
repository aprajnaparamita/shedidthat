import 'dart:io';

import 'package:shedidthat/local_server/local_server.dart';

void main() async {
  final deepseekApiKey = Platform.environment['DEEPSEEK_API_KEY'];
  final googleApiKey = Platform.environment['GOOGLE_API_KEY'];

  if (deepseekApiKey == null || googleApiKey == null) {
    print('DEEPSEEK_API_KEY and GOOGLE_API_KEY must be set');
    exit(1);
  }

  final server = LocalServer(
    deepseekApiKey: deepseekApiKey,
    googleApiKey: googleApiKey,
  );
  await server.start();
  print('Server running on port 8789');
}