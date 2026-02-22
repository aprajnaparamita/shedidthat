import 'package:flutter/material.dart';
import 'package:shedidthat/services/storage_service.dart';
import 'package:shedidthat/theme/app_colors.dart';

class GetTokenScreen extends StatefulWidget {
  const GetTokenScreen({super.key});

  @override
  State<GetTokenScreen> createState() => _GetTokenScreenState();
}

class _GetTokenScreenState extends State<GetTokenScreen> {
  final _storageService = StorageService();
  final _deepseekController = TextEditingController();
  final _googleController = TextEditingController();

  bool _deepseekValidated = false;
  bool _googleValidated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Local API Keys'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To run this app locally, you need to provide your own API keys from DeepSeek and Google Cloud.',
              style: TextStyle(color: AppColors.primaryText, fontSize: 16),
            ),
            const SizedBox(height: 24),
            // DeepSeek Section
            _buildKeySection(
              title: 'DeepSeek API Key',
              consoleUrl: 'https://platform.deepseek.com/api_keys',
              controller: _deepseekController,
              isValidated: _deepseekValidated,
              onTest: () {},
            ),
            const SizedBox(height: 24),
            // Google Cloud Section
            _buildKeySection(
              title: 'Google Cloud TTS API Key',
              consoleUrl: 'https://console.cloud.google.com/apis/credentials',
              controller: _googleController,
              isValidated: _googleValidated,
              onTest: () {},
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: (_deepseekValidated && _googleValidated) ? () {} : null,
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeySection({
    required String title,
    required String consoleUrl,
    required TextEditingController controller,
    required bool isValidated,
    required VoidCallback onTest,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextButton(onPressed: () {}, child: Text('Get key from console')),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Paste your API key here',
            suffixIcon: isValidated ? const Icon(Icons.check_circle, color: AppColors.success) : null,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: onTest, child: const Text('Test Key')),
      ],
    );
  }
}
