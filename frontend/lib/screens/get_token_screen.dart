import 'package:flutter/material.dart';
import 'package:shedidthat/l10n/app_localizations.dart';
import 'package:shedidthat/services/api_service.dart';
import 'package:shedidthat/services/device_service.dart';
import 'package:shedidthat/services/local_server_manager.dart';
import 'package:shedidthat/services/storage_service.dart';
import 'package:shedidthat/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home_screen.dart';

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
  bool _isTestingDeepseek = false;
  bool _isTestingGoogle = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  void _loadKeys() async {
    final deepseekKey = await _storageService.getDeepseekApiKey();
    final googleKey = await _storageService.getGoogleApiKey();
    if (deepseekKey != null) {
      _deepseekController.text = deepseekKey;
      setState(() {
        _deepseekValidated = true;
      });
    }
    if (googleKey != null) {
      _googleController.text = googleKey;
      setState(() {
        _googleValidated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.getTokenScreenTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.getTokenScreenExplanation,
              style: const TextStyle(color: AppColors.primaryText, fontSize: 16),
            ),
            const SizedBox(height: 24),
            // DeepSeek Section
            _buildKeySection(
              title: AppLocalizations.of(context)!.getTokenScreenDeepSeekTitle,
              consoleUrl: 'https://platform.deepseek.com/api_keys',
              controller: _deepseekController,
              isValidated: _deepseekValidated,
              isTesting: _isTestingDeepseek,
              onTest: _testDeepseekKey,
            ),
            const SizedBox(height: 24),
            // Google Cloud Section
            _buildKeySection(
              title: AppLocalizations.of(context)!.getTokenScreenGoogleTitle,
              consoleUrl: 'https://console.cloud.google.com/apis/credentials',
              controller: _googleController,
              isValidated: _googleValidated,
              isTesting: _isTestingGoogle,
              onTest: _testGoogleKey,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: (_deepseekValidated && _googleValidated) ? _saveAndProceed : null,
              child: Text(AppLocalizations.of(context)!.getStartedButton),
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
    required bool isTesting,
    required VoidCallback onTest,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextButton(onPressed: () => launchUrl(Uri.parse(consoleUrl)), child: Text(AppLocalizations.of(context)!.getTokenScreenConsoleButton)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.getTokenScreenHintText,
            suffixIcon: isValidated ? const Icon(Icons.check_circle, color: AppColors.success) : null,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: isTesting ? null : onTest,
          child: isTesting ? const CircularProgressIndicator() : Text(AppLocalizations.of(context)!.getTokenScreenTestButton),
        ),
      ],
    );
  }

  void _testDeepseekKey() async {
    setState(() {
      _isTestingDeepseek = true;
    });
    final success = await ApiService.validateDeepseekKey(_deepseekController.text);
    setState(() {
      _deepseekValidated = success;
      _isTestingDeepseek = false;
    });
  }

  void _testGoogleKey() async {
    setState(() {
      _isTestingGoogle = true;
    });
    final success = await ApiService.validateGoogleTtsKey(_googleController.text);
    setState(() {
      _googleValidated = success;
      _isTestingGoogle = false;
    });
  }

  void _saveAndProceed() async {
    await _storageService.saveApiKeys(
      deepseek: _deepseekController.text,
      google: _googleController.text,
    );

    // Start the local server now that we have keys (first-run path).
    // main.dart's startup block only runs when hasBeenRun is already true,
    // so we must start it here before setting that flag.
    await LocalServerManager().startServer(
      deepseekApiKey: _deepseekController.text,
      googleApiKey: _googleController.text,
    );
    await DeviceService.registerDevice();

    await _storageService.setHasBeenRunBefore(true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }
}
