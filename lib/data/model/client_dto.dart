import 'package:reentry/core/const/app_constants.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/ui/modules/messaging/entity/conversation_user_entity.dart';
import '../../ui/modules/appointment/create_appointment_screen.dart';

enum ClientStatus { pending, active, dropped, decline }

class ClientDto {
  final String id;
  final String name;
  final String avatar;
  final int createdAt;
  final int updatedAt;
  final String? email;
  final String? reasonForRequest;
  final String? whatYouNeedInAMentor;
  final List<String> assignees;
  final String? droppedReason;
  final String? clientId;
  final ClientStatus status;

  static const assigneesKey = 'assignees';
  static const statusKey = 'status';

  ClientDto({
    required this.id,
    required this.name,
    required this.avatar,
    required this.status,
    this.reasonForRequest,
    this.whatYouNeedInAMentor,
    this.email,
    required this.createdAt,
    required this.updatedAt,
    this.assignees = const [],
    this.droppedReason,
    this.clientId,
  });

  ConversationUserEntity toConversationUserEntity() {
    return ConversationUserEntity(userId: id, name: name, avatar: avatar);
  }

  UserDto toUserDto(){
    return UserDto(name: name, accountType: AccountType.citizen,avatar: avatar,email: email,userId: id,);
  }
  // copyWith method
  ClientDto copyWith({
    String? id,
    String? name,
    String? avatar,
    int? createdAt,
    String? email,
    String? whatYouNeedInAMentor,
    String? reasonForRequest,
    ClientStatus? status,
    int? updatedAt,
    List<String>? assignees,
    String? droppedReason,
    String? clientId,
  }) {
    return ClientDto(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      whatYouNeedInAMentor: whatYouNeedInAMentor ?? this.whatYouNeedInAMentor,
      reasonForRequest: reasonForRequest ?? this.whatYouNeedInAMentor,
      email: email ?? this.email,
      updatedAt: updatedAt ?? this.updatedAt,
      assignees: assignees ?? this.assignees,
      droppedReason: droppedReason ?? this.droppedReason,
      clientId: clientId ?? this.clientId,
    );
  }

  // toJson method
  Map<String, dynamic> toJson() {
    final nameParts = name.split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.skip(1).join(' ');
    
    // Map ClientStatus back to case_status
    final caseStatus = status == ClientStatus.pending ? 'intake' :
                       status == ClientStatus.active ? 'active' :
                       status == ClientStatus.dropped ? 'dropped' :
                       status == ClientStatus.decline ? 'decline' :
                       'intake';
    
    return {
      'person_id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'case_status': caseStatus,
      'account_status': 'active',
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // AppointmentUserDto toAppointmentUserDto() {
  //   return AppointmentUserDto(
  //       userId: id,
  //       name: name,
  //       avatar: avatar ??
  //           'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541');
  // }

  // fromJson method
  factory ClientDto.fromJson(Map<String, dynamic> json) {
    // Convert name from first_name + last_name
    final firstName = json['first_name'] ?? '';
    final lastName = json['last_name'] ?? '';
    final fullName = '${firstName} ${lastName}'.trim();
    
    // Map case_status to ClientStatus
    final caseStatus = json['case_status'] ?? 'intake';
    final status = caseStatus == 'intake' ? ClientStatus.pending :
                   caseStatus == 'active' ? ClientStatus.active :
                   caseStatus == 'dropped' ? ClientStatus.dropped :
                   caseStatus == 'decline' ? ClientStatus.decline :
                   ClientStatus.pending;
    
    final createdAt = json['created_at'];
    final updatedAt = json['updated_at'];
    
    return ClientDto(
      id: json['person_id'] ?? json['id'],
      name: fullName.isNotEmpty ? fullName : 'Unknown',
      avatar: AppConstants.avatar, // persons table doesn't have avatar
      status: status,
      createdAt: createdAt is int ? createdAt : DateTime.now().millisecondsSinceEpoch,
      updatedAt: updatedAt is int ? updatedAt : DateTime.now().millisecondsSinceEpoch,
      assignees: [], // Will be populated separately from client_assignees table
      droppedReason: null, // Not in persons table
      clientId: json['person_id'] ?? json['id'],
      email: json['email'],
      reasonForRequest: null, // Not in persons table
      whatYouNeedInAMentor: null, // Not in persons table
    );
  }
}
