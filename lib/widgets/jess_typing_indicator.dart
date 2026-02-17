
import 'package:flutter/material.dart';

class JessTypingIndicator extends StatefulWidget {
  const JessTypingIndicator({super.key});

  @override
  State<JessTypingIndicator> createState() => _JessTypingIndicatorState();
}

class _JessTypingIndicatorState extends State<JessTypingIndicator> with SingleTickerProviderStateMixin {
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return ScaleTransition(
              scale: Tween(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: Interval(0.2 * index, 0.2 * index + 0.4, curve: Curves.easeInOut),
                ),
              ),
              child: const CircleAvatar(radius: 4, backgroundColor: Colors.grey),
            );
          }),
        ),
      ),
    );
  }
}
