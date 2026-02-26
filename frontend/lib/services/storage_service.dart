import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/message.dart';

class StorageService {
  static const String _isLocalModeKey = 'isLocalMode';
  static const String _deepseekApiKey = 'DEEPSEEK_API_TOKEN';
  static const String _googleApiKey = 'GOOGLE_TEXT_API_KEY';
  static const String _hasBeenRunBeforeKey = 'hasBeenRunBefore';

  Future<bool> getHasBeenRunBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasBeenRunBeforeKey) ?? false;
  }

  Future<void> setHasBeenRunBefore(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasBeenRunBeforeKey, value);
  }

  Future<void> saveIsLocalMode(bool isLocalMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLocalModeKey, isLocalMode);
  }

  Future<void> setIsLocalModeForTest(bool isLocalMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLocalModeKey, isLocalMode);
  }

  Future<bool> getIsLocalMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLocalModeKey) ?? false;
  }

  Future<void> saveApiKeys({
    String? deepseek,
    String? google,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (deepseek != null) {
      await prefs.setString(_deepseekApiKey, deepseek);
    }
    if (google != null) {
      await prefs.setString(_googleApiKey, google);
    }
  }

  Future<String?> getDeepseekApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deepseekApiKey);
  }

  Future<String?> getGoogleApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_googleApiKey);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> clearApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deepseekApiKey);
    await prefs.remove(_googleApiKey);
  }

  // Conversation Management

  static const _conversationIdsKey = 'conversation_ids';
  static const _uuid = Uuid();

  Future<String> newConversation() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_conversationIdsKey) ?? [];
    final newId = _uuid.v4();
    await prefs.setStringList(_conversationIdsKey, [newId, ...ids]);
    return newId;
  }

  Future<List<String>> getAllConversationIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_conversationIdsKey) ?? [];
  }

  Future<String> getConversationPreview(String id) async {
    final messages = await loadConversation(id);
    if (messages.isEmpty) return 'Empty conversation';
    return messages.first.content;
  }

  Future<void> deleteConversation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_conversationIdsKey) ?? [];
    ids.remove(id);
    await prefs.setStringList(_conversationIdsKey, ids);
    await prefs.remove('convo_$id');
  }

  Future<List<Message>> loadConversation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('convo_$id');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((m) => Message.fromStorage(m as Map<String, dynamic>)).toList();
  }

  Future<void> saveConversation(String id, List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(messages.map((m) => m.toStorage()).toList());
    await prefs.setString('convo_$id', raw);
  }
}
