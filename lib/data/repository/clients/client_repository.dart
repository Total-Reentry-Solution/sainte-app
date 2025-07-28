import 'package:reentry/data/model/client_dto.dart';
import 'package:reentry/data/repository/clients/client_repository_interface.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/core/config/supabase_config.dart';

class ClientRepository extends ClientRepositoryInterface {
  // static const String table = 'clients'; // REMOVE THIS LINE

  @override
  Future<List<ClientDto>> getRecommendedClients() async {
    final user = await PersistentStorage.getCurrentUser();
    if (user == null) {
      return [];
    }
    final data = await SupabaseConfig.client
        .from('clients') // REMOVE THIS LINE
        .select()
        .contains(ClientDto.assigneesKey, [user.userId ?? ''])
        .eq(ClientDto.statusKey, ClientStatus.pending.index);
    if (data == null) return [];
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
    final data = await SupabaseConfig.client
        .from('clients') // REMOVE THIS LINE
        .select()
        .contains(ClientDto.assigneesKey, [id]);
    if (data == null) return [];
    return (data as List)
        .map((e) => ClientDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ClientDto>> getAllClients() async {
    final data = await SupabaseConfig.client
        .from('clients') // REMOVE THIS LINE
        .select();
    if (data == null) return [];
    return (data as List)
        .map((e) => ClientDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateClient(ClientDto client) async {
    await SupabaseConfig.client
        .from('clients') // REMOVE THIS LINE
        .update(client.toJson())
        .eq('id', client.id);
  }

  Future<ClientDto?> getClientById(String id) async {
    final data = await SupabaseConfig.client
        .from('clients') // REMOVE THIS LINE
        .select()
        .eq('id', id)
        .single();
    if (data == null) return null;
    return ClientDto.fromJson(data as Map<String, dynamic>);
  }
}
