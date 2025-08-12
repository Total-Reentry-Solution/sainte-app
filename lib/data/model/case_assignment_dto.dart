import 'package:reentry/data/model/user_dto.dart';

enum CaseAssignmentStatus { active, inactive, completed, terminated }

class CaseAssignmentDto {
  final String assignmentId;
  final String personId;
  final String caseloadId;
  final DateTime assignedAt;
  final CaseAssignmentStatus status;
  final UserDto? person;
  final UserDto? caseload;

  const CaseAssignmentDto({
    required this.assignmentId,
    required this.personId,
    required this.caseloadId,
    required this.assignedAt,
    required this.status,
    this.person,
    this.caseload,
  });

  factory CaseAssignmentDto.fromJson(Map<String, dynamic> json) {
    return CaseAssignmentDto(
      assignmentId: json['assignment_id'] as String,
      personId: json['person_id'] as String,
      caseloadId: json['caseload_id'] as String,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      status: CaseAssignmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CaseAssignmentStatus.active,
      ),
      person: json['person'] != null ? UserDto.fromJson(json['person']) : null,
      caseload: json['caseload'] != null ? UserDto.fromJson(json['caseload']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      'person_id': personId,
      'caseload_id': caseloadId,
      'assigned_at': assignedAt.toIso8601String(),
      'status': status.name,
    };
  }

  CaseAssignmentDto copyWith({
    String? assignmentId,
    String? personId,
    String? caseloadId,
    DateTime? assignedAt,
    CaseAssignmentStatus? status,
    UserDto? person,
    UserDto? caseload,
  }) {
    return CaseAssignmentDto(
      assignmentId: assignmentId ?? this.assignmentId,
      personId: personId ?? this.personId,
      caseloadId: caseloadId ?? this.caseloadId,
      assignedAt: assignedAt ?? this.assignedAt,
      status: status ?? this.status,
      person: person ?? this.person,
      caseload: caseload ?? this.caseload,
    );
  }
}
