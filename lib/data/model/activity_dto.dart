import 'package:reentry/data/model/goal_dto.dart';

enum Frequency { daily, weekly }

class ActivityDto {
  final String id;
  final String userId; // changed from personId
  final Frequency frequency;
  final List<int> timeLine;
  final String title;
  final int dayStreak;
  final String? goalId; // renamed from `goal` to be clear it's a UUID
  final int progress;
  final int startDate;
  final int endDate;

  static const keyCreatedAt = 'createdAt';
  static const keyEndDate = 'endDate';

  const ActivityDto({
    required this.userId, // changed from personId
    required this.frequency,
    required this.title,
    this.goalId,
    required this.progress,
    this.dayStreak = 1,
    required this.endDate,
    required this.startDate,
    required this.timeLine,
    this.id = '',
  });

  factory ActivityDto.fromJson(Map<String, dynamic> json) {
    return ActivityDto(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '', // changed from person_id
      dayStreak: json['day_streak'],
      progress: json['progress'],
      startDate: json['start_date'],
      goalId: json['goal_id'] as String?, // fixed: match new DB column
      endDate: json['end_date'],
      frequency: Frequency.values.byName(json['frequency']),
      timeLine: List<int>.from(json['time_line']),
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'user_id': userId, // Only send user_id, never person_id
      'frequency': frequency.name,
      'goal_id': (goalId != null && goalId!.isNotEmpty) ? goalId : null,
      'day_streak': dayStreak,
      'start_date': startDate,
      'end_date': endDate,
      'progress': progress,
      'time_line': timeLine,
      'title': title,
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  ActivityDto copyWith({
    String? id,
    String? userId, // changed from personId
    Frequency? frequency,
    List<int>? timeLine,
    String? goalId,
    int? startDate,
    int? endDate,
    int? progress,
    int? dayStreak,
    String? title,
  }) {
    return ActivityDto(
      id: id ?? this.id,
      userId: userId ?? this.userId, // changed from personId
      progress: progress ?? this.progress,
      dayStreak: dayStreak ?? this.dayStreak,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      goalId: goalId ?? this.goalId,
      endDate: endDate ?? this.endDate,
      timeLine: timeLine ?? this.timeLine,
      title: title ?? this.title,
    );
  }
}
