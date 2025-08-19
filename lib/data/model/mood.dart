class Mood {
  final String id;
  final String name;
  final String? icon;
  final String? category;

  Mood({required this.id, required this.name, this.icon, this.category});

  factory Mood.fromJson(Map<String, dynamic> json) => Mood(
        id: json['mood_id'] ?? json['id'],
        name: json['mood_name'] ?? json['name'],
        icon: json['mood_icon'],
        category: json['mood_category'],
      );

  Map<String, dynamic> toJson() => {
        'mood_id': id,
        'mood_name': name,
        'mood_icon': icon,
        'mood_category': category,
      };
}

class MoodLog {
  final String id;
  final String userId;
  final Mood mood;
  final String? notes;
  final int? intensity;
  final DateTime createdAt;

  MoodLog({
    required this.id,
    required this.userId,
    required this.mood,
    this.notes,
    this.intensity,
    required this.createdAt,
  });

  factory MoodLog.fromJson(Map<String, dynamic> json, Mood mood) => MoodLog(
        id: json['mood_log_id'] ?? json['id'],
        userId: json['user_id'],
        mood: mood,
        notes: json['notes'],
        intensity: json['mood_intensity'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'mood_log_id': id,
        'user_id': userId,
        'mood': mood.toJson(),
        'notes': notes,
        'mood_intensity': intensity,
        'created_at': createdAt.toIso8601String(),
      };

  DateTime get date => createdAt;
} 