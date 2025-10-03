import '../model/user.dart';
import '../model/messaging/conversation.dart';
import '../model/messaging/message.dart';
import '../model/appointment.dart';
import '../enum/account_type.dart';
import '../repository/auth/mock_auth_repository.dart';
import '../repository/user/mock_user_repository.dart';
import '../repository/messaging/mock_messaging_repository.dart';
import '../repository/appointment/mock_appointment_repository.dart';

// Mock Data Initializer - Sets up sample data for testing
class MockDataInitializer {
  static void initializeMockData() {
    _initializeUsers();
    _initializeConversations();
    _initializeMessages();
    _initializeAppointments();
  }

  static void _initializeUsers() {
    // Clear existing data
    MockUserRepository.clearMockData();
    MockAuthRepository.clearMockData();

    // Create sample users
    final users = [
      AppUser(
        id: 'current-user-id',
        email: 'user@sainte.com',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1 (555) 123-4567',
        address: '123 Main St, City, State 12345',
        accountType: AccountType.citizen,
        jobTitle: 'Software Developer',
        organization: 'Tech Corp',
        about: 'Passionate about technology and helping others succeed.',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      AppUser(
        id: 'mentor-1',
        email: 'mentor1@sainte.com',
        firstName: 'Sarah',
        lastName: 'Johnson',
        phoneNumber: '+1 (555) 234-5678',
        accountType: AccountType.mentor,
        jobTitle: 'Senior Software Engineer',
        organization: 'Tech Solutions Inc',
        about: 'Experienced mentor with 10+ years in software development.',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now(),
      ),
      AppUser(
        id: 'officer-1',
        email: 'officer1@sainte.com',
        firstName: 'Mike',
        lastName: 'Wilson',
        phoneNumber: '+1 (555) 345-6789',
        accountType: AccountType.officer,
        jobTitle: 'Case Manager',
        organization: 'Reentry Services',
        about: 'Dedicated to helping individuals successfully reintegrate into society.',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now(),
      ),
    ];

    // Add users to repositories
    for (final user in users) {
      MockUserRepository.addMockUser(user);
      MockAuthRepository.addMockUser(user);
    }
  }

  static void _initializeConversations() {
    MockMessagingRepository.clearMockData();

    final conversations = [
      Conversation(
        id: 'conv-1',
        userId1: 'current-user-id',
        userId2: 'mentor-1',
        lastMessageContent: 'Thank you for the great advice!',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        readStatus: {
          'current-user-id': true,
          'mentor-1': false,
        },
      ),
      Conversation(
        id: 'conv-2',
        userId1: 'current-user-id',
        userId2: 'officer-1',
        lastMessageContent: 'Your appointment is scheduled for tomorrow at 2 PM.',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        readStatus: {
          'current-user-id': false,
          'officer-1': true,
        },
      ),
    ];

    for (final conversation in conversations) {
      MockMessagingRepository.addMockConversation(conversation);
    }
  }

  static void _initializeMessages() {
    final messages = [
      Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'mentor-1',
        content: 'Hi John! I\'m excited to work with you. What are your main goals?',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        isRead: true,
      ),
      Message(
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'current-user-id',
        content: 'Hi Sarah! I want to improve my coding skills and find a better job.',
        createdAt: DateTime.now().subtract(const Duration(days: 5, hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5, hours: 1)),
        isRead: true,
      ),
      Message(
        id: 'msg-3',
        conversationId: 'conv-1',
        senderId: 'mentor-1',
        content: 'That\'s great! I can help you with that. Let\'s start with some coding exercises.',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        isRead: true,
      ),
      Message(
        id: 'msg-4',
        conversationId: 'conv-1',
        senderId: 'current-user-id',
        content: 'Thank you for the great advice!',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      Message(
        id: 'msg-5',
        conversationId: 'conv-2',
        senderId: 'officer-1',
        content: 'Hello John, I wanted to check in on your progress.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
      Message(
        id: 'msg-6',
        conversationId: 'conv-2',
        senderId: 'current-user-id',
        content: 'Hi Mike, things are going well. I have a job interview next week.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      Message(
        id: 'msg-7',
        conversationId: 'conv-2',
        senderId: 'officer-1',
        content: 'Your appointment is scheduled for tomorrow at 2 PM.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
      ),
    ];

    for (final message in messages) {
      MockMessagingRepository.addMockMessage(message);
    }
  }

  static void _initializeAppointments() {
    MockAppointmentRepository.clearMockData();

    final appointments = [
      Appointment(
        id: 'apt-1',
        title: 'Mentor Meeting',
        description: 'Weekly check-in with mentor to discuss progress and goals',
        userId: 'current-user-id',
        mentorId: 'mentor-1',
        startTime: DateTime.now().add(const Duration(days: 1, hours: 14)),
        endTime: DateTime.now().add(const Duration(days: 1, hours: 15)),
        status: AppointmentStatus.scheduled,
        type: AppointmentType.meeting,
        location: 'Community Center - Room 101',
        notes: 'Bring your coding project for review',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Appointment(
        id: 'apt-2',
        title: 'Case Review',
        description: 'Monthly case review with case manager',
        userId: 'current-user-id',
        officerId: 'officer-1',
        startTime: DateTime.now().add(const Duration(days: 7, hours: 10)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 11)),
        status: AppointmentStatus.scheduled,
        type: AppointmentType.meeting,
        location: 'Reentry Services Office',
        notes: 'Review progress and set new goals',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        updatedAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      Appointment(
        id: 'apt-3',
        title: 'Job Interview Prep',
        description: 'Practice interview questions with mentor',
        userId: 'current-user-id',
        mentorId: 'mentor-1',
        startTime: DateTime.now().add(const Duration(days: 3, hours: 16)),
        endTime: DateTime.now().add(const Duration(days: 3, hours: 17)),
        status: AppointmentStatus.scheduled,
        type: AppointmentType.video,
        meetingLink: 'https://meet.google.com/abc-defg-hij',
        notes: 'Focus on technical questions',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    for (final appointment in appointments) {
      MockAppointmentRepository.addMockAppointment(appointment);
    }
  }
}
