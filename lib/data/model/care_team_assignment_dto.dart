import 'package:reentry/data/model/user_dto.dart';

enum AssignmentType { care_team_member, client_assignment }
enum AssignmentStatus { active, inactive, terminated }

class CareTeamAssignmentDto {
  final String id;
  final String careTeamMemberId;
  final String clientId;
  final String assignedBy;
  final AssignmentType assignmentType;
  final AssignmentStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserDto? careTeamMember;
  final UserDto? client;
  final UserDto? assignedByUser;

  const CareTeamAssignmentDto({
    required this.id,
    required this.careTeamMemberId,
    required this.clientId,
    required this.assignedBy,
    required this.assignmentType,
    required this.status,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.careTeamMember,
    this.client,
    this.assignedByUser,
  });

  factory CareTeamAssignmentDto.fromJson(Map<String, dynamic> json) {
    return CareTeamAssignmentDto(
      id: json['id'] as String,
      careTeamMemberId: json['care_team_member_id'] as String,
      clientId: json['client_id'] as String,
      assignedBy: json['assigned_by'] as String,
      assignmentType: AssignmentType.values.firstWhere(
        (e) => e.name == json['assignment_type'],
        orElse: () => AssignmentType.care_team_member,
      ),
      status: AssignmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AssignmentStatus.active,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      careTeamMember: json['care_team_member'] != null ? UserDto.fromJson(json['care_team_member']) : null,
      client: json['client'] != null ? UserDto.fromJson(json['client']) : null,
      assignedByUser: json['assigned_by_user'] != null ? UserDto.fromJson(json['assigned_by_user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'care_team_member_id': careTeamMemberId,
      'client_id': clientId,
      'assigned_by': assignedBy,
      'assignment_type': assignmentType.name,
      'status': status.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CareTeamAssignmentDto copyWith({
    String? id,
    String? careTeamMemberId,
    String? clientId,
    String? assignedBy,
    AssignmentType? assignmentType,
    AssignmentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserDto? careTeamMember,
    UserDto? client,
    UserDto? assignedByUser,
  }) {
    return CareTeamAssignmentDto(
      id: id ?? this.id,
      careTeamMemberId: careTeamMemberId ?? this.careTeamMemberId,
      clientId: clientId ?? this.clientId,
      assignedBy: assignedBy ?? this.assignedBy,
      assignmentType: assignmentType ?? this.assignmentType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      careTeamMember: careTeamMember ?? this.careTeamMember,
      client: client ?? this.client,
      assignedByUser: assignedByUser ?? this.assignedByUser,
    );
  }
}
