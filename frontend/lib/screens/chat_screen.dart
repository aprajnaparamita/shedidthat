import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shedidthat/l10n/app_localizations.dart';
import '../models/message.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/chat_bubble.dart';
import 'package:shedidthat/screens/nag_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/jess_typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;

  const ChatScreen({super.key, this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<Message> _messages = [];
  String? _conversationId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    if (_conversationId != null) {
      _loadMessages();
    } else {
      // We need context for localization, so we delay this call.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startNewConversation();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _loadMessages() async {
    print('[ChatScreen] Loading conversation: $_conversationId');
    final messages = await _storageService.loadConversation(_conversationId!);
    setState(() {
      _messages = messages;
    });
    if (messages.isNotEmpty) {
      print('[ChatScreen] Loaded ${messages.length} messages.');
    } else {
      print('[ChatScreen] No previous messages found for this conversation.');
    }
    _scrollToBottom();
  }

  Future<void> _startNewConversation() async {
    final welcomeMessage = Message(
      role: 'assistant',
      content: AppLocalizations.of(context)!.chatScreenWelcomeMessage,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages = [welcomeMessage];
    });
  }

  Future<void> _saveConversation() async {
    if (_conversationId != null) {
      print('[ChatScreen] Saving ${_messages.length} messages to conversation: $_conversationId');
      await _storageService.saveConversation(_conversationId!, _messages);
    }
  }

  // New, simplified method to handle sending a message and streaming the response
  Future<void> _handleSendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    print('[ChatScreen] Handling message: "$text"');

    final userMessage = Message(role: 'user', content: text, timestamp: DateTime.now());
    final jessMessage = Message(role: 'assistant', content: '', timestamp: DateTime.now());

    setState(() {
      _isSending = true;
      _messages.add(userMessage);
      _messages.add(jessMessage); // Add empty bubble for Jess
    });

    _controller.clear();
    _scrollToBottom();

    // Save conversation early
    if (_conversationId == null) {
      _conversationId = await _storageService.newConversation();
    }
    // Save user message immediately
    await _saveConversation();

    try {
      final deviceId = await DeviceService.getDeviceToken();
      // Take the last 20 messages to send as context.
      final history = _messages.length > 20 ? _messages.sublist(_messages.length - 20) : _messages;
      print('[ChatScreen] Sending ${history.length} messages to API.');
      final stream = ApiService.chat(history, deviceId);

      // Listen to the stream and update the UI
      await for (final chunk in stream) {
        print('[ChatScreen] Stream chunk received: "$chunk"');
        setState(() {
          jessMessage.content += chunk;
        });
        _scrollToBottom();
      }

      print('[ChatScreen] Stream finished.');
      // After stream is complete, save the final message
      await _saveConversation();

      // Check if we should show the nag screen
      final prefs = await SharedPreferences.getInstance();
      final shouldShowNag = (prefs.getInt('requestCount') ?? 0) % 3 == 0;
      if (shouldShowNag && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const NagScreen()),
        );
      }

    } catch (e) {
      print('[ChatScreen] An error occurred during streaming: $e');
      setState(() {
        jessMessage.content = AppLocalizations.of(context)!.chatScreenErrorJessProblem;
      });
      // Save the error message
      await _saveConversation();
    } finally {
      setState(() {
        _isSending = false;
      });
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.chatScreenTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ChatBubble(message: _messages[index]);
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.chatScreenHintText,
              ),
              enabled: !_isSending,
              onSubmitted: (value) => _handleSendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isSending ? null : _handleSendMessage,
            color: _isSending ? AppColors.buttonSecondary : AppColors.accent,
          ),
        ],
      ),
    );
  }
}
