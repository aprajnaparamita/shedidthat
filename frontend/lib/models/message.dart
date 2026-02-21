class Message {
  final String role;
  String content;
  final DateTime timestamp;

  Message({required this.role, required this.content, required this.timestamp});

  Map<String, String> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }

  Map<String, String> toStorage() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromStorage(Map<String, dynamic> json) {
    return Message(
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
