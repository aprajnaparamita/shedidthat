import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';

class StorageService {
  static const _indexKey = 'conversation_index';

  Future<String> newConversation() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getStringList(_indexKey) ?? [];
    final newId = Uuid().v4();
    index.insert(0, newId);
    await prefs.setStringList(_indexKey, index);
    return newId;
  }

  Future<void> saveConversation(String id, List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = messages.map((m) => jsonEncode(m.toStorage())).toList();
    await prefs.setStringList(id, messagesJson);
  }

  Future<List<Message>> loadConversation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getStringList(id) ?? [];
    return messagesJson.map((m) => Message.fromStorage(jsonDecode(m))).toList();
  }

  Future<List<String>> getAllConversationIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_indexKey) ?? [];
  }

  Future<String> getConversationPreview(String id) async {
    final messages = await loadConversation(id);
    final firstUserMessage = messages.firstWhere((m) => m.role == 'user', orElse: () => Message(role: 'user', content: '', timestamp: DateTime.now()));
    if (firstUserMessage.content.length > 50) {
      return '${firstUserMessage.content.substring(0, 50)}...';
    }
    return firstUserMessage.content;
  }

  Future<void> deleteConversation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getStringList(_indexKey) ?? [];
    index.remove(id);
    await prefs.setStringList(_indexKey, index);
    await prefs.remove(id);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
