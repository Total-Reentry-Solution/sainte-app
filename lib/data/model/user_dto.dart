import 'package:http/http.dart';
import 'package:reentry/core/const/app_constants.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/enum/client_status.dart';
import 'package:reentry/data/model/appointment_dto.dart';
import 'package:reentry/data/model/client_dto.dart';
import 'package:reentry/data/model/verification_question.dart';
import 'package:reentry/data/model/mood.dart';
import '../../ui/modules/appointment/create_appointment_screen.dart';
import '../../ui/modules/messaging/entity/conversation_user_entity.dart';

class IntakeForm {
  final String? whyAmIWhere;
  final String? whatDoIWantToContribute;
  final String? howDoIWantToGrow;
  final String? whereAmIGoing;
  final String? whatWouldIWantToExperienceInLife;
  final String? ifIAchievedAllMyLifeGoals;
  final String? whatIsMostImportantInMyLife;
  final String? myLifesMissionStatement;
  final String? myVisionStatement;
  final String? whereAmINow;
  final String? howDoIGetThere;

  IntakeForm({
    this.whyAmIWhere,
    this.whatDoIWantToContribute,
    this.howDoIWantToGrow,
    this.whereAmIGoing,
    this.whatWouldIWantToExperienceInLife,
    this.ifIAchievedAllMyLifeGoals,
    this.whatIsMostImportantInMyLife,
    this.myLifesMissionStatement,
    this.myVisionStatement,
    this.whereAmINow,
    this.howDoIGetThere,
  });

  Map<String, dynamic> toJson() {
    return {
      'whyAmIWhere': whyAmIWhere,
      'whatDoIWantToContribute': whatDoIWantToContribute,
      'howDoIWantToGrow': howDoIWantToGrow,
      'whereAmIGoing': whereAmIGoing,
      'whatWouldIWantToExperienceInLife': whatWouldIWantToExperienceInLife,
      'ifIAchievedAllMyLifeGoals': ifIAchievedAllMyLifeGoals,
      'whatIsMostImportantInMyLife': whatIsMostImportantInMyLife,
      'myLifesMissionStatement': myLifesMissionStatement,
      'myVisionStatement': myVisionStatement,
      'whereAmINow': whereAmINow,
      'howDoIGetThere': howDoIGetThere,
    };
  }

  factory IntakeForm.fromJson(Map<String, dynamic> json) {
    return IntakeForm(
      whyAmIWhere: json['whyAmIWhere'],
      whatDoIWantToContribute: json['whatDoIWantToContribute'],
      howDoIWantToGrow: json['howDoIWantToGrow'],
      whereAmIGoing: json['whereAmIGoing'],
      whatWouldIWantToExperienceInLife: json['whatWouldIWantToExperienceInLife'],
      ifIAchievedAllMyLifeGoals: json['ifIAchievedAllMyLifeGoals'],
      whatIsMostImportantInMyLife: json['whatIsMostImportantInMyLife'],
      myLifesMissionStatement: json['myLifesMissionStatement'],
      myVisionStatement: json['myVisionStatement'],
      whereAmINow: json['whereAmINow'],
      howDoIGetThere: json['howDoIGetThere'],
    );
  }

