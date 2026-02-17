import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/conversation_card.dart';
import '../widgets/empty_state.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<String> _conversationIds = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final ids = await _storageService.getAllConversationIds();
    setState(() {
      _conversationIds = ids;
    });
  }

  void _startNewConversation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: null),
      ),
    ).then((_) => _loadConversations());
  }

  void _openConversation(String conversationId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: conversationId),
      ),
    ).then((_) => _loadConversations());
  }

  Future<void> _deleteConversation(String conversationId) async {
    await _storageService.deleteConversation(conversationId);
    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('She Absolutely Just Did That'),
      ),
      body: _conversationIds.isEmpty
          ? EmptyState(onButtonPressed: _startNewConversation)
          : ListView.builder(
              itemCount: _conversationIds.length,
              itemBuilder: (context, index) {
                final conversationId = _conversationIds[index];
                return FutureBuilder<String>(
                  future: _storageService.getConversationPreview(conversationId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ConversationCard(
                      title: snapshot.data ?? '',
                      time: 'just now', // Replace with actual time logic
                      onTap: () => _openConversation(conversationId),
                      onDelete: () => _deleteConversation(conversationId),
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
