import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/device_service.dart';
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

      body: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              Widget headerImage;
              if (isMobile) {
                headerImage = Image.asset(
                  'assets/header.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                );
              } else {
                // For tablets/desktops, make it slightly larger
                final headerHeight = constraints.maxHeight * 0.45;
                headerImage = SizedBox(
                  height: headerHeight,
                  child: Image.asset(
                    'assets/header.png',
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                );
              }

              return Column(
                children: [
                  headerImage,
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () async {
                      await _storageService.clearAll();
                      await DeviceService.clearRegistration();
                      // Reload the state to reflect the changes
                      _loadConversations();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('App state cleared! Please restart the app.'),
                        ),
                      );
                    },
                    child: const Text('Reset State (Debug Only)'),
                  ),
                ),
              Expanded(
                child: _conversationIds.isEmpty
                    ? EmptyState(onButtonPressed: _startNewConversation)
                    : ListView.builder(
                        itemCount: _conversationIds.length,
                        itemBuilder: (context, index) {
                          final conversationId = _conversationIds[index];
                          return FutureBuilder<String>(
                            future: _storageService
                                .getConversationPreview(conversationId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
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
              ),
            ],
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
