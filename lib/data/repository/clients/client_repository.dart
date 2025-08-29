import 'package:reentry/data/model/client_dto.dart';
import 'package:reentry/data/repository/clients/client_repository_interface.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/core/config/supabase_config.dart';

class ClientRepository extends ClientRepositoryInterface {
  // static const String table = 'clients'; // REMOVE THIS LINE

  @override
  Future<List<ClientDto>> getRecommendedClients() async {
    final user = await PersistentStorage.getCurrentUser();
    if (user == null || user.userId == null) {
      return [];
    }
    
    final assignments = await SupabaseConfig.client
        .from('client_assignees')
        .select('client_id')
        .eq('assignee_id', user.userId!);

    final clientIds =
        (assignments as List).map((e) => e['client_id'] as String).toList();
    if (clientIds.isEmpty) return [];

    final data = await SupabaseConfig.client
        .from('persons')
        .select('*, client_assignees(assignee_id)')
        .eq('account_status', 'active')
        .eq('case_status', 'intake')
        .in_('person_id', clientIds);

    return (data as List)
        .map((e) => ClientDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ClientDto>> getUserClients({String? userId}) async {
    String? id = userId;
    if (userId == null) {
      final user = await PersistentStorage.getCurrentUser();
      if (user == null) {
        return [];
      }
      id = user.userId;
    }
    if (id == null) {
      return [];
    }
    
    final assignments = await SupabaseConfig.client
        .from('client_assignees')
        .select('client_id')
        .eq('assignee_id', id);

    final clientIds =
        (assignments as List).map((e) => e['client_id'] as String).toList();
    if (clientIds.isEmpty) return [];

    final data = await SupabaseConfig.client
        .from('persons')
        .select('*, client_assignees(assignee_id)')
        .eq('account_status', 'active')
        .in_('person_id', clientIds);

    return (data as List)
        .map((e) => ClientDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ClientDto>> getAllClients() async {
    try {
      // Get all active persons directly
      final data = await SupabaseConfig.client
          .from('persons')
          .select('*, client_assignees(assignee_id)')
          .eq('account_status', 'active');

      return (data as List)
          .map((e) => ClientDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error in getAllClients: $e');
      return [];
    }
  }

  @override
  Future<void> updateClient(ClientDto client) async {
    await SupabaseConfig.client
        .from('persons')
        .update(client.toJson())
        .eq('person_id', client.id);
  }

  Future<ClientDto?> getClientById(String id) async {
    final data = await SupabaseConfig.client
        .from('persons')
        .select('*, client_assignees(assignee_id)')
        .eq('person_id', id)
        .eq('account_status', 'active')
        .single();
    if (data == null) return null;
    return ClientDto.fromJson(data as Map<String, dynamic>);
  }

  // Search for citizens by name or email
  Future<List<ClientDto>> searchCitizens(String searchTerm) async {
    print('=== SEARCH DEBUG ===');
    print('Searching for: "$searchTerm"');
    print('Method: searchCitizens in ClientRepository');
    
    if (searchTerm.isEmpty) {
      print('Empty search term, returning all citizens');
      return getAllClients();
    }
    
    try {
      print('Making search query directly from persons table...');
      print('Search term: "$searchTerm"');
      
      // Search directly in persons table
      final data = await SupabaseConfig.client
          .from('persons')
          .select('*, client_assignees(assignee_id)')
          .eq('account_status', 'active')
          .or('first_name.ilike.%${searchTerm}%,last_name.ilike.%${searchTerm}%,email.ilike.%${searchTerm}%');
      
      print('Search results: ${data?.length ?? 0}');
      print('Raw search results: $data');
      
      if (data == null) {
        print('No data returned from search');
        return [];
      }
      
      final results = (data as List)
          .map((e) => ClientDto.fromJson(e as Map<String, dynamic>))
          .toList();
      
      print('Processed ${results.length} results');
      if (results.isNotEmpty) {
        print('Sample results: ${results.take(3).map((e) => '${e.name} (${e.email})').toList()}');
      } else {
        print('No results found after processing');
      }
      print('===================');
      
      return results;
    } catch (e) {
      print('Error in search: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Assign a case manager to a citizen
  Future<void> assignCaseManagerToCitizen(
      String citizenId, String caseManagerId) async {
    await SupabaseConfig.client.from('client_assignees').insert({
      'client_id': citizenId,
      'assignee_id': caseManagerId,
    });
  }

  // Remove case manager assignment from a citizen
  Future<void> removeCaseManagerFromCitizen(
      String citizenId, String caseManagerId) async {
    await SupabaseConfig.client
        .from('client_assignees')
        .delete()
        .eq('client_id', citizenId)
        .eq('assignee_id', caseManagerId);
  }
}
