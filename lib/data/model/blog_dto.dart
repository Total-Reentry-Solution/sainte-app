class BlogDto {
  final String title;
  final List<Map<String, dynamic>> content;
  final String? imageUrl;
  final String? url;
  final String? id;
  final String? authorName;
  final String? dateCreated;
  final String? userId;
  final String? category;

  const BlogDto(
      {required this.title,
      required this.content,
      this.imageUrl,
      this.authorName,
      this.dateCreated,
        this.category,
      this.url,
      this.userId,
      this.id});

  factory BlogDto.fromJson(Map<String, dynamic> json) {
    return BlogDto(
      title: json['title'] as String? ?? 'Untitled',
      content: (json['data'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList()??[],
      category: json['category'] as String? ?? 'General',
      dateCreated:
          (DateTime.tryParse((json['date'] as String?) ?? '') ?? DateTime.now())
              .toIso8601String(),
      imageUrl: json['image_url'] as String?,
      url: null, // url column doesn't exist in our schema
      id: json['id'] as String?,
      authorName: json['author_name'] as String? ?? 'Anonymous',
      userId: json['author_id'] as String? ?? '',
    );
  }

  BlogDto copyWith({
    String? id,
    String? title,
    List<Map<String, dynamic>>? content,
    String? url,
    String? imageUrl,
  }) {
    return BlogDto(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson({DateTime? date}) {
    return {
      'title': title,
      'data': content,
      'date': date?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'authorName': authorName,
      'content': 'No content',
      'url': url,
      'category':category,
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
    };
  }
}
