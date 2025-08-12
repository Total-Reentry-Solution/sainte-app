import '../../../ui/modules/appointment/bloc/appointment_event.dart';
import '../../model/appointment_dto.dart';
import '../../model/user_dto.dart';

abstract class AppointmentRepositoryInterface{
  Future<NewAppointmentDto> createAppointment(NewAppointmentDto payload);
  Future<List<AppointmentEntityDto>> getUserAppointments();
  Future<List<NewAppointmentDto>> getAppointments({String? userId, bool dashboard = false});
  Future<List<NewAppointmentDto>> getUpcomingAppointments({String? userId});
  Future<NewAppointmentDto> updateAppointment(NewAppointmentDto payload);
  Future<void> deleteAppointment(AppointmentDto payload);
  Future<List<AppointmentDto>> getAppointmentByUserId(String userId);
}