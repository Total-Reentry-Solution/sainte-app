class GoalDto {
  final String? goalId;
  final String personId;
  final String goalDescription;
  final DateTime? targetDate;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? goalType;
  final String title;
  final String description;
  final int? progressPercentage;
  final String? priorityLevel;
  final List<String>? tags;
  final String? duration;
  final DateTime? endDate;

  static const durations = [
    'Weekly',
    'Bi-Weekly',
    'Monthly',
    'Quarterly',
    '6 months',
    "1 year",
    "5 years",
    "10 years"
  ];

  GoalDto({
    this.goalId,
    required this.personId,
    required this.goalDescription,
    this.targetDate,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
    this.goalType,
    required this.title,
    required this.description,
    this.progressPercentage,
    this.priorityLevel,
    this.tags,
    this.duration,
    this.endDate,
  });

  GoalDto copyWith({
    String? goalId,
    String? personId,
    String? goalDescription,
    DateTime? targetDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? goalType,
    String? title,
    String? description,
    int? progressPercentage,
    String? priorityLevel,
    List<String>? tags,
    String? duration,
    DateTime? endDate,
  }) {
    return GoalDto(
      goalId: goalId ?? this.goalId,
      personId: personId ?? this.personId,
      goalDescription: goalDescription ?? this.goalDescription,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      goalType: goalType ?? this.goalType,
      title: title ?? this.title,
      description: description ?? this.description,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      tags: tags ?? this.tags,
      duration: duration ?? this.duration,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'person_id': personId,
      'goal_description': goalDescription,
      'target_date': targetDate?.toIso8601String(),
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'goal_type': goalType,
      'title': title,
      'description': description,
      'progress_percentage': progressPercentage,
      'priority_level': priorityLevel,
      'tags': tags,
      'duration': duration,
      'end_date': endDate?.toIso8601String(),
    };
    if (goalId != null) {
      map['goal_id'] = goalId;
    }
    return map;
  }

  factory GoalDto.fromJson(Map<String, dynamic> json) {
    return GoalDto(
      goalId: json['goal_id'],
      personId: json['person_id'],
      goalDescription: json['goal_description'] ?? json['description'] ?? '',
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date']) : null,
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      goalType: json['goal_type'],
      title: json['title'] ?? '',
      description: json['description'] ?? json['goal_description'] ?? '',
      progressPercentage: json['progress_percentage'],
      priorityLevel: json['priority_level'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      duration: json['duration'],
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
    );
  }
}
