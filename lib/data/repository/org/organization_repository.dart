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
    UserDto? user = await repository.getUserById(userId);
    if (user == null) {
      throw Exception("User not found");
    }
    
    // Remove organization from user's organizations list
    user = user.copyWith(
        organizations: user.organizations.where((e) => e != orgId).toList());
    
    // Update the user in the database
    await repository.updateUser(user);
    return user;
  }

  Future<UserDto?> joinOrganization(String orgId, String userId) async {
    UserDto? user = await repository.getUserById(userId);
    if (user == null) {
      throw Exception("User not found");
    }
    
    // Check if user is already a member of this organization
    if (user.organizations.contains(orgId)) {
      return user; // Already a member
    }
    
    // Add organization to user's organizations list
    user = user.copyWith(
        organizations: [...user.organizations, orgId]);
    
    // Update the user in the database
    await repository.updateUser(user);
    return user;
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

  // Check if an organization exists by name
  Future<bool> organizationExists(String organizationName) async {
    try {
      final data = await SupabaseConfig.client
          .from('organizations')
          .select('id')
          .eq('name', organizationName)
          .maybeSingle();
      return data != null;
    } catch (e) {
      print('Error checking if organization exists: $e');
      return false;
    }
  }

  // Get all organization names for dropdown/autocomplete
  Future<List<String>> getAllOrganizationNames() async {
    try {
      final data = await SupabaseConfig.client
          .from('organizations')
          .select('name')
          .order('name');
      if (data == null) return [];
      return (data as List)
          .map((e) => e['name'] as String)
          .toList();
    } catch (e) {
      print('Error fetching organization names: $e');
      return [];
    }
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
