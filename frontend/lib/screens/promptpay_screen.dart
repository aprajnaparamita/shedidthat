import 'dart:io';

import 'package:file_picker/file_picker.dart';
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

      print('[_saveImage] Attempting to save QR code...');

      if (Platform.isMacOS) {
        // Use file_picker for macOS
        print('[_saveImage] Using file_picker for macOS. A save dialog should appear.');
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: 'promptpay_qr.jpeg',
        );

        if (outputFile != null) {
          File file = File(outputFile);
          await file.writeAsBytes(bytes);
          message = 'Saved file to $outputFile';
          print('[_saveImage] File saved to: $outputFile');
        } else {
          message = 'Save cancelled';
          print('[_saveImage] User canceled the save dialog.');
        }
      } else if (kIsWeb || Platform.isWindows || Platform.isLinux) {
        // Use file_saver for desktop and web
        print('[_saveImage] Using file_saver for desktop/web. A save dialog should appear.');
        String? filePath = await FileSaver.instance.saveFile(
          name: 'promptpay_qr.jpeg',
          bytes: bytes,
          mimeType: MimeType.jpeg,
        );
        message = filePath != null ? 'Saved file to Downloads' : 'Save cancelled';
        print('[_saveImage] file_saver process completed. Path: $filePath');
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Use image_gallery_saver for mobile
        print('[_saveImage] Using image_gallery_saver for mobile.');
        bool hasPermission = false;
        if (Platform.isAndroid) {
          hasPermission = await Permission.storage.request().isGranted;
        } else if (Platform.isIOS) {
          hasPermission = await Permission.photos.request().isGranted;
        }

        if (!hasPermission) {
          message = 'Storage permission is required.';
          print('[_saveImage] Permission denied.');
        } else {
          final result = await ImageGallerySaver.saveImage(bytes);
          if (result['isSuccess']) {
            message = 'Saved to Photos';
            final filePath = result['filePath'];
            print('[_saveImage] Successfully saved to Photos. Path: $filePath');
          } else {
            throw Exception('Failed to save to gallery');
          }
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      print('[_saveImage] Error: ${e.toString()}');
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
