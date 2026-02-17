import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/jess_typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;

  const ChatScreen({super.key, this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final StorageService _storageService = StorageService();
  final DeviceService _deviceService = DeviceService();
  final TextEditingController _controller = TextEditingController();
  List<Message> _messages = [];
  String? _conversationId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    if (_conversationId != null) {
      _loadMessages();
    } else {
      _startNewConversation();
    }
  }

  Future<void> _loadMessages() async {
    final messages = await _storageService.loadConversation(_conversationId!);
    setState(() {
      _messages = messages;
    });
  }

  Future<void> _startNewConversation() async {
    // Don't create an ID or save until the first message is sent.
    final welcomeMessage = Message(
      role: 'assistant',
      content:
          "Hey bestie! So glad you're here. What's on your mind?",
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages = [welcomeMessage];
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    final userMessage = Message(role: 'user', content: text, timestamp: DateTime.now());

    // If this is the first message, create the conversation now.
    if (_conversationId == null) {
      _conversationId = await _storageService.newConversation();
    }

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    await _storageService.saveConversation(_conversationId!, _messages);

    final deviceToken = await DeviceService.getDeviceToken();
    if (deviceToken == null) {
      // TODO: Handle device registration error
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final reply = await ApiService.sendMessage(_messages, deviceToken);

    final jessMessage = Message(role: 'assistant', content: reply, timestamp: DateTime.now());

    setState(() {
      _messages.add(jessMessage);
      _isLoading = false;
    });

    await _storageService.saveConversation(_conversationId!, _messages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
                  backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Debrief'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const JessTypingIndicator();
                }
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
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
              decoration: const InputDecoration(
                hintText: 'Spill the tea...',
              ),
              enabled: !_isLoading,
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isLoading ? null : () => _sendMessage(),
          ),
        ],
      ),
    );
  }
}
