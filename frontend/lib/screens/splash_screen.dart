import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shedidthat/l10n/app_localizations.dart';
import 'package:shedidthat/l10n/app_localizations.dart';
import 'package:shedidthat/screens/get_token_screen.dart';
import 'package:shedidthat/screens/home_screen.dart';
import 'package:shedidthat/services/device_service.dart';
import 'package:shedidthat/services/storage_service.dart';
import 'package:shedidthat/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shedidthat/services/local_server_manager.dart';

// Top-level class definition
class NoGlowScrollBehavior extends ScrollBehavior {
  const NoGlowScrollBehavior();
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();
  bool _isLoading = false;
  bool _isLocalMode = false;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Widget _buildLocalModeToggle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(AppLocalizations.of(context)!.runLocally, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Switch(
          value: _isLocalMode,
          onChanged: (value) {
                    setState(() {
                      _isLocalMode = value;
                    });
                    _storageService.saveIsLocalMode(value);
                    if (!value) {
                      _storageService.clearApiKeys();
                    }
                  },
        ),
      ],
    );
  }



  void _loadInitialState() async {
    final isLocal = await _storageService.getIsLocalMode();
    if (mounted) {
      setState(() {
        _isLocalMode = isLocal;
      });
    }
  }


  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _getStarted() async {
    if (_isLocalMode) {
      final deepseekKey = await _storageService.getDeepseekApiKey();
      final googleKey = await _storageService.getGoogleApiKey();
      if (deepseekKey == null || googleKey == null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const GetTokenScreen()),
          );
        }
        return; // Stop execution if we navigate to token screen
      }
    } else {
      // For production mode, register the device before proceeding.
      await DeviceService.registerDevice();
    }

    // If all checks pass, navigate to home screen
    if (mounted) {
      await _storageService.setHasBeenRunBefore(true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _isLoading ? AppColors.accentDark : AppColors.accent,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: _isLoading
          ? null
          : () async {
              setState(() {
                _isLoading = true;
              });
              try {
                await _getStarted();
              } catch (e) {
                print("Get Started failed: $e");
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
      child: _isLoading
          ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : Text(
              AppLocalizations.of(context)!.getStartedButton,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0522),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D0838), Color(0xFF1A0522)],
          ),
        ),
        child: SafeArea(
          child: ScrollConfiguration(
            behavior: const NoGlowScrollBehavior(),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    if (isTablet) const SizedBox(height: 60),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: LayoutBuilder(builder: (context, constraints) {
                        return Image.asset(
                          'assets/header.png',
                          width: double.infinity,
                          height: 200, // Set a fixed height
                          fit: BoxFit.contain,
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    AutoSizeText(
                      AppLocalizations.of(context)!.splashTitle,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                      maxLines: 1,
                      minFontSize: 18,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _buildDivider(),
                    const SizedBox(height: 24),
                    _buildInfoBubble(context),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.privacyTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.privacyText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildGithubButton(context),
                    const SizedBox(height: 16),
                    _buildRichText(
                      AppLocalizations.of(context)!.createdByText,
                      'darabuilds.tech/dating',
                      'https://darabuilds.tech/dating',
                    ),
                    const SizedBox(height: 24),
                    _buildLocalModeToggle(context),
                    const SizedBox(height: 24),
                    _buildGetStartedButton(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBubble(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.jessBubbleBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppLocalizations.of(context)!.splashBubbleText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.splashBubbleText,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(
              width: 20,
              height: 10,
              child: CustomPaint(
                painter: BubbleTailPainter(color: AppColors.jessBubbleBackground),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 250),
        height: 1,
        color: const Color(0xFF5A3F63),
      ),
    );
  }

  Widget _buildGithubButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _launchURL('https://github.com/aprajnaparamita/shedidthat'),
      icon: SvgPicture.asset(
        'assets/GitHub_Lockup_Black_Clearspace.svg',
        height: 24,
      ),
      label: Text(AppLocalizations.of(context)!.githubButton),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildRichText(String text, String linkText, String url) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 14,
        ),
        children: <TextSpan>[
          TextSpan(text: text),
          TextSpan(
            text: linkText,
            style: const TextStyle(color: AppColors.accent, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()..onTap = () => _launchURL(url),
          ),
        ],
      ),
    );
  }


}

class BubbleTailPainter extends CustomPainter {
  final Color color;

  BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2 - 10, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width / 2 + 10, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
