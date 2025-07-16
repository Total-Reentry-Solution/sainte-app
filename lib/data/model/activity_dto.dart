import 'package:reentry/data/model/goal_dto.dart';

enum Frequency { daily, weekly }

class ActivityDto {
  final String id;
  final Frequency frequency;
  final List<int> timeLine;
  final String title;
  final int dayStreak;
  final String? goal;
  final int progress;

  final int startDate;
  final int endDate;
  static const keyCreatedAt = 'createdAt';
  static const keyEndDate = 'endDate';

  const ActivityDto({
    required this.frequency,
    required this.title,
    this.goal,
    required this.progress,
    this.dayStreak = 1,
    required this.endDate,
    required this.startDate,
    required this.timeLine,
    this.id = '',
  });

  // fromJson method
  factory ActivityDto.fromJson(Map<String, dynamic> json) {
    return ActivityDto(
      id: json['id'] ?? '',
      dayStreak: json['day_streak'],
      progress: json['progress'],
      startDate: json['start_date'],
      goal: json['goal'] as String?,
      endDate: json['end_date'],
      frequency: Frequency.values.byName(json['frequency']),
      timeLine: List<int>.from(json['time_line']),
      title: json['title'],
    );
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'frequency': frequency.name,
      'goal': goal,
      'day_streak': dayStreak,
      'start_date': startDate,
      'end_date': endDate,
      'progress': progress,
      'time_line': timeLine,
      'title': title,
    };
  }

  ActivityDto copyWith({
    String? id,
    Frequency? frequency,
    List<int>? timeLine,
    String? goal,
    int? startDate,
    int? endDate,
    int? progress,
    int? dayStreak,
    String? title,
  }) {
    return ActivityDto(
      id: id ?? this.id,
      progress: progress ?? this.progress,
      dayStreak: dayStreak ?? this.dayStreak,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      goal: goal??this.goal,
      endDate: endDate ?? this.endDate,
      timeLine: timeLine ?? this.timeLine,
      title: title ?? this.title,
    );
  }
}
