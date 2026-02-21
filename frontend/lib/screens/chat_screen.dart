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
  bool _isJessTyping = false;
  bool _isSending = false;

  // New state for retry logic
  String? _uiMessage;

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
    final messages = await _storageService.loadConversation(_conversationId!);
    setState(() {
      _messages = messages;
    });
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

  // Main method to handle sending a message
  Future<void> _handleSendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMessage = Message(role: 'user', content: text, timestamp: DateTime.now());

    setState(() {
      _isSending = true;
      _uiMessage = null; // Clear previous messages
      _messages.add(userMessage);
    });

    _controller.clear();
    _scrollToBottom();

    // Save conversation early
    if (_conversationId == null) {
      _conversationId = await _storageService.newConversation();
    }
    await _storageService.saveConversation(_conversationId!, _messages);

    try {
      await _trySendMessageWithRetries(userMessage);
    } finally {
      setState(() {
        _isSending = false;
      });
      _focusNode.requestFocus();
    }
  }

  // Recursive method to handle retries
  Future<void> _trySendMessageWithRetries(Message userMessage, {int attempt = 1}) async {
    setState(() {
      _isJessTyping = true;
    });

    try {
      final deviceToken = await DeviceService.getDeviceToken();
      final response = await ApiService.sendMessage(_messages, deviceToken);
      final reply = response['reply'];
      final shouldShowNag = response['shouldShowNag'] ?? false;

      final jessMessage = Message(role: 'assistant', content: reply, timestamp: DateTime.now());

      setState(() {
        _messages.add(jessMessage);
        _isJessTyping = false;
        _uiMessage = null; // Clear any messages
      });

      await _storageService.saveConversation(_conversationId!, _messages);
      _scrollToBottom();

      if (shouldShowNag && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const NagScreen()),
        );
      }
    } on RegistrationException catch (e) {
      print('[ChatScreen] Attempt $attempt failed with RegistrationException: $e');
      await _handleRetry(userMessage, attempt, e);
    } on NetworkException catch (e) {
      print('[ChatScreen] Attempt $attempt failed with NetworkException: $e');
      await _handleRetry(userMessage, attempt, e);
    } on RateLimitException catch (e) {
      final errorMessage = Message(role: 'assistant', content: e.message, timestamp: DateTime.now());
      setState(() {
        _messages.add(errorMessage);
        _isJessTyping = false;
      });
    } catch (e) {
      print('[ChatScreen] An unexpected error occurred: $e');
      final errorMessage = Message(role: 'assistant', content: AppLocalizations.of(context)!.chatScreenErrorUnexpected, timestamp: DateTime.now());
      setState(() {
        _messages.add(errorMessage);
        _isJessTyping = false;
      });
    }
  }

  Future<void> _handleRetry(Message userMessage, int attempt, Exception e) async {
    if (attempt == 1) {
      // First failure: silent retry
      print('[ChatScreen] Silently attempting to re-register and retry.');
      await DeviceService.registerDevice();
      await _trySendMessageWithRetries(userMessage, attempt: 2);
    } else if (attempt == 2) {
      // Second failure: show message and wait
      print('[ChatScreen] Second attempt failed. Waiting 3 seconds.');
      setState(() {
        _uiMessage = AppLocalizations.of(context)!.chatScreenErrorRetryInProgress;
      });
      await Future.delayed(const Duration(seconds: 3));
      await DeviceService.registerDevice();
      await _trySendMessageWithRetries(userMessage, attempt: 3);
    } else {
      // Third failure: give up
      print('[ChatScreen] Final attempt failed. Showing error to user.');
      setState(() {
        _uiMessage = AppLocalizations.of(context)!.chatScreenErrorJessProblem;
        _isJessTyping = false;
      });
      // After a delay, clear the error to allow the user to try again
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _uiMessage = null;
          });
        }
      });
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
                itemCount: _messages.length + (_isJessTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isJessTyping && index == _messages.length) {
                    return const JessTypingIndicator();
                  }
                  return ChatBubble(message: _messages[index]);
                },
              ),
            ),
            if (_uiMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  _uiMessage!,
                  style: const TextStyle(color: AppColors.secondaryText),
                  textAlign: TextAlign.center,
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
              enabled: !_isSending && !_isJessTyping,
              onSubmitted: (value) => _handleSendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isSending || _isJessTyping ? null : _handleSendMessage,
            color: _isSending ? AppColors.buttonSecondary : AppColors.accent,
          ),
        ],
      ),
    );
  }
}
