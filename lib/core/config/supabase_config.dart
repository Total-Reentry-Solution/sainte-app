import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace these with your actual Supabase project credentials
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  
  // Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;
  
  // Auth instance
  static GoTrueClient get auth => client.auth;
  
  // Database instance
  static SupabaseQueryBuilder get db => client.from;
  
  // Storage instance
  static StorageClient get storage => client.storage;
  
  // RPC instance for custom functions
  static FunctionsClient get functions => client.functions;
  
  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
  
  // Helper method to get current user
  static User? get currentUser => auth.currentUser;
  
  // Helper method to check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
  
  // Helper method to get user ID
  static String? get currentUserId => currentUser?.id;
} 