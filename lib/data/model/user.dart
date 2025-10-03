import '../enum/account_type.dart';

// CLEAN AppUser Model - Built from scratch to match Supabase schema
class AppUser {
  // Core identity (matches users table columns)
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? address;
  
  // Account info
  final AccountType accountType;
  final bool isDeleted;
  final String? deletionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Profile info
  final String? jobTitle;
  final String? organization;
  final String? organizationAddress;
  final String? supervisorName;
  final String? supervisorEmail;
  final DateTime? dateOfBirth;
  final String? about;
  
  // System fields
  final String? userCode;
  final String? pushNotificationToken;
  final UserSettings settings;
  final UserAvailability? availability;
  
  // Relationships (matches organization_ids, service_ids, etc.)
  final List<String> organizationIds;
  final List<String> serviceIds;
  final List<String> assigneeIds;
  final List<String> mentorIds;
  final List<String> officerIds;
  
  // Complex objects
  final IntakeForm? intakeForm;
  final VerificationRequest? verification;
  final List<MoodLog> moodLogs;

  const AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    this.address,
    required this.accountType,
    this.isDeleted = false,
    this.deletionReason,
    required this.createdAt,
    required this.updatedAt,
    this.jobTitle,
    this.organization,
    this.organizationAddress,
    this.supervisorName,
    this.supervisorEmail,
    this.dateOfBirth,
    this.about,
    this.userCode,
    this.pushNotificationToken,
    this.settings = const UserSettings(),
    this.availability,
    this.organizationIds = const [],
    this.serviceIds = const [],
    this.assigneeIds = const [],
    this.mentorIds = const [],
    this.officerIds = const [],
    this.intakeForm,
    this.verification,
    this.moodLogs = const [],
  });

  // Computed properties
  String get fullName => '$firstName $lastName'.trim();
  String get displayName => fullName.isNotEmpty ? fullName : 'Unknown User';

  // JSON conversion (snake_case to camelCase mapping)
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'phone_number': phoneNumber,
    'avatar_url': avatarUrl,
    'address': address,
    'account_type': accountType.name,
    'is_deleted': isDeleted,
    'deletion_reason': deletionReason,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'job_title': jobTitle,
    'organization': organization,
    'organization_address': organizationAddress,
    'supervisor_name': supervisorName,
    'supervisor_email': supervisorEmail,
    'date_of_birth': dateOfBirth?.toIso8601String(),
    'about': about,
    'user_code': userCode,
    'push_notification_token': pushNotificationToken,
    'settings': settings.toJson(),
    'availability': availability?.toJson(),
    'organization_ids': organizationIds,
    'service_ids': serviceIds,
    'assignee_ids': assigneeIds,
    'mentor_ids': mentorIds,
    'officer_ids': officerIds,
    'intake_form': intakeForm?.toJson(),
    'verification': verification?.toJson(),
    'mood_logs': moodLogs.map((e) => e.toJson()).toList(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] ?? '',
    email: json['email'] ?? '',
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    phoneNumber: json['phone_number'],
    avatarUrl: json['avatar_url'],
    address: json['address'],
    accountType: AccountType.values.firstWhere(
      (e) => e.name == json['account_type'],
      orElse: () => AccountType.citizen,
    ),
    isDeleted: json['is_deleted'] ?? false,
    deletionReason: json['deletion_reason'],
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    jobTitle: json['job_title'],
    organization: json['organization'],
    organizationAddress: json['organization_address'],
    supervisorName: json['supervisor_name'],
    supervisorEmail: json['supervisor_email'],
    dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
    about: json['about'],
    userCode: json['user_code'],
    pushNotificationToken: json['push_notification_token'],
    settings: json['settings'] != null ? UserSettings.fromJson(json['settings']) : const UserSettings(),
    availability: json['availability'] != null ? UserAvailability.fromJson(json['availability']) : null,
    organizationIds: List<String>.from(json['organization_ids'] ?? []),
    serviceIds: List<String>.from(json['service_ids'] ?? []),
    assigneeIds: List<String>.from(json['assignee_ids'] ?? []),
    mentorIds: List<String>.from(json['mentor_ids'] ?? []),
    officerIds: List<String>.from(json['officer_ids'] ?? []),
    intakeForm: json['intake_form'] != null ? IntakeForm.fromJson(json['intake_form']) : null,
    verification: json['verification'] != null ? VerificationRequest.fromJson(json['verification']) : null,
    moodLogs: (json['mood_logs'] as List<dynamic>?)
        ?.map((e) => MoodLog.fromJson(e))
        .toList() ?? [],
  );

  AppUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? avatarUrl,
    String? address,
    AccountType? accountType,
    bool? isDeleted,
    String? deletionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? jobTitle,
    String? organization,
    String? organizationAddress,
    String? supervisorName,
    String? supervisorEmail,
    DateTime? dateOfBirth,
    String? about,
    String? userCode,
    String? pushNotificationToken,
    UserSettings? settings,
    UserAvailability? availability,
    List<String>? organizationIds,
    List<String>? serviceIds,
    List<String>? assigneeIds,
    List<String>? mentorIds,
    List<String>? officerIds,
    IntakeForm? intakeForm,
    VerificationRequest? verification,
    List<MoodLog>? moodLogs,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
      accountType: accountType ?? this.accountType,
      isDeleted: isDeleted ?? this.isDeleted,
      deletionReason: deletionReason ?? this.deletionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      jobTitle: jobTitle ?? this.jobTitle,
      organization: organization ?? this.organization,
      organizationAddress: organizationAddress ?? this.organizationAddress,
      supervisorName: supervisorName ?? this.supervisorName,
      supervisorEmail: supervisorEmail ?? this.supervisorEmail,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      about: about ?? this.about,
      userCode: userCode ?? this.userCode,
      pushNotificationToken: pushNotificationToken ?? this.pushNotificationToken,
      settings: settings ?? this.settings,
      availability: availability ?? this.availability,
      organizationIds: organizationIds ?? this.organizationIds,
      serviceIds: serviceIds ?? this.serviceIds,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      mentorIds: mentorIds ?? this.mentorIds,
      officerIds: officerIds ?? this.officerIds,
      intakeForm: intakeForm ?? this.intakeForm,
      verification: verification ?? this.verification,
      moodLogs: moodLogs ?? this.moodLogs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppUser(id: $id, email: $email, fullName: $fullName)';
}

