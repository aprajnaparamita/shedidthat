
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/conversation_card.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<String>> _conversationIds;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    setState(() {
      _conversationIds = StorageService.getAllConversationIds();
    });
  }

  void _startNewConversation() async {
    final newId = await StorageService.newConversation();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ChatScreen(conversationId: newId)),
    ).then((_) => _loadConversations());
  }

  void _deleteConversation(String id) async {
    await StorageService.deleteConversation(id);
    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('She Absolutely Just Did That', style: Theme.of(context).appBarTheme.titleTextStyle),
      ),
      body: FutureBuilder<List<String>>(
        future: _conversationIds,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No debriefs yet. What are you waiting for?', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startNewConversation,
                    child: const Text('Start a New Debrief'),
                  ),
                ],
              ),
            );
          }

          final ids = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: ids.length,
            itemBuilder: (context, index) {
              final id = ids[index];
              return ConversationCard(
                conversationId: id,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ChatScreen(conversationId: id)),
                  ).then((_) => _loadConversations());
                },
                onDelete: () => _deleteConversation(id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewConversation,
        child: const Icon(Icons.add),
      ),
    );
  }
}
