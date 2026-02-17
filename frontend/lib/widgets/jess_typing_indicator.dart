import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class JessTypingIndicator extends StatefulWidget {
  const JessTypingIndicator({super.key});

  @override
  State<JessTypingIndicator> createState() => _JessTypingIndicatorState();
}

class _JessTypingIndicatorState extends State<JessTypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
            child: Image.asset(
              'assets/jess.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.jessBubbleBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: List.generate(3, (index) {
              return ScaleTransition(
                scale: _controller.drive(
                  Tween(begin: 0.5, end: 1.0).chain(
                    CurveTween(curve: Interval(0.2 * index, 0.2 * index + 0.4, curve: Curves.easeInOut)),
                  ),
                ),
                child: const Icon(Icons.circle, size: 8, color: Colors.grey),
              );
            }),
          ),
        ),
      ],
    );
  }
}
