import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
    
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase URL or Anon Key is missing. Please check your .env file.');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
} 