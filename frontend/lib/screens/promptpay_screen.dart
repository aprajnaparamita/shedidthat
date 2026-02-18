import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shedidthat/theme/app_colors.dart';

class PromptPayScreen extends StatelessWidget {
  const PromptPayScreen({super.key});

  Future<void> _saveImage(BuildContext context) async {
    try {
      final byteData = await rootBundle.load('assets/promptpay.jpeg');
      final bytes = byteData.buffer.asUint8List();
      String message = 'Saved';

      if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        // Use file_saver for desktop and web
        await FileSaver.instance.saveFile(
          name: 'promptpay_qr.jpeg',
          bytes: bytes,
          mimeType: MimeType.jpeg,
        );
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Use image_gallery_saver for mobile
        bool hasPermission = false;
        if (Platform.isAndroid) {
          hasPermission = await Permission.storage.request().isGranted;
        } else if (Platform.isIOS) {
          hasPermission = await Permission.photos.request().isGranted;
        }

        if (!hasPermission) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission is required.')),
            );
          }
          return;
        }

        final result = await ImageGallerySaver.saveImage(bytes);
        if (result['isSuccess']) {
          message = 'Saved to Camera Roll';
        } else {
          throw Exception('Failed to save to gallery');
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save QR Code: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Thai PromptPay'),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ),
            child: Transform.scale(
              scale: kIsWeb ? 0.75 : 1.0,
              child: Stack(
                children: [
                  Image.asset('assets/promptpay.jpeg'),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: ElevatedButton.icon(
                      onPressed: () => _saveImage(context),
                      icon: const Icon(Icons.download),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
              ),
            ),
          ),
    );
  }
}