  IntakeForm copyWith({
    String? whyAmIWhere,
    String? whatDoIWantToContribute,
    String? howDoIWantToGrow,
    String? whereAmIGoing,
    String? whatWouldIWantToExperienceInLife,
    String? ifIAchievedAllMyLifeGoals,
    String? whatIsMostImportantInMyLife,
    String? myLifesMissionStatement,
    String? myVisionStatement,
    String? whereAmINow,
    String? howDoIGetThere,
  }) {
    return IntakeForm(
      whyAmIWhere: whyAmIWhere ?? this.whyAmIWhere,
      whatDoIWantToContribute:
          whatDoIWantToContribute ?? this.whatDoIWantToContribute,
      howDoIWantToGrow: howDoIWantToGrow ?? this.howDoIWantToGrow,
      whereAmIGoing: whereAmIGoing ?? this.whereAmIGoing,
      whatWouldIWantToExperienceInLife: whatWouldIWantToExperienceInLife ??
          this.whatWouldIWantToExperienceInLife,
      ifIAchievedAllMyLifeGoals:
          ifIAchievedAllMyLifeGoals ?? this.ifIAchievedAllMyLifeGoals,
      whatIsMostImportantInMyLife:
          whatIsMostImportantInMyLife ?? this.whatIsMostImportantInMyLife,
      myLifesMissionStatement:
          myLifesMissionStatement ?? this.myLifesMissionStatement,
      myVisionStatement: myVisionStatement ?? this.myVisionStatement,
      whereAmINow: whereAmINow ?? this.whereAmINow,
      howDoIGetThere: howDoIGetThere ?? this.howDoIGetThere,
    );
  }
}

enum VerificationStatus{
  pending, rejected,
  verified,none
}

class VerificationRequestDto {
  final String? id;
  final String? userId;
  final String? questionId;
  final String? answer;
  final VerificationStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? verificationStatus;
  final String? date;
  final Map<String, String> form;
  final String? rejectionReason;

  VerificationRequestDto({
    this.id,
    this.userId,
    this.questionId,
    this.answer,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.verificationStatus,
    this.date,
    this.form = const {},
    this.rejectionReason,
  });

  // CopyWith method
  VerificationRequestDto copyWith({
    String? id,
    String? userId,
    String? questionId,
    String? answer,
    VerificationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? verificationStatus,
    String? date,
    Map<String, String>? form,
    String? rejectionReason,
  }) {
    return VerificationRequestDto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      answer: answer ?? this.answer,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      date: date ?? this.date,
      form: form ?? this.form,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  // From JSON
  factory VerificationRequestDto.fromJson(Map<String, dynamic> json) {
    return VerificationRequestDto(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      questionId: json['question_id'] as String?,
      answer: json['answer'] as String?,
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VerificationStatus.pending,
      ),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      verificationStatus: json['verificationStatus'] as String?,
      date: json['date'] as String?,
      form: Map<String, String>.from(json['form'] ?? {}),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'question_id': questionId,
      'answer': answer,
      'status': status.name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'verificationStatus': verificationStatus ?? VerificationStatus.pending,
      'date': date,
      'form': form,
      'rejectionReason': rejectionReason,
    };
  }
}

class UserDto {
  final String? userId;
  final String name;
  final AccountType accountType;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final IntakeForm? intakeForm;
  final VerificationRequestDto? verification;
  final String? avatar;
  final List<String> organizations;
  final String? dob;
  final String? jobTitle;
  final List<String> services;
  final String? about;
  final List<String> assignee;
  final String? feelingsDate;
  final String? activityDate;
  final String? organization;
  final String? email;
  final String? userCode;
  final String? personId;
  final bool deleted;
  final List<MoodLog> moodLogs;
  final String? organizationAddress;
  final String? pushNotificationToken;
  final String? reasonForAccountDeletion;
  final String? supervisorsName;
  final String? supervisorsEmail;
  final UserAvailability? availability;
  final String? phoneNumber;
  final String? password;
  final UserSettings settings;
  final List<String> mentors;
  final List<MoodLog> moodTimeLine;
  final String? verificationStatus;
  final List<String> officers;
  final String? address;

  ConversationUserEntity toConversationUserEntity() {
    return ConversationUserEntity(
        userId: userId ?? '', name: name, avatar: avatar);
  }

  static const keyUserId = 'userId';
  static const keyAccountType = 'account_type';
  static const keyDeleted = 'deleted';
  static const keyVerificationStatus = 'verificationStatus';

  ClientDto toClient() => ClientDto(
      id: userId ?? '',
      name: name,
      avatar: avatar ?? AppConstants.avatar,
      status: ClientStatus.active,
      createdAt: 0,
      updatedAt: 0);

