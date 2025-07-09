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
    final data = await SupabaseConfig.client
        .from(table)
        .select()
        .eq(UserDto.keyAccountType, type.name)
        .neq(UserDto.keyDeleted, true);
    if (data == null) return [];
    return (data as List)
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserDto>> getAllCareTeam() async {
    final data = await SupabaseConfig.client
        .from(table)
        .select()
        .neq(UserDto.keyAccountType, AccountType.citizen.name);
    if (data == null) return [];
    return (data as List)
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminStatEntity> fetchStats() async {
    final user = await PersistentStorage.getCurrentUser();
    List<UserDto> citizens = [];
    List<UserDto> careTeam = [];
    if (user?.accountType == AccountType.reentry_orgs) {
      careTeam = await repo.getCareTeamByOrganization(user?.userId ?? '');
      citizens = await repo.getCitizensByOrganization(user?.userId ?? '');
    } else if (user?.accountType == AccountType.admin) {
      citizens = await getUsers(AccountType.citizen);
      careTeam = await getNonCitizens();
    } else {
      final clients =
          await ClientRepository().getUserClients(userId: user?.userId);
      citizens = clients.map((e) => e.toUserDto()).toList();
    }
    return AdminStatEntity(
        appointments: 0,
        careTeam: careTeam.length,
        totalCitizens: citizens.length);
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
