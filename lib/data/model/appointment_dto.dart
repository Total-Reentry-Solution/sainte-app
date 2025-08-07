import 'package:reentry/ui/modules/appointment/create_appointment_screen.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/model/client_dto.dart';

enum AppointmentStatus { all, upcoming, missed, done, canceled }

enum EventState { scheduled, accepted, declined, pending }

class NewAppointmentDto {
  final String title;
  final String description;
  final String? location;
  final String? participantName;
  final String? participantAvatar;
  final String? participantId;
  final String creatorId;
  final int? timestamp;
  final EventState state;
  final List<String> orgs;
  final String? id;
  final AppointmentStatus status;
  final String? reasonForRejection;
  final DateTime date;
  final List<String> attendees;
  final String creatorName;
  final bool createdByMe;
  final String creatorAvatar;

  static const keyAttendees = 'attendees';
  static const keyStatus = 'status';
  static const keyState = 'state';
  static const keyCreatorId = 'creatorId';
  static const keyParticipantId = 'participantId';
  static const keyDate = 'timestamp';

  const NewAppointmentDto(
      {required this.title,
      required this.description,
      this.location,
      this.attendees = const [],
      this.participantAvatar,
      this.createdByMe = false,
      this.id,
      this.reasonForRejection,
      required this.date,
      this.participantName,
      required this.creatorAvatar,
      required this.creatorName,
      required this.status,
      this.orgs = const [],
      this.timestamp,
      this.participantId,
      required this.creatorId,
      required this.state});

  AppointmentUserDto? getParticipant() {
    if (participantId == null) {
      return null;
    }
    return AppointmentUserDto(
        userId: participantId ?? '',
        name: participantName ?? '',
        avatar: participantAvatar ?? '');
  }

  Map<String, dynamic> toJson() {
    // Check if this is a manual entry (participantId starts with 'manual_')
    final isManualEntry = participantId?.startsWith('manual_') ?? false;
    
    return {
      //'id': (id != null && id?.isNotEmpty == true) ? id : null,
      'date': date.toIso8601String(),
      'creator_id': (creatorId != null && creatorId?.isNotEmpty == true) ? creatorId : null,
      'title': title.isNotEmpty ? title : 'Untitled Appointment', // Ensure title is never null
      'description': description.isNotEmpty ? description : '', // Ensure description is never null
      // Only include participant info if it's a real mentor (not manual entry)
      //'participant_name': (!isManualEntry && participantName != null) ? participantName : null,
      // 'participant_avatar': (!isManualEntry && participantAvatar != null) ? participantAvatar : null,
      //'organizations': orgs,
      // Only set participant_id if it's not a manual entry and is a valid UUID
      'participant_id': (!isManualEntry && participantId != null && participantId!.isNotEmpty) ? participantId : null,
      //'reason_for_rejection': reasonForRejection,
      // Note: attendees field removed as it doesn't exist in the database schema
      // The appointments table uses participant_id instead
      'state': state.name,
      'status': status.name,
      'location': location ?? ''
    };
  }

  factory NewAppointmentDto.fromJson(Map<String, dynamic> json, String userId) {
    // Parse status with better error handling
    AppointmentStatus status;
    try {
      status = AppointmentStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => AppointmentStatus.upcoming,
      );
    } catch (e) {
      print('Error parsing appointment status: ${json['status']}, defaulting to upcoming');
      status = AppointmentStatus.upcoming;
    }
    
    // Parse state with better error handling
    EventState state;
    try {
      state = EventState.values.firstWhere(
        (e) => e.name == (json['state'] as String?),
        orElse: () => EventState.pending,
      );
    } catch (e) {
      print('Error parsing appointment state: ${json['state']}, defaulting to pending');
      state = EventState.pending;
    }
    
    // Determine if appointment is past due and update status accordingly
    final appointmentDate = DateTime.parse(json['date'] as String);
    final now = DateTime.now();
    
    // If appointment is in the past and still marked as upcoming, change to missed
    if (appointmentDate.isBefore(now) && status == AppointmentStatus.upcoming) {
      status = AppointmentStatus.missed;
    }
    
