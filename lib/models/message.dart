class Message {
  final String role;       // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Serialize for API — only role + content go to Claude
  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };

  /// Full serialization for local storage
  Map<String, dynamic> toStorage() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Message.fromStorage(Map<String, dynamic> json) => Message(
    role: json['role'] as String,
    content: json['content'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
