import 'user.dart';
import '../enum/account_type.dart';

// CLEAN Client Model - Built from scratch to match Supabase schema
// Clients are users with account_type = 'citizen' and specific properties
class Client {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final ClientStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> assigneeIds;
  final String? reasonForRequest;
  final String? mentorRequirements;
  final String? droppedReason;

  const Client({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeIds = const [],
    this.reasonForRequest,
    this.mentorRequirements,
    this.droppedReason,
  });

  // Computed properties
  String get fullName => '$firstName $lastName'.trim();
  String get displayName => fullName.isNotEmpty ? fullName : 'Unknown Client';

  // JSON conversion (snake_case to camelCase mapping)
  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone_number': phoneNumber,
    'avatar_url': avatarUrl,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'assignee_ids': assigneeIds,
    'reason_for_request': reasonForRequest,
    'mentor_requirements': mentorRequirements,
    'dropped_reason': droppedReason,
  };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: json['id'] ?? '',
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    email: json['email'],
    phoneNumber: json['phone_number'],
    avatarUrl: json['avatar_url'],
    status: ClientStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ClientStatus.pending,
    ),
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    assigneeIds: List<String>.from(json['assignee_ids'] ?? []),
    reasonForRequest: json['reason_for_request'],
    mentorRequirements: json['mentor_requirements'],
    droppedReason: json['dropped_reason'],
  );

  // Convert from AppUser (for users with account_type = 'citizen')
  factory Client.fromUser(AppUser user) => Client(
    id: user.id,
    firstName: user.firstName,
    lastName: user.lastName,
    email: user.email,
    phoneNumber: user.phoneNumber,
    avatarUrl: user.avatarUrl,
    status: ClientStatus.active, // Default status for existing users
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
    assigneeIds: user.assigneeIds,
    reasonForRequest: user.about, // Use about field as reason
    mentorRequirements: null,
    droppedReason: user.isDeleted ? user.deletionReason : null,
  );

  // Convert to AppUser (for creating/updating users)
  AppUser toUser() => AppUser(
    id: id,
    email: email ?? '',
    firstName: firstName,
    lastName: lastName,
    phoneNumber: phoneNumber,
    avatarUrl: avatarUrl,
    accountType: AccountType.citizen,
    isDeleted: status == ClientStatus.dropped,
    deletionReason: droppedReason,
    createdAt: createdAt,
    updatedAt: updatedAt,
    about: reasonForRequest,
    assigneeIds: assigneeIds,
  );

  Client copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    ClientStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? assigneeIds,
    String? reasonForRequest,
    String? mentorRequirements,
    String? droppedReason,
  }) {
    return Client(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      reasonForRequest: reasonForRequest ?? this.reasonForRequest,
      mentorRequirements: mentorRequirements ?? this.mentorRequirements,
      droppedReason: droppedReason ?? this.droppedReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Client && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Client(id: $id, fullName: $fullName, status: $status)';
}

enum ClientStatus {
  pending,
  active,
  dropped,
  declined;

  String get displayName {
    switch (this) {
      case ClientStatus.pending:
        return 'Pending';
      case ClientStatus.active:
        return 'Active';
      case ClientStatus.dropped:
        return 'Dropped';
      case ClientStatus.declined:
        return 'Declined';
    }
  }
}