    return NewAppointmentDto(
      title: json['title'] as String,
      description: json['description'] as String,
      location: json['location'] as String?,
      participantName: null, // Not stored in database - will be fetched from user profile if participantId exists
      orgs: [], // Not stored in database
      createdByMe: json['creator_id'] == userId,
      reasonForRejection: null, // Not stored in database
      participantAvatar: null, // Not stored in database - will be fetched from user profile if participantId exists
      participantId: json['participant_id'] as String?,
      creatorId: json['creator_id'] as String,
      timestamp: null, // Not stored in database
      state: EventState.values.byName(json['state'] as String),
      attendees: [], // attendees field not used in current database schema
     // id: json['id'] as String?,
      status: AppointmentStatus.values.byName(json['status'] as String),
      date: DateTime.parse(json['date'] as String),
      creatorName: '', // Not stored in database - will need to fetch from user profile
      creatorAvatar: '', // Not stored in database - will need to fetch from user profile
    );
  }

  NewAppointmentDto copyWith({
    String? title,
    String? description,
    String? location,
    String? participantName,
    String? participantAvatar,
    String? participantId,
    String? creatorId,
    int? timestamp,
    EventState? state,
    String? id,
    AppointmentStatus? status,
    List<String>? orgs,
    String? reasonForRejection,
    DateTime? date,
    String? creatorName,
    String? creatorAvatar,
  }) {
    return NewAppointmentDto(
      title: title ?? this.title,
      description: description ?? this.description,
      orgs: orgs ?? this.orgs,
      location: location ?? this.location,
      participantName: participantName ?? this.participantName,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      participantId: participantId ?? this.participantId,
      creatorId: creatorId ?? this.creatorId,
      timestamp: timestamp ?? this.timestamp,
      reasonForRejection: reasonForRejection ?? this.reasonForRejection,
      state: state ?? this.state,
      id: id ?? this.id,
      status: status ?? this.status,
      date: date ?? this.date,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
    );
  }
}

class AppointmentDto {
  final String id;
  final String? note;
  final int time;
  final List<String> attendees;
  final int? bookedDay;
  final String? bookedTime;
  final AppointmentStatus status;
  static const keyAttendees = 'attendees';
  static const keyStatus = 'status';
  static const keyOrgs = 'orgs';

  AppointmentDto({
    required this.id,
    this.note,
    this.bookedDay,
    this.bookedTime,
    required this.status,
    required this.time,
    this.attendees = const [],
  });

  // copyWith method
  AppointmentDto copyWith({
    String? id,
    int? time,
    AppointmentStatus? status,
    String? note,
    int? bookedDay,
    String? bookedTime,
    List<String>? attendees,
  }) {
    return AppointmentDto(
      id: id ?? this.id,
      note: note ?? this.note,
      bookedDay: bookedDay ?? this.bookedDay,
      status: status ?? this.status,
      bookedTime: bookedTime ?? this.bookedTime,
      time: time ?? this.time,
      attendees: attendees ?? this.attendees,
    );
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'note': note,
      'status': status.name,
      'attendees': attendees,
      'bookedDay': bookedDay,
      'bookedTime': bookedTime
    };
  }

  // fromJson method
  factory AppointmentDto.fromJson(Map<String, dynamic> json) {
    final statusValue =
        (json['status'] as String?) ?? AppointmentStatus.upcoming.name;
    return AppointmentDto(
        id: json['id'],
        note: json['note'],
        status:
            AppointmentStatus.values.firstWhere((e) => e.name == statusValue),
        bookedTime: json['bookedTime'],
        bookedDay: json['bookedDay'],
        time: (json['time'] as int?) ?? 0,
        attendees: (json['attendees'] as List<dynamic>)
            .map((e) => e.toString())
            .toList());
  }
}

class AppointmentEntityDto {
  final String id;
  final String? note;
  final DateTime time;
  final String userId;
  final String name;
  final String accountType;
  final AppointmentStatus status;
  final int bookedDay;
  final String bookedTime;
  final String avatar;

  const AppointmentEntityDto(
      {required this.userId,
      required this.time,
      required this.bookedTime,
      required this.bookedDay,
      required this.accountType,
      required this.status,
      required this.name,
      required this.id,
      required this.note,
      required this.avatar});
}

class CreateAppointmentDto {}

extension UserDtoToAppointmentUserDto on UserDto {
  AppointmentUserDto toAppointmentUserDto() {
    return AppointmentUserDto(
      userId: userId ?? '',
      name: name,
      avatar: avatar ?? '',
    );
  }
}

extension ClientDtoToAppointmentUserDto on ClientDto {
  AppointmentUserDto toAppointmentUserDto() {
    return AppointmentUserDto(
      userId: id ?? '',
      name: name,
      avatar: avatar ?? '',
    );
  }
}