  // AppointmentUserDto toAppointmentUserDto() => AppointmentUserDto(
  //     userId: userId ?? '',
  //     name: name,
  //     avatar: avatar ?? AppConstants.avatar,
  // );


  bool showFeeling(){
    if(moodLogs.isEmpty){
      return true;
    }
    final today = DateTime.now();
    final feelingDate = DateTime.parse(moodLogs.last.date.toIso8601String());
    return today.day != feelingDate.day || today.month != feelingDate.month || today.year != feelingDate.year;
  }

  bool showActivity(){
    if(activityDate==null){
      return true;
    }
    final today = DateTime.now();
    final activityDateTime = DateTime.parse(activityDate!);
    return today.day != activityDateTime.day || today.month != activityDateTime.month || today.year != activityDateTime.year;
  }

  const UserDto({
    required this.name,
    required this.accountType,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.intakeForm,
    this.verification,
    this.avatar,
    this.organizations = const [],
    this.dob,
    this.jobTitle,
    this.services = const [],
    this.about,
    this.assignee = const [],
    this.feelingsDate,
    this.activityDate,
    this.organization,
    this.email,
    this.userCode,
    this.personId,
    this.deleted = false,
    this.moodLogs = const [],
    this.organizationAddress,
    this.pushNotificationToken,
    this.reasonForAccountDeletion,
    this.supervisorsName,
    this.supervisorsEmail,
    this.availability,
    this.phoneNumber,
    this.password,
    this.settings = const UserSettings(),
    this.mentors = const [],
    this.moodTimeLine = const [],
    this.verificationStatus,
    this.officers = const [],
    this.address,
  });

