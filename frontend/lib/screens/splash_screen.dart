import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shedidthat/screens/home_screen.dart';
import 'package:shedidthat/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
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
                    const Text(
                      'She Absolutely Just Did That',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDivider(),
                    const SizedBox(height: 24),
                    _buildInfoBubble(context),
                    const SizedBox(height: 24),
                    const Text(
                      '🔒 Your Privacy Matters',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All conversations are stored locally on your device only. No accounts. No cloud storage. No data collection. When you delete the app, everything goes with it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildGithubButton(),
                    const SizedBox(height: 16),
                    _buildRichText(
                      'Created by Janet Jeffus, a solo lesbian developer.\nLearn more: ',
                      'darabuilds.tech/dating',
                      'https://darabuilds.tech/dating',
                    ),
                    const SizedBox(height: 32),
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
              child: const Text(
                "Your situationship just did something unhinged and you need to debrief immediately. Jess is available. An AI best friend who's always awake, always invested, and has genuinely been waiting by the phone. Great questions. Zero judgment. Official ratings. She picked up on the first ring. Start talking.",
                textAlign: TextAlign.center,
                style: TextStyle(
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

  Widget _buildGithubButton() {
    return ElevatedButton.icon(
      onPressed: () => _launchURL('https://github.com/aprajnaparamita/shedidthat'),
      icon: SvgPicture.asset(
        'assets/GitHub_Lockup_Black_Clearspace.svg',
        height: 24,
      ),
      label: const Text('View on GitHub'),
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
          color: AppColors.tertiaryText,
          fontSize: 13,
        ),
        children: [
          TextSpan(text: text),
          TextSpan(
            text: linkText,
            style: const TextStyle(
              color: AppColors.accent,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = () => _launchURL(url),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Text(
          'Get Started',
          style: TextStyle(
            color: AppColors.buttonPrimaryText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class BubbleTailPainter extends CustomPainter {
  final Color color;

  BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(size.width / 2 - 10, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width / 2 + 10, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class NoGlowScrollBehavior extends ScrollBehavior {
  const NoGlowScrollBehavior();
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
