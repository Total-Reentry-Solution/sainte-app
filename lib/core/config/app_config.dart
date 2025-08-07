import 'package:flutter/foundation.dart';

enum BackendType {
  supabase,
}

class AppConfig {
  // Environment variables (will be loaded from .env file)
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String _supabaseServiceRoleKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: '');
  
  // Backend selection - now only Supabase
  static BackendType get backendType => BackendType.supabase;
  
  // Supabase configuration
  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;
  static String get supabaseServiceRoleKey => _supabaseServiceRoleKey;
  
  // Debug mode
  static bool get isDebugMode => kDebugMode;
  
  // Check if Supabase is configured
  static bool get isSupabaseConfigured => 
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;
  
  // Get current backend name for logging
  static String get currentBackendName => backendType.name.toUpperCase();
} 