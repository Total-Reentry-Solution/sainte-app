import 'package:reentry/data/model/mentor_request.dart';
import 'package:reentry/exception/app_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/config/supabase_config.dart';
import 'mentor_repository_interface.dart';

class MentorRepository extends MentorRepositoryInterface {
  static const String mentorRequestsTable = 'mentor_requests';
  static const String clientsTable = 'clients';

  @override
  Future<MentorRequest> requestMentor(MentorRequest data) async {
    try {
      // Check if user already has a mentor request and replace it
      await SupabaseConfig.client
          .from(mentorRequestsTable)
          .delete()
          .eq('user_id', data.userId ?? '');
      
      // Create new mentor request
      final mentorRequestPayload = data.copyWith(id: ''); // Will be auto-generated
      final mentorRequestResult = await SupabaseConfig.client
          .from(mentorRequestsTable)
          .insert(mentorRequestPayload.toJson())
          .select()
          .single();
      
      // Create or update client record
      final clientPayload = data.toClient().copyWith(id: data.userId);
      await SupabaseConfig.client
          .from(clientsTable)
          .upsert(clientPayload.toJson());
      
      return MentorRequest.fromJson(mentorRequestResult);
    } catch (e) {
      throw BaseExceptions('Failed to request mentor: ${e.toString()}');
    }
  }
}
