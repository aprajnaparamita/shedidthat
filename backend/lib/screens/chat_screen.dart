
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/jess_typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() async {
    final messages = await StorageService.loadConversation(widget.conversationId);
    setState(() {
      _messages = messages;
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMessage = Message(role: 'user', content: text);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _error = null;
      _controller.clear();
    });

    await StorageService.saveConversation(widget.conversationId, _messages);

    try {
      final deviceToken = await DeviceService.getDeviceToken();
      final reply = await ApiService.sendMessage(_messages, deviceToken);
      final jessMessage = Message(role: 'assistant', content: reply);

      setState(() {
        _messages.add(jessMessage);
        _isLoading = false;
      });

      await StorageService.saveConversation(widget.conversationId, _messages);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debrief'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const JessTypingIndicator();
                }
                final message = _messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
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
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
