import 'package:flutter_bloc/flutter_bloc.dart';
import 'appointment_state.dart';
import '../../../../data/model/appointment.dart';
import '../../../../data/repository/appointment/appointment_repository_interface.dart';

// Clean Appointment Cubit
class AppointmentCubit extends Cubit<AppointmentState> {
  final AppointmentRepositoryInterface _appointmentRepository;
  
  AppointmentCubit({
    required AppointmentRepositoryInterface appointmentRepository,
  }) : _appointmentRepository = appointmentRepository,
       super(AppointmentInitial());

  Future<void> loadUserAppointments(String userId) async {
    emit(AppointmentLoading());
    
    try {
      final appointments = await _appointmentRepository.getUserAppointments(userId);
      emit(AppointmentsLoaded(appointments));
    } catch (e) {
      emit(AppointmentError('Failed to load appointments: ${e.toString()}'));
    }
  }

  Future<void> loadUpcomingAppointments(String userId) async {
    emit(AppointmentLoading());
    
    try {
      final appointments = await _appointmentRepository.getUpcomingAppointments(userId);
      emit(UpcomingAppointmentsLoaded(appointments));
    } catch (e) {
      emit(AppointmentError('Failed to load upcoming appointments: ${e.toString()}'));
    }
  }

  Future<void> loadAppointmentsByDate(String userId, DateTime date) async {
    emit(AppointmentLoading());
    
    try {
      final appointments = await _appointmentRepository.getAppointmentsByDate(userId, date);
      emit(AppointmentsLoaded(appointments));
    } catch (e) {
      emit(AppointmentError('Failed to load appointments by date: ${e.toString()}'));
    }
  }

  Future<void> createAppointment(Appointment appointment) async {
    try {
      final createdAppointment = await _appointmentRepository.createAppointment(appointment);
      if (createdAppointment != null) {
        emit(AppointmentCreated(createdAppointment));
      }
    } catch (e) {
      emit(AppointmentError('Failed to create appointment: ${e.toString()}'));
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      final updatedAppointment = await _appointmentRepository.updateAppointment(appointment);
      if (updatedAppointment != null) {
        emit(AppointmentUpdated(updatedAppointment));
      }
    } catch (e) {
      emit(AppointmentError('Failed to update appointment: ${e.toString()}'));
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _appointmentRepository.deleteAppointment(appointmentId);
      emit(AppointmentDeleted(appointmentId));
    } catch (e) {
      emit(AppointmentError('Failed to delete appointment: ${e.toString()}'));
    }
  }

  Future<void> getAvailableSlots(String userId, DateTime date) async {
    try {
      final slots = await _appointmentRepository.getAvailableSlots(userId, date);
      emit(AvailableSlotsLoaded(slots, date));
    } catch (e) {
      emit(AppointmentError('Failed to get available slots: ${e.toString()}'));
    }
  }

  Future<void> checkTimeSlotAvailability(String userId, DateTime dateTime) async {
    try {
      await _appointmentRepository.isTimeSlotAvailable(userId, dateTime);
      // You could emit a specific state for this if needed
    } catch (e) {
      emit(AppointmentError('Failed to check time slot availability: ${e.toString()}'));
    }
  }

  Future<void> sendAppointmentReminder(String appointmentId) async {
    try {
      await _appointmentRepository.sendAppointmentReminder(appointmentId);
    } catch (e) {
      emit(AppointmentError('Failed to send appointment reminder: ${e.toString()}'));
    }
  }
}
