import 'package:reentry/data/model/user_dto.dart';

enum InvitationType { care_team_member, client_assignment }
enum InvitationStatus { pending, accepted, rejected }

class CareTeamInvitationDto {
  final String id;
  final String inviterId;
  final String inviteeId;
  final InvitationType invitationType;
  final InvitationStatus status;
  final String? message;
  final String? reasonForRejection;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserDto? inviter;
  final UserDto? invitee;

  const CareTeamInvitationDto({
    required this.id,
    required this.inviterId,
    required this.inviteeId,
    required this.invitationType,
    required this.status,
    this.message,
    this.reasonForRejection,
    required this.createdAt,
    required this.updatedAt,
    this.inviter,
    this.invitee,
  });

  factory CareTeamInvitationDto.fromJson(Map<String, dynamic> json) {
    return CareTeamInvitationDto(
      id: json['id'] as String,
      inviterId: json['inviter_id'] as String,
      inviteeId: json['invitee_id'] as String,
      invitationType: InvitationType.values.firstWhere(
        (e) => e.name == json['invitation_type'],
        orElse: () => InvitationType.care_team_member,
      ),
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvitationStatus.pending,
      ),
      message: json['message'] as String?,
      reasonForRejection: json['reason_for_rejection'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      inviter: json['inviter'] != null ? UserDto.fromJson(json['inviter']) : null,
      invitee: json['invitee'] != null ? UserDto.fromJson(json['invitee']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inviter_id': inviterId,
      'invitee_id': inviteeId,
      'invitation_type': invitationType.name,
      'status': status.name,
      'message': message,
      'reason_for_rejection': reasonForRejection,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CareTeamInvitationDto copyWith({
    String? id,
    String? inviterId,
    String? inviteeId,
    InvitationType? invitationType,
    InvitationStatus? status,
    String? message,
    String? reasonForRejection,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserDto? inviter,
    UserDto? invitee,
  }) {
    return CareTeamInvitationDto(
      id: id ?? this.id,
      inviterId: inviterId ?? this.inviterId,
      inviteeId: inviteeId ?? this.inviteeId,
      invitationType: invitationType ?? this.invitationType,
      status: status ?? this.status,
      message: message ?? this.message,
      reasonForRejection: reasonForRejection ?? this.reasonForRejection,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      inviter: inviter ?? this.inviter,
      invitee: invitee ?? this.invitee,
    );
  }
}
