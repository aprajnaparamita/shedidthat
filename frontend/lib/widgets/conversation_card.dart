import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ConversationCard extends StatelessWidget {
  final String title;
  final String time;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ConversationCard({
    super.key,
    required this.title,
    required this.time,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(title),
      onDismissed: (direction) => onDelete(),
      background: Container(color: Colors.red),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: const VerticalDivider(
            color: AppColors.primary,
            thickness: 4,
          ),
          title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          subtitle: Text(time, style: Theme.of(context).textTheme.labelSmall),
          onTap: onTap,
        ),
      ),
    );
  }
}
