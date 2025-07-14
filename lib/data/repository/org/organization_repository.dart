import 'package:reentry/data/repository/user/user_repository.dart';
import '../../enum/account_type.dart';
import '../../model/user_dto.dart';
import 'package:reentry/core/config/supabase_config.dart';

class OrganizationRepository {
  final repository = UserRepository();
  static const String table = 'user_profiles';

  Future<UserDto?> findOrganizationByCode(String code) async {
    // COMMENTED OUT: Filtering by accountType, which does not exist in user_profiles schema
    /*
    final data = await SupabaseConfig.client
        .from(table)
        .select()
        .eq('createdAt', DateTime.fromMillisecondsSinceEpoch(int.parse(code)).toIso8601String())
        .eq(UserDto.keyAccountType, AccountType.reentry_orgs.name)
        .single();
    */
    final data = await SupabaseConfig.client
        .from(table)
        .select()
        .eq('createdAt', DateTime.fromMillisecondsSinceEpoch(int.parse(code)).toIso8601String())
        .single();
    if (data == null) return null;
    return UserDto.fromJson(data as Map<String, dynamic>);
  }

  Future<UserDto?> removeFromOrganization(String orgId, String userId) async {
    // COMMENTED OUT: organizations field does not exist in user_profiles schema
    /*
    UserDto? user = await repository.getUserById(userId);
    if (user == null) {
      throw Exception("User not found");
    }
    user = user.copyWith(
        organizations: user.organizations.where((e) => e != orgId).toList());
    print('update user -> ${user.organizations}');
    await repository.updateUser(user);
    return user;
    */
    return await repository.getUserById(userId);
  }

  Future<UserDto?> joinOrganization(String orgId, String userId) async {
    // COMMENTED OUT: organizations field does not exist in user_profiles schema
    /*
    UserDto? user = await repository.getUserById(userId);
    if (user == null) {
      throw Exception("User not found");
    }
    user = user.copyWith(
        organizations: user.organizations.contains(orgId)
            ? user.organizations
            : [...user.organizations, orgId]);
    await repository.updateUser(user);
    return user;
    */
    return await repository.getUserById(userId);
  }

  Future<List<UserDto>> getCareTeamByOrganization(String orgId) async {
    final data = await SupabaseConfig.client
        .from(table)
        .select()
        .contains('organizations', [orgId])
        .eq(UserDto.keyDeleted, false)
        .neq(UserDto.keyAccountType, AccountType.citizen.name);
    if (data == null) return [];
    return (data as List)
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserDto>> getCitizensByOrganization(String orgId) async {
    final data = await SupabaseConfig.client
        .from(table)
        .select()
        .contains('organizations', [orgId])
        .neq(UserDto.keyDeleted, true)
        .eq(UserDto.keyAccountType, AccountType.citizen.name);
    if (data == null) return [];
    return (data as List)
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserDto>> getUsersByOrganization(String orgId) async {
    final data = await SupabaseConfig.client
        .from(table)
        .select()
        .contains('organizations', [orgId])
        .neq(UserDto.keyDeleted, true);
    if (data == null) return [];
    return (data as List)
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserDto>> getOrganizationsOfCareTeam(UserDto user) async {
    if (user.organizations.isEmpty) {
      return [];
    }
    final data = await SupabaseConfig.client
        .from(table)
        .select()
        .inFilter('userId', user.organizations)
        .eq(UserDto.keyAccountType, AccountType.reentry_orgs.name)
        .neq(UserDto.keyDeleted, true);
    if (data == null) return [];
    return (data as List)
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserDto>> getAllOrganizations() async {
    final data = await SupabaseConfig.client
        .from(table)
        .select()
        .eq(UserDto.keyAccountType, AccountType.reentry_orgs.name)
        .neq(UserDto.keyDeleted, true);
    if (data == null) return [];
    return (data as List)
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserDto>> getAllOrganizationsByIds(List<String> ids) async {
    final data = await SupabaseConfig.client
        .from(table)
        .select()
        .inFilter(UserDto.keyUserId, ids)
        .neq(UserDto.keyDeleted, true);
    if (data == null) return [];
    return (data as List)
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
