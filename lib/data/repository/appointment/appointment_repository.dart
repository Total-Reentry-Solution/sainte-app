// APPOINTMENT REPOSITORY TEMPORARILY DISABLED FOR AUTH TESTING
// All code in this file is commented out to allow registration/login to work.
/*
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/model/appointment_dto.dart';
import 'package:reentry/data/repository/appointment/appointment_repository_interface.dart';
import 'package:reentry/data/repository/user/user_repository.dart';
import 'package:reentry/data/shared/share_preference.dart';
import '../../../ui/modules/appointment/bloc/appointment_event.dart';
import '../../../core/config/supabase_config.dart';
import 'package:reentry/core/exceptions/base_exceptions.dart';

class AppointmentRepository extends AppointmentRepositoryInterface {

  Future<void> cancelAppointment(NewAppointmentDto payload) async {
    try {
      if (payload.id != null) {
        await SupabaseConfig.client
            .from(SupabaseConfig.appointmentsTable)
            .update({
              'status': AppointmentStatus.canceled.name,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', payload.id);
      }
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
  Future<NewAppointmentDto> createAppointment(
      CreateAppointmentEvent payload) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.appointmentsTable)
          .insert({
            'id': payload.data.id,
            'title': payload.data.title,
            'description': payload.data.description,
            'date': payload.data.date.millisecondsSinceEpoch,
            'creator_id': payload.data.creatorId,
            'creator_name': payload.data.creatorName,
            'creator_avatar': payload.data.creatorAvatar,
            'status': payload.data.status.name,
            'state': payload.data.state.name,
            'attendees': payload.data.attendees,
            'organizations': payload.data.orgs,
            'location': payload.data.location,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return payload.data;
    } catch (e) {
      throw Exception('Failed to create appointment: ${e.toString()}');
    }
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
          .eq('id', payload.id);
    } catch (e) {
      throw BaseExceptions('Failed to delete appointment: ${e.toString()}');
    }
  }

  @override
  Future<List<AppointmentEntityDto>> getUserAppointments() async {
    final user = await PersistentStorage.getCurrentUser();
    
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.appointmentsTable)
          .select()
          .contains('attendees', [user?.userId ?? '']);
      
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
    // For Supabase, you'll need to implement real-time subscriptions
    return Stream.value([]);
  }

  Future<List<NewAppointmentDto>> getUserAppointmentHistoryFuture(
      String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.appointmentsTable)
          .select()
          .contains('attendees', [userId])
          .order('date', ascending: false);
      
      return response.map<NewAppointmentDto>((appointment) {
        return NewAppointmentDto(
          id: appointment['id'],
          title: appointment['title'] ?? '',
          description: appointment['description'] ?? '',
          date: DateTime.fromMillisecondsSinceEpoch(appointment['date'] ?? 0),
          creatorId: appointment['creator_id'] ?? '',
          creatorName: appointment['creator_name'] ?? '',
          creatorAvatar: appointment['creator_avatar'] ?? '',
          status: AppointmentStatus.values.firstWhere(
            (e) => e.name == appointment['status'],
            orElse: () => AppointmentStatus.upcoming,
          ),
          state: EventState.values.firstWhere(
            (e) => e.name == appointment['state'],
            orElse: () => EventState.pending,
          ),
          attendees: List<String>.from(appointment['attendees'] ?? []),
          orgs: List<String>.from(appointment['organizations'] ?? []),
          location: appointment['location'],
        );
      }).toList();
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
              .contains('attendees', [userId]);
        }
      }
      
      return response.map<NewAppointmentDto>((appointment) {
        return NewAppointmentDto(
          id: appointment['id'],
          title: appointment['title'] ?? '',
          description: appointment['description'] ?? '',
          date: DateTime.fromMillisecondsSinceEpoch(appointment['date'] ?? 0),
          creatorId: appointment['creator_id'] ?? '',
          creatorName: appointment['creator_name'] ?? '',
          creatorAvatar: appointment['creator_avatar'] ?? '',
          status: AppointmentStatus.values.firstWhere(
            (e) => e.name == appointment['status'],
            orElse: () => AppointmentStatus.upcoming,
          ),
          state: EventState.values.firstWhere(
            (e) => e.name == appointment['state'],
            orElse: () => EventState.pending,
          ),
          attendees: List<String>.from(appointment['attendees'] ?? []),
          orgs: List<String>.from(appointment['organizations'] ?? []),
          location: appointment['location'],
        );
      }).toList();
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
          .contains('attendees', [user?.userId ?? ''])
          .eq('status', AppointmentStatus.upcoming.name);
      
      return response.map<AppointmentDto>((appointment) {
        return AppointmentDto(
          id: appointment['id'],
          status: AppointmentStatus.values.firstWhere(
            (e) => e.name == appointment['status'],
            orElse: () => AppointmentStatus.upcoming,
          ),
          time: appointment['date'] ?? 0,
          attendees: List<String>.from(appointment['attendees'] ?? []),
        );
      }).toList();
    } catch (e) {
      print('Error getting appointments by user from Supabase: $e');
      return [];
    }
  }

  @override
  Future<NewAppointmentDto> updateAppointment(NewAppointmentDto payload) async {
    try {
      if (payload.id == null) {
        throw BaseExceptions('Appointment ID is required for update');
      }
      
      await SupabaseConfig.client
          .from(SupabaseConfig.appointmentsTable)
          .update({
            'title': payload.title,
            'description': payload.description,
            'date': payload.date.millisecondsSinceEpoch,
            'status': payload.status.name,
            'state': payload.state.name,
            'attendees': payload.attendees,
            'organizations': payload.orgs,
            'location': payload.location,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', payload.id);
    } catch (e) {
      throw BaseExceptions('Failed to update appointment: ${e.toString()}');
    }
  }
}
*/
