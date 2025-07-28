import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/repository/admin/admin_repository_interface.dart';
import 'package:reentry/data/repository/appointment/appointment_repository.dart';
import 'package:reentry/data/repository/clients/client_repository.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/ui/modules/admin/admin_stat_state.dart';
import 'package:reentry/core/config/supabase_config.dart';

import '../mentor/mentor_repository.dart';
import '../org/organization_repository.dart';

class AdminRepository implements AdminRepositoryInterface {
  final repo = OrganizationRepository();
  final _mentorRepo = MentorRepository();
  static const String table = 'user_profiles';

  @override
  Future<List<UserDto>> getUsers(AccountType type) async {
    // COMMENTED OUT: Filtering by accountType and deleted, which do not exist in user_profiles schema
    /*
    final data = await SupabaseConfig.client
        .from(table)
        .select()
        .eq(UserDto.keyAccountType, type.name)
        .neq(UserDto.keyDeleted, true);
    */
    final data = await SupabaseConfig.client
        .from(table)
        .select();
    if (data == null) return [];
    return (data as List)
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserDto>> getAllCareTeam() async {
    // COMMENTED OUT: Filtering by accountType, which does not exist in user_profiles schema
    /*
    final data = await SupabaseConfig.client
        .from(table)
        .select()
        .neq(UserDto.keyAccountType, AccountType.citizen.name);
    */
    final data = await SupabaseConfig.client
        .from(table)
        .select();
    if (data == null) return [];
    return (data as List)
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminStatEntity> fetchStats() async {
    final user = await PersistentStorage.getCurrentUser();
    List<UserDto> citizens = [];
    List<UserDto> careTeam = [];
    int appointmentCount = 0;
    int goalCount = 0;
    int milestoneCount = 0;
    int incidentCount = 0;

    try {
      // Get userId for all queries
      final userId = user?.userId;
      // Activities count (person_activities.user_id)
      final activitiesData = userId != null && userId.isNotEmpty
        ? await SupabaseConfig.client
            .from('person_activities')
            .select('id')
            .eq('user_id', userId)
        : [];
      final activitiesCount = activitiesData?.length ?? 0;

      // Appointments count (appointments.creator_id or participant_id)
      final appointmentsData = userId != null && userId.isNotEmpty
        ? await SupabaseConfig.client
            .from('appointments')
            .select('id')
            .or('creator_id.eq.$userId,participant_id.eq.$userId')
        : [];
      appointmentCount = appointmentsData?.length ?? 0;

      // Goals count (person_goals.person_id)
      final goalsData = userId != null && userId.isNotEmpty
        ? await SupabaseConfig.client
            .from('person_goals')
            .select('goal_id')
            .eq('person_id', userId)
        : [];
      goalCount = goalsData?.length ?? 0;

      // Milestones count (person_milestones.person_id)
      final milestonesData = userId != null && userId.isNotEmpty
        ? await SupabaseConfig.client
            .from('person_milestones')
            .select('milestone_id')
            .eq('person_id', userId)
        : [];
      milestoneCount = milestonesData?.length ?? 0;

      // Mood logs count (mood_logs.user_id)
      final moodLogsData = userId != null && userId.isNotEmpty
        ? await SupabaseConfig.client
            .from('mood_logs')
            .select('mood_log_id')
            .eq('user_id', userId)
        : [];
      final moodLogsCount = moodLogsData?.length ?? 0;

      // Get incidents count from incidents table (global for now)
      final incidentsData = await SupabaseConfig.client
          .from('incidents')
          .select('id');
      incidentCount = incidentsData?.length ?? 0;

      if (user?.accountType == AccountType.reentry_orgs) {
        // For reentry organizations, get care team and citizens from case_care_team and persons
        final careTeamData = await SupabaseConfig.client
            .from('case_care_team')
            .select('user_id')
            .eq('status', 'active');
        
        final citizensData = await SupabaseConfig.client
            .from('persons')
            .select('person_id, first_name, last_name, email')
            .eq('account_status', 'active');

        careTeam = careTeamData?.map((e) => UserDto.fromJson({
          'id': e['user_id'],
          'first_name': 'Care Team Member',
          'last_name': '',
          'email': '',
          'account_type': 'care_team'
        })).toList() ?? [];

        citizens = citizensData?.map((e) => UserDto.fromJson({
          'id': e['person_id'],
          'first_name': e['first_name'] ?? '',
          'last_name': e['last_name'] ?? '',
          'email': e['email'] ?? '',
          'account_type': 'citizen'
        })).toList() ?? [];

      } else if (user?.accountType == AccountType.admin) {
        // For admin, get all citizens and care team
        final citizensData = await SupabaseConfig.client
            .from('persons')
            .select('person_id, first_name, last_name, email')
            .eq('account_status', 'active');

        final careTeamData = await SupabaseConfig.client
            .from('case_care_team')
            .select('user_id')
            .eq('status', 'active');

        citizens = citizensData?.map((e) => UserDto.fromJson({
          'id': e['person_id'],
          'first_name': e['first_name'] ?? '',
          'last_name': e['last_name'] ?? '',
          'email': e['email'] ?? '',
          'account_type': 'citizen'
        })).toList() ?? [];

        careTeam = careTeamData?.map((e) => UserDto.fromJson({
          'id': e['user_id'],
          'first_name': 'Care Team Member',
          'last_name': '',
          'email': '',
          'account_type': 'care_team'
        })).toList() ?? [];

      } else {
        // For other users, get their clients
        final clients = await ClientRepository().getUserClients(userId: user?.userId);
        citizens = clients.map((e) => e.toUserDto()).toList();
      }

      // Return stats with activities and mood logs
      return AdminStatEntity(
        appointments: appointmentCount,
        careTeam: careTeam.length,
        totalCitizens: citizens.length,
        goals: goalCount,
        milestones: milestoneCount,
        incidents: incidentCount,
        // Optionally add activitiesCount and moodLogsCount to AdminStatEntity if you want to display them
      );
    } catch (e) {
      print('Error fetching stats: $e');
      // Fallback to empty data if there's an error
      citizens = [];
      careTeam = [];
      appointmentCount = 0;
      goalCount = 0;
      milestoneCount = 0;
      incidentCount = 0;
    }

    return AdminStatEntity(
        appointments: appointmentCount,
        careTeam: careTeam.length,
        totalCitizens: citizens.length,
        goals: goalCount,
        milestones: milestoneCount,
        incidents: incidentCount);
  }

  Future<List<UserDto>> getNonCitizens() async {
    final data = await SupabaseConfig.client
        .from(table)
        .select()
        .neq(UserDto.keyAccountType, AccountType.citizen.name)
        .eq(UserDto.keyDeleted, false);
    if (data == null) return [];
    return (data as List)
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
