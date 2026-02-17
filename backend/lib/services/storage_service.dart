import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';

/// All conversations live on-device only.
/// No database, no server storage, no cost.
/// Each API call sends the full local history — Claude's context window
/// handles the "memory". This is the whole trick.
class StorageService {
  static const String _idsKey = 'conversation_ids';
  static const _uuid = Uuid();

  /// Create a new conversation, returns its ID
  static Future<String> newConversation() async {
    final id = _uuid.v4();
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_idsKey) ?? [];
    ids.insert(0, id); // Most recent first
    await prefs.setStringList(_idsKey, ids);
    return id;
  }

  /// Save messages for a conversation (overwrites)
  static Future<void> saveConversation(String id, List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(messages.map((m) => m.toStorage()).toList());
    await prefs.setString('convo_$id', encoded);
  }

  /// Load messages for a conversation
  static Future<List<Message>> loadConversation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('convo_$id');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((m) => Message.fromStorage(m as Map<String, dynamic>)).toList();
  }

  /// Get all conversation IDs (most recent first)
  static Future<List<String>> getAllConversationIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_idsKey) ?? [];
  }

  /// Get preview of a conversation (first user message)
  static Future<String> getConversationPreview(String id) async {
    final messages = await loadConversation(id);
    final firstUserMsg = messages.firstWhere(
      (m) => m.role == 'user',
      orElse: () => Message(role: 'user', content: 'New debrief'),
    );
    final preview = firstUserMsg.content;
    return preview.length > 50 ? '${preview.substring(0, 50)}...' : preview;
  }

  /// Delete a conversation
  static Future<void> deleteConversation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('convo_$id');
    final ids = prefs.getStringList(_idsKey) ?? [];
    ids.remove(id);
    await prefs.setStringList(_idsKey, ids);
  }

  /// Clear all conversations
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_idsKey) ?? [];
    for (final id in ids) {
      await prefs.remove('convo_$id');
    }
    await prefs.remove(_idsKey);
  }
}