  // copyWith method
  UserDto copyWith({
    String? userId,
    String? name,
    AccountType? accountType,
    DateTime? createdAt,
    DateTime? updatedAt,
    IntakeForm? intakeForm,
    VerificationRequestDto? verification,
    String? avatar,
    List<String>? organizations,
    String? dob,
    String? jobTitle,
    List<String>? services,
    String? about,
    List<String>? assignee,
    String? feelingsDate,
    String? activityDate,
    String? organization,
    String? email,
    String? userCode,
    String? personId,
    bool? deleted,
    List<MoodLog>? moodLogs,
    String? organizationAddress,
    String? pushNotificationToken,
    String? verificationStatus,
    UserSettings? settings,
    List<MoodLog>? moodTimeLine,
    List<String>? mentors,
    String? supervisorsName,
    String? supervisorsEmail,
    String? phoneNumber,
    String? password,
    String? address,
  }) {
    return UserDto(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      intakeForm: intakeForm ?? this.intakeForm,
      verification: verification ?? this.verification,
      avatar: avatar ?? this.avatar,
      organizations: organizations ?? this.organizations,
      dob: dob ?? this.dob,
      jobTitle: jobTitle ?? this.jobTitle,
      services: services ?? this.services,
      about: about ?? this.about,
      assignee: assignee ?? this.assignee,
      feelingsDate: feelingsDate ?? this.feelingsDate,
      activityDate: activityDate ?? this.activityDate,
      organization: organization ?? this.organization,
      email: email ?? this.email,
      userCode: userCode ?? this.userCode,
      personId: personId ?? this.personId,
      deleted: deleted ?? this.deleted,
      moodLogs: moodLogs ?? this.moodLogs,
      organizationAddress: organizationAddress ?? this.organizationAddress,
      pushNotificationToken: pushNotificationToken ?? this.pushNotificationToken,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      settings: settings ?? this.settings,
      moodTimeLine: moodTimeLine ?? this.moodTimeLine,
      mentors: mentors ?? this.mentors,
      supervisorsName: supervisorsName ?? this.supervisorsName,
      supervisorsEmail: supervisorsEmail ?? this.supervisorsEmail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'account_type': accountType.name,
      'deleted': deleted,
      'verificationStatus': verificationStatus,
      'verification': verification ==null?null:VerificationRequestDto.fromJson(verification!.toJson()),
      'intakeForm': intakeForm?.toJson(),
      'moodLogs': moodLogs.map((e) => e.toJson()).toList(),
      'moodTimeLine': moodTimeLine.map((e) => e.toJson()).toList(),
      'services': services,
      'assignee': assignee,
      'job_title': jobTitle,
      'organization': organization,
      'organization_address': organizationAddress,
      'organizations': organizations,
      'activityDate': activityDate,
      'supervisors_name': supervisorsName,
      'dob': dob,
      'availability': availability?.toJson(),
      'mentors': mentors,
      'push_notification_token': pushNotificationToken,
      'userCode': userCode,
      'person_id': personId,
      'officers': officers,
      'password': password,
      'settings': settings.toJson(),
      'reason_for_account_deletion': reasonForAccountDeletion,
      'supervisors_email': supervisorsEmail,
      'address': address,
    };
  }

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      userId: json['id'],
      name: json['name'] ?? '',
      accountType: json['account_type'] != null 
          ? AccountType.values.firstWhere(
              (e) => e.name == json['account_type'],
              orElse: () => AccountType.citizen)
          : AccountType.citizen,
      email: json['email'],
      phoneNumber: json['phoneNumber'] ?? json['phone'],
      avatar: json['avatar'] ?? json['avatar_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      deleted: json['deleted'] ?? false,
      verificationStatus: null, // Not in schema
      verification: null, // Not in schema
      intakeForm: null, // Not in schema
      moodLogs: const [],
      moodTimeLine: const [],
      services: const [],
      assignee: const [],
      jobTitle: json['job_title'],
      organization: json['organization'],
      organizationAddress: json['organization_address'],
      organizations: json['organizations'] != null
          ? List<String>.from(json['organizations'])
          : const [],
      activityDate: null,
      supervisorsName: json['supervisors_name'],
      dob: json['dob'],
      availability: null,
      mentors: const [],
      pushNotificationToken: json['push_notification_token'],
      userCode: json['userCode'],
      personId: json['person_id'],
      officers: const [],
      password: null,
      settings: json['settings'] != null ? UserSettings.fromJson(json['settings']) : const UserSettings(),
      about: null,
      reasonForAccountDeletion: json['reason_for_account_deletion'],
      supervisorsEmail: json['supervisors_email'],
      address: json['address'],
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,
    };
  }

  factory UserAvailability.fromJson(Map<String, dynamic> json) {
    return UserAvailability(
      monday: json['monday'],
      tuesday: json['tuesday'],
      wednesday: json['wednesday'],
      thursday: json['thursday'],
      friday: json['friday'],
      saturday: json['saturday'],
      sunday: json['sunday'],
    );
  }
}

class UserSettings {
  final bool pushNotification;
  final bool emailNotification;
  final bool smsNotification;
  final String? language;
  final String? theme;

  const UserSettings({
    this.pushNotification = true,
    this.emailNotification = true,
    this.smsNotification = false,
    this.language,
    this.theme,
  });

  Map<String, dynamic> toJson() {
    return {
      'push_notification': pushNotification,
      'email_notification': emailNotification,
      'sms_notification': smsNotification,
      'language': language,
      'theme': theme,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      pushNotification: json['push_notification'] ?? true,
      emailNotification: json['email_notification'] ?? true,
      smsNotification: json['sms_notification'] ?? false,
      language: json['language'],
      theme: json['theme'],
    );
  }

  UserSettings copyWith({
    bool? pushNotification,
    bool? emailNotification,
    bool? smsNotification,
    String? language,
    String? theme,
  }) {
    return UserSettings(
      pushNotification: pushNotification ?? this.pushNotification,
      emailNotification: emailNotification ?? this.emailNotification,
      smsNotification: smsNotification ?? this.smsNotification,
      language: language ?? this.language,
      theme: theme ?? this.theme,
    );
  }
}
