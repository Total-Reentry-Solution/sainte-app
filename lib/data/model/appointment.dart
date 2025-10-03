// Clean Appointment Model
class Appointment {
  final String id;
  final String title;
  final String? description;
  final String userId;
  final String? mentorId;
  final String? officerId;
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? location;
  final String? meetingLink;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const Appointment({
    required this.id,
    required this.title,
    this.description,
    required this.userId,
    this.mentorId,
    this.officerId,
    required this.startTime,
    required this.endTime,
    this.status = AppointmentStatus.scheduled,
    this.type = AppointmentType.meeting,
    this.location,
    this.meetingLink,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  // Computed properties
  Duration get duration => endTime.difference(startTime);
  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isPast => endTime.isBefore(DateTime.now());
  bool get isToday => startTime.day == DateTime.now().day && 
                     startTime.month == DateTime.now().month && 
                     startTime.year == DateTime.now().year;

  // JSON conversion
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'user_id': userId,
    'mentor_id': mentorId,
    'officer_id': officerId,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'status': status.name,
    'type': type.name,
    'location': location,
    'meeting_link': meetingLink,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'metadata': metadata,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'],
    userId: json['user_id'] ?? '',
    mentorId: json['mentor_id'],
    officerId: json['officer_id'],
    startTime: DateTime.parse(json['start_time'] ?? DateTime.now().toIso8601String()),
    endTime: DateTime.parse(json['end_time'] ?? DateTime.now().toIso8601String()),
    status: AppointmentStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => AppointmentStatus.scheduled,
    ),
    type: AppointmentType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => AppointmentType.meeting,
    ),
    location: json['location'],
    meetingLink: json['meeting_link'],
    notes: json['notes'],
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    metadata: json['metadata'],
  );

  Appointment copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
    String? mentorId,
    String? officerId,
    DateTime? startTime,
    DateTime? endTime,
    AppointmentStatus? status,
    AppointmentType? type,
    String? location,
    String? meetingLink,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      mentorId: mentorId ?? this.mentorId,
      officerId: officerId ?? this.officerId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      type: type ?? this.type,
      location: location ?? this.location,
      meetingLink: meetingLink ?? this.meetingLink,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Appointment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Appointment(id: $id, title: $title, startTime: $startTime)';
}

enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rescheduled;

  String get displayName {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.rescheduled:
        return 'Rescheduled';
    }
  }
}

enum AppointmentType {
  meeting,
  call,
  video,
  inPerson,
  group;

  String get displayName {
    switch (this) {
      case AppointmentType.meeting:
        return 'Meeting';
      case AppointmentType.call:
        return 'Phone Call';
      case AppointmentType.video:
        return 'Video Call';
      case AppointmentType.inPerson:
        return 'In Person';
      case AppointmentType.group:
        return 'Group Meeting';
    }
  }
}
