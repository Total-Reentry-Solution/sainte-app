import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/model/appointment_dto.dart';
import 'package:reentry/data/repository/appointment/appointment_repository_interface.dart';
import 'package:reentry/data/repository/user/user_repository.dart';
import 'package:reentry/data/shared/share_preference.dart';
import '../../../ui/modules/appointment/bloc/appointment_event.dart';
import '../../../core/config/supabase_config.dart';
import 'package:reentry/exception/app_exceptions.dart';

class AppointmentRepository extends AppointmentRepositoryInterface {

  Future<void> cancelAppointment(NewAppointmentDto payload) async {
    try {
      if (payload.id == null) {
        throw Exception('Appointment ID is required');
      }
      await SupabaseConfig.client
          .from(SupabaseConfig.appointmentsTable)
          .update({
            'status': AppointmentStatus.canceled.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', payload.id!);
    } catch (e) {
      throw Exception('Failed to cancel appointment: ${e.toString()}');
    }
  }

  Future<void> updateAppointmentStatus(
      AppointmentStatus status, String id) async {
    try {
      await SupabaseConfig.client
          .from(SupabaseConfig.appointmentsTable)
          .update({
            'status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to update appointment status: ${e.toString()}');
    }
  }

  @override
  Future<NewAppointmentDto> createAppointment(NewAppointmentDto payload) async {
    // Implement the logic to insert a new appointment into Supabase and return the created NewAppointmentDto
    final response = await SupabaseConfig.client
        .from(SupabaseConfig.appointmentsTable)
        .insert(payload.toJson())
        .select()
        .single();
    if (response == null) throw Exception('Failed to create appointment');
    return NewAppointmentDto.fromJson(response, payload.creatorId);
  }

  @override
  Future<void> deleteAppointment(AppointmentDto payload) async {
    try {
      if (payload.id == null) {
        throw BaseExceptions('Appointment ID is required for deletion');
      }
      
      await SupabaseConfig.client
          .from(SupabaseConfig.appointmentsTable)
          .delete()
          .eq('id', payload.id!);
    } catch (e) {
      throw BaseExceptions('Failed to delete appointment: ${e.toString()}');
    }
  }

  @override
  Future<List<AppointmentEntityDto>> getUserAppointments() async {
    final user = await PersistentStorage.getCurrentUser();
    
    try {
      final           response = await SupabaseConfig.client
              .from(SupabaseConfig.appointmentsTable)
              .select()
              .or('creator_id.eq.${user?.userId ?? ''},participant_id.eq.${user?.userId ?? ''}');
      
      // Convert to AppointmentEntityDto - you'll need to implement this conversion
      return [];
    } catch (e) {
      print('Error getting user appointments from Supabase: $e');
      return [];
    }
  }

  Future<Stream<List<NewAppointmentDto>>> getUserAppointmentInvitations(
      String userId) async {
    // For Supabase, you'll need to implement real-time subscriptions
    // This is a simplified version - you might want to use Supabase real-time
    return Stream.value([]);
  }

  Future<Stream<List<NewAppointmentDto>>> getUserAppointmentHistory(
      String userId) async {
    // For now, return a stream with the current appointments
    // In the future, you can implement real-time subscriptions with Supabase
    final appointments = await getUserAppointmentHistoryFuture(userId);
    return Stream.value(appointments);
  }

  Future<List<NewAppointmentDto>> getUserAppointmentHistoryFuture(
      String userId) async {
    try {
      final         response = await SupabaseConfig.client
            .from(SupabaseConfig.appointmentsTable)
            .select()
            .or('creator_id.eq.$userId,participant_id.eq.$userId')
            .order('date', ascending: false);
      
      List<NewAppointmentDto> appointments = [];
      for (var appointment in response) {
        // Fetch participant name if participant_id exists (mentor in system)
        String? participantName;
        String? participantAvatar;
        if (appointment['participant_id'] != null) {
          try {
            final participant = await UserRepository().getUserById(appointment['participant_id']);
            participantName = participant?.name;
            participantAvatar = participant?.avatar;
          } catch (e) {
            print('Error fetching participant info: $e');
          }
        }
        
        appointments.add(NewAppointmentDto(
          id: appointment['id'],
          title: appointment['title'] ?? '',
          description: appointment['description'] ?? '',
          date: DateTime.parse(appointment['date'] ?? DateTime.now().toIso8601String()),
          creatorId: appointment['creator_id'] ?? '',
          creatorName: '', // Not stored in database - will need to fetch from user profile
          creatorAvatar: '', // Not stored in database - will need to fetch from user profile
          status: AppointmentStatus.values.firstWhere(
            (e) => e.name == appointment['status'],
            orElse: () => AppointmentStatus.upcoming,
          ),
          state: EventState.values.firstWhere(
            (e) => e.name == appointment['state'],
            orElse: () => EventState.pending,
          ),
          attendees: [], // attendees field not used in current schema
          orgs: [], // Not stored in database
          location: appointment['location'],
          participantName: participantName, // Fetched from user profile if participant_id exists
          participantAvatar: participantAvatar, // Fetched from user profile if participant_id exists
          participantId: appointment['participant_id'],
        ));
      }
      return appointments;
    } catch (e) {
      print('Error getting appointment history from Supabase: $e');
      return [];
    }
  }

  Future<List<NewAppointmentDto>> getAppointments({String? userId}) async {
    try {
      List<Map<String, dynamic>> response;
      if (userId == null) {
        response = await SupabaseConfig.client
            .from(SupabaseConfig.appointmentsTable)
            .select();
      } else {
        final user = await UserRepository().getUserById(userId);
        if (user?.accountType == AccountType.reentry_orgs) {
          response = await SupabaseConfig.client
              .from(SupabaseConfig.appointmentsTable)
              .select()
              .contains('organizations', [userId]);
        } else {
          response = await SupabaseConfig.client
              .from(SupabaseConfig.appointmentsTable)
              .select()
              .or('creator_id.eq.$userId,participant_id.eq.$userId');
        }
      }
      
      List<NewAppointmentDto> appointments = [];
      for (var appointment in response) {
        // Fetch participant name if participant_id exists (mentor in system)
        String? participantName;
        String? participantAvatar;
        if (appointment['participant_id'] != null) {
          try {
            final participant = await UserRepository().getUserById(appointment['participant_id']);
            participantName = participant?.name;
            participantAvatar = participant?.avatar;
          } catch (e) {
            print('Error fetching participant info: $e');
          }
        }
        
        appointments.add(NewAppointmentDto(
          id: appointment['id'],
          title: appointment['title'] ?? '',
          description: appointment['description'] ?? '',
          date: DateTime.parse(appointment['date'] ?? DateTime.now().toIso8601String()),
          creatorId: appointment['creator_id'] ?? '',
          creatorName: '', // Not stored in database - will need to fetch from user profile
          creatorAvatar: '', // Not stored in database - will need to fetch from user profile
          status: AppointmentStatus.values.firstWhere(
            (e) => e.name == appointment['status'],
            orElse: () => AppointmentStatus.upcoming,
          ),
          state: EventState.values.firstWhere(
            (e) => e.name == appointment['state'],
            orElse: () => EventState.pending,
          ),
          attendees: [], // attendees field not used in current schema
          orgs: [], // Not stored in database
          location: appointment['location'],
          participantName: participantName, // Fetched from user profile if participant_id exists
          participantAvatar: participantAvatar, // Fetched from user profile if participant_id exists
          participantId: appointment['participant_id'],
        ));
      }
      return appointments;
    } catch (e) {
      print('Error getting appointments from Supabase: $e');
      return [];
    }
  }

  @override
  Future<List<AppointmentDto>> getAppointmentByUserId(String userId) async {
    final user = await PersistentStorage.getCurrentUser();
    
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.appointmentsTable)
          .select()
          .or('creator_id.eq.${user?.userId ?? ''},participant_id.eq.${user?.userId ?? ''}')
          .eq('status', AppointmentStatus.upcoming.name);
      
      return response.map<AppointmentDto>((appointment) {
        return AppointmentDto(
          id: appointment['id'],
          status: AppointmentStatus.values.firstWhere(
            (e) => e.name == appointment['status'],
            orElse: () => AppointmentStatus.upcoming,
          ),
          time: appointment['date'] ?? 0,
          attendees: [], // attendees field not used in current schema
        );
      }).toList();
    } catch (e) {
      print('Error getting appointments by user from Supabase: $e');
      return [];
    }
  }

  @override
  Future<NewAppointmentDto> updateAppointment(NewAppointmentDto payload) async {
    if (payload.id == null) throw Exception('Appointment ID is required for update');
    try {
      await SupabaseConfig.client
          .from(SupabaseConfig.appointmentsTable)
          .update(payload.toJson())
          .eq('id', payload.id!);
      // Fetch the updated row
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.appointmentsTable)
          .select()
          .eq('id', payload.id!)
          .single();
      if (response == null) throw Exception('Failed to fetch updated appointment');
      return NewAppointmentDto.fromJson(response, payload.creatorId);
    } catch (e) {
      throw Exception('Failed to update appointment: ${e.toString()}');
    }
  }
}
