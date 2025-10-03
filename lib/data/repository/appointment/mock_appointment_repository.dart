import 'appointment_repository_interface.dart';
import '../../model/appointment.dart';

// Mock Appointment Repository - Clean implementation with mock data
class MockAppointmentRepository implements AppointmentRepositoryInterface {
  static final List<Appointment> _appointments = [];

  @override
  Future<List<Appointment>> getUserAppointments(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _appointments.where((a) => 
      a.userId == userId || a.mentorId == userId || a.officerId == userId
    ).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<Appointment?> getAppointmentById(String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    try {
      return _appointments.firstWhere((a) => a.id == appointmentId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Appointment?> createAppointment(Appointment appointment) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    _appointments.add(appointment);
    return appointment;
  }

  @override
  Future<Appointment?> updateAppointment(Appointment appointment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _appointments.indexWhere((a) => a.id == appointment.id);
    if (index != -1) {
      _appointments[index] = appointment;
      return appointment;
    }
    return null;
  }

  @override
  Future<void> deleteAppointment(String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _appointments.removeWhere((a) => a.id == appointmentId);
  }

  @override
  Future<List<Appointment>> getUpcomingAppointments(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final now = DateTime.now();
    return _appointments.where((a) => 
      (a.userId == userId || a.mentorId == userId || a.officerId == userId) &&
      a.startTime.isAfter(now) &&
      a.status != AppointmentStatus.cancelled
    ).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<Appointment>> getAppointmentsByDate(String userId, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _appointments.where((a) => 
      (a.userId == userId || a.mentorId == userId || a.officerId == userId) &&
      a.startTime.year == date.year &&
      a.startTime.month == date.month &&
      a.startTime.day == date.day
    ).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<Appointment>> getAppointmentsByStatus(String userId, AppointmentStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _appointments.where((a) => 
      (a.userId == userId || a.mentorId == userId || a.officerId == userId) &&
      a.status == status
    ).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<DateTime>> getAvailableSlots(String userId, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Mock implementation - return some available slots
    final slots = <DateTime>[];
    final startHour = 9;
    final endHour = 17;
    
    for (int hour = startHour; hour < endHour; hour++) {
      final slot = DateTime(date.year, date.month, date.day, hour, 0);
      if (slot.isAfter(DateTime.now())) {
        slots.add(slot);
      }
    }
    
    return slots;
  }

  @override
  Future<bool> isTimeSlotAvailable(String userId, DateTime dateTime) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Check if there's already an appointment at this time
    final conflictingAppointment = _appointments.any((a) => 
      (a.userId == userId || a.mentorId == userId || a.officerId == userId) &&
      a.startTime.year == dateTime.year &&
      a.startTime.month == dateTime.month &&
      a.startTime.day == dateTime.day &&
      a.startTime.hour == dateTime.hour &&
      a.status != AppointmentStatus.cancelled
    );
    
    return !conflictingAppointment;
  }

  @override
  Future<void> sendAppointmentReminder(String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock implementation - just simulate success
  }

  @override
  Future<List<Appointment>> getAppointmentsNeedingReminders() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final now = DateTime.now();
    final reminderTime = now.add(const Duration(hours: 1));
    
    return _appointments.where((a) => 
      a.startTime.isAfter(now) &&
      a.startTime.isBefore(reminderTime) &&
      a.status == AppointmentStatus.scheduled
    ).toList();
  }

  // Helper methods for testing
  static void addMockAppointment(Appointment appointment) {
    _appointments.add(appointment);
  }

  static void clearMockData() {
    _appointments.clear();
  }
}
