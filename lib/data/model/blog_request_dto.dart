enum BlogRequestStatus {
  pending,
  approved,
  rejected,
}

class BlogRequestDto {
  final String? id;
  final String userId;
  final String title;
  final String content;
  final String details;
  final BlogRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BlogRequestDto({
    this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.details,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlogRequestDto.fromJson(Map<String, dynamic> json) {
    return BlogRequestDto(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      details: json['details'] as String,
      status: BlogRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BlogRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'details': details,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 