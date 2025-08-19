import 'package:reentry/data/enum/account_type.dart';

class ReceiverInfo {
  final String name;
  final String avatar;
  final AccountType accountType;

  const ReceiverInfo(
      {required this.name, required this.avatar, required this.accountType});
}

class MessageDto {
  final String? id;
  final String senderPersonId;
  final String receiverPersonId;
  final String? senderId; // Add support for userID
  final String? receiverId; // Add support for userID
  final String text;
  final ReceiverInfo? receiverInfo;
  final int? timestamp;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MessageDto({
    this.id,
    required this.senderPersonId,
    required this.receiverPersonId,
    this.senderId, // Optional userID
    this.receiverId, // Optional userID
    required this.text,
    this.receiverInfo,
    this.timestamp,
    this.isRead = false,
    this.createdAt,
    this.updatedAt,
  });

  MessageDto copyWith({
    String? id,
    String? senderPersonId,
    String? receiverPersonId,
    String? senderId,
    String? receiverId,
    String? text,
    ReceiverInfo? receiverInfo,
    int? timestamp,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      MessageDto(
        id: id ?? this.id,
        senderPersonId: senderPersonId ?? this.senderPersonId,
        receiverPersonId: receiverPersonId ?? this.receiverPersonId,
        senderId: senderId ?? this.senderId,
        receiverId: receiverId ?? this.receiverId,
        text: text ?? this.text,
        receiverInfo: receiverInfo ?? this.receiverInfo,
        timestamp: timestamp ?? this.timestamp,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    print('MessageDto.fromJson called with: $json');
    
    // Support both personID and userID fields
    final senderPersonId = json['sender_person_id'] ?? json['sender_id'] ?? '';
    final receiverPersonId = json['receiver_person_id'] ?? json['receiver_id'] ?? '';
    final senderId = json['sender_id'];
    final receiverId = json['receiver_id'];
    
    print('Parsed senderPersonId: $senderPersonId');
    print('Parsed receiverPersonId: $receiverPersonId');
    print('Parsed senderId: $senderId');
    print('Parsed receiverId: $receiverId');
    
    return MessageDto(
      id: json['id'],
      senderPersonId: senderPersonId,
      receiverPersonId: receiverPersonId,
      senderId: senderId,
      receiverId: receiverId,
      text: json['text'] ?? '',
      receiverInfo: null,
      timestamp: json['sent_at'] != null ? DateTime.parse(json['sent_at']).millisecondsSinceEpoch : DateTime.now().millisecondsSinceEpoch,
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_person_id': senderPersonId,
    'receiver_person_id': receiverPersonId,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'text': text,
    'sent_at': timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp!).toIso8601String() : DateTime.now().toIso8601String(),
    'is_read': isRead,
    'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
  };

  // Helper method to get the primary sender identifier
  String get primarySenderId => senderPersonId.isNotEmpty ? senderPersonId : (senderId ?? '');
  
  // Helper method to get the primary receiver identifier
  String get primaryReceiverId => receiverPersonId.isNotEmpty ? receiverPersonId : (receiverId ?? '');
}
