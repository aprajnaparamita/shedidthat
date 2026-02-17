
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ConversationCard extends StatelessWidget {
  final String conversationId;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ConversationCard({super.key, 
    required this.conversationId,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(conversationId),
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: ListTile(
          title: FutureBuilder<String>(
            future: StorageService.getConversationPreview(conversationId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Loading...');
              }
              return Text(
                snapshot.data ?? 'Empty conversation',
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
