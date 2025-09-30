import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum BackendType {
  supabase,
}

class AppConfig {
  // Environment variables (will be loaded from .env file)
  static String get _supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get _supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get _supabaseServiceRoleKey => dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
  
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