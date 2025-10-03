import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/appointment_cubit.dart';
import 'bloc/appointment_state.dart';
import '../../../../data/model/appointment.dart';
import '../../../../data/repository/appointment/mock_appointment_repository.dart';

// Clean Appointments Screen
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedView = 'upcoming'; // upcoming, all, calendar

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppointmentCubit(
        appointmentRepository: MockAppointmentRepository(),
      )..loadUpcomingAppointments('current-user-id'), // Mock user ID
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Appointments',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          actions: [
            IconButton(
              onPressed: () => _showNewAppointmentDialog(context),
              icon: const Icon(Icons.add, color: Colors.black),
            ),
          ],
        ),
        body: BlocConsumer<AppointmentCubit, AppointmentState>(
          listener: (context, state) {
            if (state is AppointmentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is AppointmentCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment created successfully!'),
                  backgroundColor: Color(0xFF3AE6BD),
                ),
              );
            } else if (state is AppointmentUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment updated successfully!'),
                  backgroundColor: Color(0xFF3AE6BD),
                ),
              );
            } else if (state is AppointmentDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment deleted successfully!'),
                  backgroundColor: Color(0xFF3AE6BD),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AppointmentLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3AE6BD)),
                ),
              );
            }
            
            return Column(
              children: [
                // View Toggle
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildViewToggle('upcoming', 'Upcoming'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildViewToggle('all', 'All'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildViewToggle('calendar', 'Calendar'),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: _buildContent(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildViewToggle(String value, String label) {
    final isSelected = _selectedView == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = value;
        });
        _loadAppointments();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3AE6BD) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppointmentState state) {
    switch (_selectedView) {
      case 'upcoming':
        return _buildUpcomingView(state);
      case 'all':
        return _buildAllView(state);
      case 'calendar':
        return _buildCalendarView(state);
      default:
        return _buildUpcomingView(state);
    }
  }

  Widget _buildUpcomingView(AppointmentState state) {
    if (state is UpcomingAppointmentsLoaded) {
      if (state.upcomingAppointments.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_available,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No upcoming appointments',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: state.upcomingAppointments.length,
        itemBuilder: (context, index) {
          final appointment = state.upcomingAppointments[index];
          return _buildAppointmentCard(appointment);
        },
      );
    }
    
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3AE6BD)),
      ),
    );
  }

  Widget _buildAllView(AppointmentState state) {
    if (state is AppointmentsLoaded) {
      if (state.appointments.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_note,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No appointments found',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: state.appointments.length,
        itemBuilder: (context, index) {
          final appointment = state.appointments[index];
          return _buildAppointmentCard(appointment);
        },
      );
    }
    
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3AE6BD)),
      ),
    );
  }

  Widget _buildCalendarView(AppointmentState state) {
    return Column(
      children: [
        // Calendar Header
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        
        // Calendar Grid
        Expanded(
          child: _buildCalendarGrid(),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final day = index - firstWeekday + 1;
        final isCurrentMonth = day > 0 && day <= lastDayOfMonth.day;
        final isToday = isCurrentMonth && 
                       day == DateTime.now().day && 
                       _selectedDate.month == DateTime.now().month &&
                       _selectedDate.year == DateTime.now().year;
        
        return Container(
          margin: const EdgeInsets.all(1.0),
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFF3AE6BD) : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isCurrentMonth ? Colors.grey[300]! : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              isCurrentMonth ? day.toString() : '',
              style: TextStyle(
                color: isToday ? Colors.white : Colors.black,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3AE6BD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: Color(0xFF3AE6BD),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        appointment.type.displayName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    appointment.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(appointment.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(appointment.startTime),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3AE6BD),
                  ),
                ),
              ],
            ),
            
            if (appointment.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.location!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            if (appointment.description != null) ...[
              const SizedBox(height: 12),
              Text(
                appointment.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showAppointmentDetails(appointment),
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _editAppointment(appointment),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.inProgress:
        return Colors.orange;
      case AppointmentStatus.completed:
        return Colors.grey;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.rescheduled:
        return Colors.purple;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (appointmentDate == today) {
      dateStr = 'Today';
    } else if (appointmentDate == today.add(const Duration(days: 1))) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
    
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    return '$dateStr at $timeStr';
  }

  void _loadAppointments() {
    switch (_selectedView) {
      case 'upcoming':
        context.read<AppointmentCubit>().loadUpcomingAppointments('current-user-id');
        break;
      case 'all':
        context.read<AppointmentCubit>().loadUserAppointments('current-user-id');
        break;
      case 'calendar':
        context.read<AppointmentCubit>().loadAppointmentsByDate('current-user-id', _selectedDate);
        break;
    }
  }

  void _showNewAppointmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Schedule New Appointment',
            style: TextStyle(
              color: Color(0xFF3AE6BD),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This feature will allow you to schedule appointments with mentors, officers, and other professionals.',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF3AE6BD),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            appointment.title,
            style: const TextStyle(
              color: Color(0xFF3AE6BD),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${_formatDateTime(appointment.startTime)}'),
              Text('Duration: ${appointment.duration.inMinutes} minutes'),
              Text('Type: ${appointment.type.displayName}'),
              Text('Status: ${appointment.status.displayName}'),
              if (appointment.location != null)
                Text('Location: ${appointment.location}'),
              if (appointment.description != null) ...[
                const SizedBox(height: 8),
                Text('Description: ${appointment.description}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF3AE6BD),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editAppointment(Appointment appointment) {
    // TODO: Implement edit appointment functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit appointment feature coming soon!'),
        backgroundColor: Color(0xFF3AE6BD),
      ),
    );
  }
}
