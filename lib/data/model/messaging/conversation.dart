// Clean Conversation Model
class Conversation {
  final String id;
  final String userId1;
  final String userId2;
  final String? lastMessageId;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, bool> readStatus; // userId -> isRead
  final bool isActive;

  const Conversation({
    required this.id,
    required this.userId1,
    required this.userId2,
    this.lastMessageId,
    this.lastMessageContent,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.readStatus = const {},
    this.isActive = true,
  });

  // Computed properties
  bool isReadBy(String userId) => readStatus[userId] ?? false;
  String get otherUserId => userId1; // Will be determined by context

  // JSON conversion
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id1': userId1,
    'user_id2': userId2,
    'last_message_id': lastMessageId,
    'last_message_content': lastMessageContent,
    'last_message_at': lastMessageAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'read_status': readStatus,
    'is_active': isActive,
  };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] ?? '',
    userId1: json['user_id1'] ?? '',
    userId2: json['user_id2'] ?? '',
    lastMessageId: json['last_message_id'],
    lastMessageContent: json['last_message_content'],
    lastMessageAt: json['last_message_at'] != null 
        ? DateTime.parse(json['last_message_at']) 
        : null,
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    readStatus: Map<String, bool>.from(json['read_status'] ?? {}),
    isActive: json['is_active'] ?? true,
  );

  Conversation copyWith({
    String? id,
    String? userId1,
    String? userId2,
    String? lastMessageId,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, bool>? readStatus,
    bool? isActive,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readStatus: readStatus ?? this.readStatus,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Conversation(id: $id, userId1: $userId1, userId2: $userId2)';
}
