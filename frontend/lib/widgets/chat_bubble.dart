import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser)
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text('J', style: TextStyle(color: Colors.white)),
          ),
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isUser ? AppColors.userBubbleGradient : null,
              color: isUser ? null : AppColors.jessBubble,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${message.timestamp.hour}:${message.timestamp.minute}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isUser ? Colors.white70 : Colors.black54,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