// Supporting classes
class UserSettings {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final String? language;
  final String? theme;

  const UserSettings({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.language,
    this.theme,
  });

  Map<String, dynamic> toJson() => {
    'pushNotifications': pushNotifications,
    'emailNotifications': emailNotifications,
    'smsNotifications': smsNotifications,
    'language': language,
    'theme': theme,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    pushNotifications: json['pushNotifications'] ?? true,
    emailNotifications: json['emailNotifications'] ?? true,
    smsNotifications: json['smsNotifications'] ?? false,
    language: json['language'],
    theme: json['theme'],
  );
}

class UserAvailability {
  final String? monday;
  final String? tuesday;
  final String? wednesday;
  final String? thursday;
  final String? friday;
  final String? saturday;
  final String? sunday;

  const UserAvailability({
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
    this.sunday,
  });

  Map<String, dynamic> toJson() => {
    'monday': monday,
    'tuesday': tuesday,
    'wednesday': wednesday,
    'thursday': thursday,
    'friday': friday,
    'saturday': saturday,
    'sunday': sunday,
  };

  factory UserAvailability.fromJson(Map<String, dynamic> json) => UserAvailability(
    monday: json['monday'],
    tuesday: json['tuesday'],
    wednesday: json['wednesday'],
    thursday: json['thursday'],
    friday: json['friday'],
    saturday: json['saturday'],
    sunday: json['sunday'],
  );
}

class IntakeForm {
  final String? currentSituation;
  final String? contributionGoals;
  final String? growthGoals;
  final String? futureVision;
  final String? lifeExperiences;
  final String? achievementVision;
  final String? lifePriorities;
  final String? missionStatement;
  final String? visionStatement;
  final String? currentPosition;
  final String? pathForward;

  const IntakeForm({
    this.currentSituation,
    this.contributionGoals,
    this.growthGoals,
    this.futureVision,
    this.lifeExperiences,
    this.achievementVision,
    this.lifePriorities,
    this.missionStatement,
    this.visionStatement,
    this.currentPosition,
    this.pathForward,
  });

  Map<String, dynamic> toJson() => {
    'currentSituation': currentSituation,
    'contributionGoals': contributionGoals,
    'growthGoals': growthGoals,
    'futureVision': futureVision,
    'lifeExperiences': lifeExperiences,
    'achievementVision': achievementVision,
    'lifePriorities': lifePriorities,
    'missionStatement': missionStatement,
    'visionStatement': visionStatement,
    'currentPosition': currentPosition,
    'pathForward': pathForward,
  };

  factory IntakeForm.fromJson(Map<String, dynamic> json) => IntakeForm(
    currentSituation: json['currentSituation'],
    contributionGoals: json['contributionGoals'],
    growthGoals: json['growthGoals'],
    futureVision: json['futureVision'],
    lifeExperiences: json['lifeExperiences'],
    achievementVision: json['achievementVision'],
    lifePriorities: json['lifePriorities'],
    missionStatement: json['missionStatement'],
    visionStatement: json['visionStatement'],
    currentPosition: json['currentPosition'],
    pathForward: json['pathForward'],
  );
}

// Placeholder classes - will be defined in separate files
class VerificationRequest {
  final String id;
  final String status;
  final Map<String, dynamic> form;
  final DateTime createdAt;

  const VerificationRequest({
    required this.id,
    required this.status,
    required this.form,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'form': form,
    'created_at': createdAt.toIso8601String(),
  };

  factory VerificationRequest.fromJson(Map<String, dynamic> json) => VerificationRequest(
    id: json['id'] ?? '',
    status: json['status'] ?? 'pending',
    form: json['form'] ?? {},
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
  );
}

class MoodLog {
  final String id;
  final String userId;
  final String moodId;
  final String? notes;
  final int? intensity;
  final DateTime createdAt;

  const MoodLog({
    required this.id,
    required this.userId,
    required this.moodId,
    this.notes,
    this.intensity,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'mood_id': moodId,
    'notes': notes,
    'intensity': intensity,
    'created_at': createdAt.toIso8601String(),
  };

  factory MoodLog.fromJson(Map<String, dynamic> json) => MoodLog(
    id: json['id'] ?? '',
    userId: json['user_id'] ?? '',
    moodId: json['mood_id'] ?? '',
    notes: json['notes'],
    intensity: json['intensity'],
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
  );
}
