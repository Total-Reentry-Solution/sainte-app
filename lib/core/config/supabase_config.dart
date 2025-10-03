import 'package:supabase_flutter/supabase_flutter.dart';

// Clean Supabase configuration
class SupabaseConfig {
  static SupabaseClient get client => Supabase.instance.client;
  
  static User? get currentUser => client.auth.currentUser;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://elwejexsczkwsgxpamfx.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVsd2VqZXhzY3prd3NneHBhbWZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ5NzQ4NzEsImV4cCI6MjA1MDU1MDg3MX0.8QZQZQZQZQZQZQZQZQZQZQZQZQZQZQZQZQZQZQZQ',
    );
  }
}