import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'app_config.dart';

class SupabaseConfig {
  /// Allow tests to override the [SupabaseClient].
  static supabase.SupabaseClient? _overrideClient;

  /// Set a mock [SupabaseClient] for testing. Pass `null` to remove override.
  static set testClient(supabase.SupabaseClient? client) {
    _overrideClient = client;
  }

  // Supabase project configuration
  static String get supabaseUrl => AppConfig.supabaseUrl;
  static String get supabaseAnonKey => AppConfig.supabaseAnonKey;
  
  // Table names
  static const String userProfilesTable = 'user_profiles';
  static const String personsTable = 'persons';
  static const String organizationsTable = 'organizations';
  static const String conversationsTable = 'conversations';
  static const String messagesTable = 'messages';
  static const String conversationMembersTable = 'conversation_members';
  static const String appointmentsTable = 'appointments';
  static const String appointmentAttendeesTable = 'appointment_attendees';
  static const String blogPostsTable = 'blog_posts';
  static const String incidentsTable = 'incidents';
  static const String reportsTable = 'reports';
  
  // Initialize Supabase
  static Future<void> initialize() async {
    await supabase.Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Get Supabase client
  static supabase.SupabaseClient get client {
    return _overrideClient ?? supabase.Supabase.instance.client;
  }
  
  // Check if user is authenticated
  static bool get isAuthenticated {
    return client.auth.currentUser != null;
  }
  
  // Get current user
  static supabase.User? get currentUser {
    return client.auth.currentUser;
  }
  
  // Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  // Get user profile from database
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from(userProfilesTable)
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
  
  // Update user profile
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await client
          .from(userProfilesTable)
          .update(data)
          .eq('id', userId);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
  
  // Create user profile
  static Future<void> createUserProfile(Map<String, dynamic> data) async {
    try {
      await client
          .from(userProfilesTable)
          .insert(data);
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }
  
  // Delete user profile
  static Future<void> deleteUserProfile(String userId) async {
    try {
      await client
          .from(userProfilesTable)
          .delete()
          .eq('id', userId);
    } catch (e) {
      print('Error deleting user profile: $e');
      rethrow;
    }
  }
  
  // Listen to auth state changes
  static Stream<supabase.AuthState> get authStateChanges {
    return client.auth.onAuthStateChange;
  }
} 