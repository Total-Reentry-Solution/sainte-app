import '../../model/appointment.dart';

// Clean Appointment Repository Interface
abstract class AppointmentRepositoryInterface {
  // Appointments CRUD
  Future<List<Appointment>> getUserAppointments(String userId);
  Future<Appointment?> getAppointmentById(String appointmentId);
  Future<Appointment?> createAppointment(Appointment appointment);
  Future<Appointment?> updateAppointment(Appointment appointment);
  Future<void> deleteAppointment(String appointmentId);
  
  // Appointment Management
  Future<List<Appointment>> getUpcomingAppointments(String userId);
  Future<List<Appointment>> getAppointmentsByDate(String userId, DateTime date);
  Future<List<Appointment>> getAppointmentsByStatus(String userId, AppointmentStatus status);
  
  // Availability
  Future<List<DateTime>> getAvailableSlots(String userId, DateTime date);
  Future<bool> isTimeSlotAvailable(String userId, DateTime dateTime);
  
  // Notifications
  Future<void> sendAppointmentReminder(String appointmentId);
  Future<List<Appointment>> getAppointmentsNeedingReminders();
}
