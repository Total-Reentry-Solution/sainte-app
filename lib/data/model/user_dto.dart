import 'package:http/http.dart';
import 'package:reentry/core/const/app_constants.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/enum/client_status.dart';
import 'package:reentry/data/enum/emotions.dart';
import 'package:reentry/data/model/appointment_dto.dart';
import 'package:reentry/data/model/client_dto.dart';
import 'package:reentry/data/model/verification_question.dart';
import '../../ui/modules/appointment/create_appointment_screen.dart';
import '../../ui/modules/messaging/entity/conversation_user_entity.dart';

class FeelingDto {
  final Emotions emotion;
  final DateTime date;

  const FeelingDto({required this.date, required this.emotion});

  Map<String, dynamic> toJson() {
    return {'emotion': emotion.name, 'date': date.toIso8601String()};
  }

  factory FeelingDto.fromJson(Map<String, dynamic> json) {
    return FeelingDto(
        date: DateTime.parse(json['date']),
        emotion: Emotions.values.byName(json['emotion']));
  }
}

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
  final bool deleted;
  final Emotions? emotion;
  final String? organizationAddress;
  final String? pushNotificationToken;
  final String? reasonForAccountDeletion;
  final String? supervisorsName;
  final FeelingDto? feelingToday;
  final String? supervisorsEmail;
  final UserAvailability? availability;
  final String? address;
  final String? phoneNumber;
  final String? password;
  final UserSettings settings;
  final List<String> mentors;
  final List<FeelingDto> feelingTimeLine;
  final String? verificationStatus;
  final List<String> officers;

  ConversationUserEntity toConversationUserEntity() {
    return ConversationUserEntity(
        userId: userId ?? '', name: name, avatar: avatar);
  }

  static const keyUserId = 'userId';
  static const keyAccountType = 'accountType';
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
    if(feelingToday==null){
      return true;
    }
    final today = DateTime.now();
    final feelingDate = DateTime.parse(feelingToday!.date.toIso8601String());
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
    this.deleted = false,
    this.emotion,
    this.organizationAddress,
    this.pushNotificationToken,
    this.reasonForAccountDeletion,
    this.supervisorsName,
    this.feelingToday,
    this.supervisorsEmail,
    this.availability,
    this.address,
    this.phoneNumber,
    this.password,
    this.settings = const UserSettings(),
    this.mentors = const [],
    this.feelingTimeLine = const [],
    this.verificationStatus,
    this.officers = const [],
  });

  // copyWith method
  UserDto copyWith({
    String? userId,
    String? name,
    AccountType? accountType,
    DateTime? createdAt,
    DateTime? updatedAt,
    FeelingDto? feelingToday,
    String? feelingsDate,
    UserSettings? settings,
    String? email,
    String? avatar,
    VerificationRequestDto? verification,
    IntakeForm? intakeForm,
    String? verificationStatus,
    String? about,
    List<FeelingDto>? feelingTimeLine,
    List<String>? services,
    List<String>? assignee,
    Emotions? emotion,
    String? jobTitle,
    String? organization,
    String? organizationAddress,
    List<String>? organizations,
    String? activityDate,
    String? supervisorsName,
    String? dob,
    UserAvailability? availability,
    List<String>? mentors,
    String? pushNotificationToken,
    String? userCode,
    List<String>? officers,
    String? password,
    bool? deleted,
    String? reasonForAccountDeletion,
    String? supervisorsEmail,
    String? address,
    String? phoneNumber,
  }) {
    return UserDto(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      feelingToday: feelingToday ?? this.feelingToday,
      feelingsDate: feelingsDate ?? this.feelingsDate,
      settings: settings ?? this.settings,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      verification: verification ?? this.verification,
      intakeForm: intakeForm ?? this.intakeForm,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      about: about ?? this.about,
      feelingTimeLine: feelingTimeLine ?? this.feelingTimeLine,
      services: services ?? this.services,
      assignee: assignee ?? this.assignee,
      emotion: emotion ?? this.emotion,
      jobTitle: jobTitle ?? this.jobTitle,
      organization: organization ?? this.organization,
      organizationAddress: organizationAddress ?? this.organizationAddress,
      organizations: organizations ?? this.organizations,
      activityDate: activityDate ?? this.activityDate,
      supervisorsName: supervisorsName ?? this.supervisorsName,
      dob: dob ?? this.dob,
      availability: availability ?? this.availability,
      mentors: mentors ?? this.mentors,
      pushNotificationToken: pushNotificationToken ?? this.pushNotificationToken,
      userCode: userCode ?? this.userCode,
      officers: officers ?? this.officers,
      password: password ?? this.password,
      deleted: deleted ?? this.deleted,
      reasonForAccountDeletion: reasonForAccountDeletion ?? this.reasonForAccountDeletion,
      supervisorsEmail: supervisorsEmail ?? this.supervisorsEmail,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
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
      'accountType': accountType.name,
      'deleted': deleted,
      'verificationStatus': verificationStatus,
      'verification': verification ==null?null:VerificationRequestDto.fromJson(verification!.toJson()),
      'intakeForm': intakeForm?.toJson(),
      'feelingToday': feelingToday?.toJson(),
      'feelingTimeLine': feelingTimeLine.map((e) => e.toJson()).toList(),
      'services': services,
      'assignee': assignee,
      'emotion': emotion?.name,
      'jobTitle': jobTitle,
      'organization': organization,
      'organizationAddress': organizationAddress,
      'organizations': organizations,
      'activityDate': activityDate,
      'supervisorsName': supervisorsName,
      'dob': dob,
      'availability': availability?.toJson(),
      'mentors': mentors,
      'pushNotificationToken': pushNotificationToken,
      'userCode': userCode,
      'officers': officers,
      'password': password,
      'settings': settings.toJson(),
      'reasonForAccountDeletion': reasonForAccountDeletion,
      'supervisorsEmail': supervisorsEmail,
      'address': address,
      'about': about,
    };
  }

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      userId: json['id'],
      name: json['name'] ?? '',
      accountType: AccountType.values.firstWhere(
        (e) => e.name == json['accountType'],
        orElse: () => AccountType.citizen,
      ),
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      avatar: json['avatar'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      deleted: json['deleted'] ?? false,
      verificationStatus: json['verificationStatus'],
      verification: json['verification'] ==null?null:VerificationRequestDto.fromJson(json['verification']),
      intakeForm: json['intakeForm'] != null ? IntakeForm.fromJson(json['intakeForm']) : null,
      feelingToday: json['feelingToday'] != null ? FeelingDto.fromJson(json['feelingToday']) : null,
      feelingTimeLine: (json['feelingTimeLine'] as List<dynamic>?)
          ?.map((e) => FeelingDto.fromJson(e))
          .toList() ?? [],
      services: List<String>.from(json['services'] ?? []),
      assignee: List<String>.from(json['assignee'] ?? []),
      emotion: json['emotion'] != null ? Emotions.values.byName(json['emotion']) : null,
      jobTitle: json['jobTitle'],
      organization: json['organization'],
      organizationAddress: json['organizationAddress'],
      organizations: List<String>.from(json['organizations'] ?? []),
      activityDate: json['activityDate'],
      supervisorsName: json['supervisorsName'],
      dob: json['dob'],
      availability: json['availability'] != null ? UserAvailability.fromJson(json['availability']) : null,
      mentors: List<String>.from(json['mentors'] ?? []),
      pushNotificationToken: json['pushNotificationToken'],
      userCode: json['userCode'],
      officers: List<String>.from(json['officers'] ?? []),
      password: json['password'],
      settings: json['settings'] != null ? UserSettings.fromJson(json['settings']) : const UserSettings(),
      reasonForAccountDeletion: json['reasonForAccountDeletion'],
      supervisorsEmail: json['supervisorsEmail'],
      address: json['address'],
      about: json['about'],
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
      'pushNotification': pushNotification,
      'emailNotification': emailNotification,
      'smsNotification': smsNotification,
      'language': language,
      'theme': theme,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      pushNotification: json['pushNotification'] ?? true,
      emailNotification: json['emailNotification'] ?? true,
      smsNotification: json['smsNotification'] ?? false,
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
