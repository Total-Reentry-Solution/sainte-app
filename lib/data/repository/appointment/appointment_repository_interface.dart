import '../../../ui/modules/appointment/bloc/appointment_event.dart';
import '../../model/appointment_dto.dart';

abstract class AppointmentRepositoryInterface{
  Future<NewAppointmentDto> createAppointment(NewAppointmentDto payload);
  Future<List<AppointmentEntityDto>> getUserAppointments();
  Future<NewAppointmentDto> updateAppointment(NewAppointmentDto payload);
  Future<void> deleteAppointment(AppointmentDto payload);
  Future<List<AppointmentDto>> getAppointmentByUserId(String userId);
}