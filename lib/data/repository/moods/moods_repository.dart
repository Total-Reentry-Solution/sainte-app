import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../model/mood.dart';

class MoodsRepository {
  Future<List<Mood>> getAllMoods() async {
    final response = await SupabaseConfig.client.from('moods').select();
    return (response as List).map((e) => Mood.fromJson(e)).toList();
  }

  Future<Mood?> getMoodById(String id) async {
    final response = await SupabaseConfig.client.from('moods').select().eq('mood_id', id).single();
    if (response == null) return null;
    return Mood.fromJson(response);
  }

  Future<Mood?> getMoodByName(String name) async {
    final response = await SupabaseConfig.client.from('moods').select().eq('mood_name', name).single();
    if (response == null) return null;
    return Mood.fromJson(response);
  }
} 