import 'package:reentry/data/model/user_dto.dart';

enum CaseCitizenAssignmentRequestStatus {
  pending,
  accepted,
  rejected,
  active,
}

class CaseCitizenAssignmentDto {
  final String? id;
  final String caseManagerId;
  final String citizenId;
  final CaseCitizenAssignmentRequestStatus assignmentStatus;
  final String? requestMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? respondedAt;
  final String? responseMessage;
  final DateTime? assignedAt;
  
  // Additional fields for UI display
  final UserDto? caseManager;
  final UserDto? citizen;

  const CaseCitizenAssignmentDto({
    this.id,
    required this.caseManagerId,
    required this.citizenId,
    this.assignmentStatus = CaseCitizenAssignmentRequestStatus.pending,
    this.requestMessage,
    required this.createdAt,
    required this.updatedAt,
    this.respondedAt,
    this.responseMessage,
    this.assignedAt,
    this.caseManager,
    this.citizen,
  });

  factory CaseCitizenAssignmentDto.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    return CaseCitizenAssignmentDto(
      id: json['id'],
      caseManagerId: json['case_manager_id'] ?? '',
      citizenId: json['citizen_id'] ?? '',
      assignmentStatus: CaseCitizenAssignmentRequestStatus.values.firstWhere(
        (e) => e.name == json['assignment_status'],
        orElse: () => CaseCitizenAssignmentRequestStatus.pending,
      ),
      requestMessage: json['request_message'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      respondedAt: json['responded_at'] != null 
          ? DateTime.parse(json['responded_at']) 
          : null,
      responseMessage: json['response_message'],
      assignedAt: json['assigned_at'] != null 
          ? DateTime.parse(json['assigned_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'case_manager_id': caseManagerId,
      'citizen_id': citizenId,
      'assignment_status': assignmentStatus.name,
      if (requestMessage != null) 'request_message': requestMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
      if (responseMessage != null) 'response_message': responseMessage,
      if (assignedAt != null) 'assigned_at': assignedAt!.toIso8601String(),
    };
  }

  CaseCitizenAssignmentDto copyWith({
    String? id,
    String? caseManagerId,
    String? citizenId,
    CaseCitizenAssignmentRequestStatus? assignmentStatus,
    String? requestMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? respondedAt,
    String? responseMessage,
    DateTime? assignedAt,
    UserDto? caseManager,
    UserDto? citizen,
  }) {
    return CaseCitizenAssignmentDto(
      id: id ?? this.id,
      caseManagerId: caseManagerId ?? this.caseManagerId,
      citizenId: citizenId ?? this.citizenId,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      requestMessage: requestMessage ?? this.requestMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      responseMessage: responseMessage ?? this.responseMessage,
      assignedAt: assignedAt ?? this.assignedAt,
      caseManager: caseManager ?? this.caseManager,
      citizen: citizen ?? this.citizen,
    );
  }

  @override
  String toString() {
    return 'CaseCitizenAssignmentDto(id: $id, caseManagerId: $caseManagerId, citizenId: $citizenId, assignmentStatus: $assignmentStatus, requestMessage: $requestMessage, createdAt: $createdAt, updatedAt: $updatedAt, respondedAt: $respondedAt, responseMessage: $responseMessage, assignedAt: $assignedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CaseCitizenAssignmentDto &&
        other.id == id &&
        other.caseManagerId == caseManagerId &&
        other.citizenId == citizenId &&
        other.assignmentStatus == assignmentStatus &&
        other.requestMessage == requestMessage &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.respondedAt == respondedAt &&
        other.responseMessage == responseMessage &&
        other.assignedAt == assignedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        caseManagerId.hashCode ^
        citizenId.hashCode ^
        assignmentStatus.hashCode ^
        requestMessage.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        respondedAt.hashCode ^
        responseMessage.hashCode ^
        assignedAt.hashCode;
  }
}
