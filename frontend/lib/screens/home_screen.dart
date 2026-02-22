import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shedidthat/services/api_service.dart';
import 'package:shedidthat/theme/app_colors.dart';
import 'package:shedidthat/screens/nag_screen.dart';
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
  bool _isLoading = false;

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

  void _startNewConversation() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: null),
      ),
    ).then((_) {
      _loadConversations();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
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
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await _storageService.clearAll();
                              _loadConversations();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('App state cleared! Please restart the app.'),
                                ),
                              );
                            },
                            child: const Text('Reset State (Debug Only)'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const NagScreen()),
                              );
                            },
                            child: const Text('Show Nag Screen (Debug Only)'),
                          ),
                          TextButton(
                            onPressed: () {
                              throw Exception('This is a Sentry test exception from the client.');
                            },
                            child: const Text('Sentry Client Error (Debug Only)'),
                          ),
                          TextButton(
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sending server error request...'),
                                ),
                              );
                              await ApiService.triggerSentryTest();
                            },
                            child: const Text('Sentry Server Error (Debug Only)'),
                          ),
                        ],
                      ),
                    ),
              Expanded(
                child: Stack(
                  children: [
                    _conversationIds.isEmpty
                        ? EmptyState(
                            onButtonPressed: _startNewConversation,
                            isLoading: _isLoading,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 80), // Add padding to avoid overlap
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
                    Positioned(
                      top: 16,
                      left: 16,
                      child: FloatingActionButton(
                        onPressed: _isLoading ? null : _startNewConversation,
                        backgroundColor: _isLoading
                            ? AppColors.buttonSecondary
                            : AppColors.accent,
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
