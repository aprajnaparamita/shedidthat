import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            gradient: AppColors.userBubbleGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              color: AppColors.userBubbleText,
            ),
          ),
        ),
      );
    }

    // Jess's bubble with avatar
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/jess.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.jessBubbleBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.jessBubbleBorder, width: 1),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: AppColors.jessBubbleText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
