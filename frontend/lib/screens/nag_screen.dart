import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shedidthat/screens/bank_transfer_screen.dart';
import 'package:shedidthat/screens/promptpay_screen.dart';
import 'package:shedidthat/theme/app_colors.dart';

class NagScreen extends StatelessWidget {
  const NagScreen({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Can't launch URL, show error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground.withOpacity(0.95),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: constraints.maxHeight * 0.05),
                _buildPhotoWithBubble(context),
                SizedBox(height: constraints.maxHeight * 0.05),
                _buildDivider(),
                const SizedBox(height: 24),
                const Text(
                  'Support the Developer',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This app is free, open source, and built by one person late at night because Sappho would have wanted this.\n\nIf it made you smile, consider buying me a coffee. Every bit helps.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDivider(),
                const SizedBox(height: 24),
                _buildRevolutButton(context),
                const SizedBox(height: 16),
                _buildPromptPayButton(context),
                const SizedBox(height: 16),
                _buildBankTransferButton(context),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Not today? No worries. Jess isn\'t going anywhere.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.05),
              ],
            ),
          );
          }),
        ),
      ),
    );
  }

  Widget _buildPhotoWithBubble(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: Image.asset(
            'assets/janet.jpg',
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -10,
          right: -40,
          child: Transform.rotate(
            angle: -0.1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: _BubblePainter(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'You\'re amazing!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      width: 100,
      color: AppColors.accent.withOpacity(0.5),
    );
  }

  Widget _buildRevolutButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.buttonPrimaryText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      onPressed: () => _launchURL('https://revolut.me/janetbocr'),
      child: const Text('Send with Revolut', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildPromptPayButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.userBubbleBackground,
        foregroundColor: AppColors.primaryText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PromptPayScreen()),
        );
      },
      child: const Text('Send with Thai PromptPay', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildBankTransferButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.userBubbleBackground,
        foregroundColor: AppColors.primaryText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const BankTransferScreen()),
        );
      },
      child: const Text('Bank Transfer', style: TextStyle(fontSize: 16)),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16));

    final path = Path()..addRRect(rrect);

    // Draw shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.2), 4.0, true);

    // Draw bubble
    canvas.drawPath(path, paint);

    // Draw tail
    final tailPath = Path()
      ..moveTo(size.width * 0.3, size.height - 1)
      ..lineTo(size.width * 0.2, size.height + 10)
      ..lineTo(size.width * 0.5, size.height - 1)
      ..close();

    canvas.drawPath(tailPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
