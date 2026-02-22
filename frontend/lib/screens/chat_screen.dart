
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shedidthat/l10n/app_localizations.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/chat_bubble.dart';
import 'package:shedidthat/screens/nag_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Message> _messages = [];
  String? _conversationId;
  bool _isSending = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    if (_conversationId != null) {
      _loadMessages();
    } else {
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
    _audioPlayer.dispose();
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

  Future<void> playSpeech(String speechPath) async {
    print('[ChatScreen] playSpeech called with path: $speechPath');
    if (_isMuted) {
      print('[ChatScreen] Audio is muted, not playing speech.');
      return;
    }
    try {
      final url = ApiService.getSpeechUrl(speechPath);
      print('[ChatScreen] Attempting to play audio from URL: $url');

      // Stop any currently playing audio before starting new playback.
      await _audioPlayer.stop();
      print('[ChatScreen] Previous audio stopped.');

      await _audioPlayer.setUrl(url);
      print('[ChatScreen] Audio URL set successfully.');

      _audioPlayer.play();
      print('[ChatScreen] Audio playback started.');
    } catch (e) {
      print('[ChatScreen] Error playing speech: $e');
      // Silent fail - never block UI
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    print('[ChatScreen] Handling message: "$text"');

    final userMessage = Message(role: 'user', content: text, timestamp: DateTime.now());
    final jessMessage = Message(role: 'assistant', content: '', timestamp: DateTime.now());

    setState(() {
      _isSending = true;
      _messages.add(userMessage);
      _messages.add(jessMessage);
    });

    _controller.clear();
    _scrollToBottom();

    if (_conversationId == null) {
      _conversationId = await _storageService.newConversation();
    }
    await _saveConversation();

    try {
      final deviceId = await DeviceService.getDeviceToken();
      final history = _messages.length > 20 ? _messages.sublist(_messages.length - 20) : _messages;
      print('[ChatScreen] Sending ${history.length} messages to API.');
      final stream = ApiService.chat(history, deviceId);

      String? speechUrl;

      String buffer = '';
    await for (final chunk in stream) {
      buffer += chunk;

      // Process buffer line by line
      int newlineIndex;
      while ((newlineIndex = buffer.indexOf('\n')) != -1) {
        final line = buffer.substring(0, newlineIndex).trim();
        buffer = buffer.substring(newlineIndex + 1);

        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data.isEmpty) continue;

          try {
            final decodedChunk = jsonDecode(data);

            if (decodedChunk['done'] == true) {
              speechUrl = decodedChunk['speechUrl'];
            } else if (decodedChunk['content'] != null) {
              setState(() {
                jessMessage.content += decodedChunk['content'];
              });
              _scrollToBottom();
            }
          } catch (e) {
            print('[ChatScreen] Could not decode stream data JSON: $data');
          }
        }
      }
    }

      print('[ChatScreen] Stream finished.');
      await _saveConversation();

      if (speechUrl != null) {
        await playSpeech(speechUrl);
      }

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
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 60.0), // Add padding to bottom
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
          _buildMuteButton(),
        ],
      ),
    );
  }

  Widget _buildMuteButton() {
    return Positioned(
      top: 8,
      right: 16,
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            setState(() => _isMuted = !_isMuted);
            if (_isMuted) {
              _audioPlayer.stop();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
          ),
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
