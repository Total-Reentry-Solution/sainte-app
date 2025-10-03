import '../../../../data/model/appointment.dart';

// Clean Appointment State
abstract class AppointmentState {}

class AppointmentInitial extends AppointmentState {}

class AppointmentLoading extends AppointmentState {}

class AppointmentsLoaded extends AppointmentState {
  final List<Appointment> appointments;
  
  AppointmentsLoaded(this.appointments);
}

class AppointmentCreated extends AppointmentState {
  final Appointment appointment;
  
  AppointmentCreated(this.appointment);
}

class AppointmentUpdated extends AppointmentState {
  final Appointment appointment;
  
  AppointmentUpdated(this.appointment);
}

class AppointmentDeleted extends AppointmentState {
  final String appointmentId;
  
  AppointmentDeleted(this.appointmentId);
}

class AppointmentError extends AppointmentState {
  final String message;
  
  AppointmentError(this.message);
}

class AvailableSlotsLoaded extends AppointmentState {
  final List<DateTime> availableSlots;
  final DateTime date;
  
  AvailableSlotsLoaded(this.availableSlots, this.date);
}

class UpcomingAppointmentsLoaded extends AppointmentState {
  final List<Appointment> upcomingAppointments;
  
  UpcomingAppointmentsLoaded(this.upcomingAppointments);
}
