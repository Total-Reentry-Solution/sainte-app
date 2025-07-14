import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../model/mood.dart';
import '../moods/moods_repository.dart';

class MoodLogsRepository {
  final MoodsRepository moodsRepository;
  MoodLogsRepository({required this.moodsRepository});

  Future<void> insertMoodLog({
    required String userId,
    required String moodId,
    String? notes,
    int? intensity,
  }) async {
    await SupabaseConfig.client.from('mood_logs').insert({
      'user_id': userId,
      'mood_id': moodId,
      'notes': notes,
      'mood_intensity': intensity,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<MoodLog>> getMoodLogsForUser(String userId) async {
    final moods = await moodsRepository.getAllMoods();
    final response = await SupabaseConfig.client
        .from('mood_logs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) {
      final mood = moods.firstWhere((m) => m.id == e['mood_id'], orElse: () => Mood(id: '', name: 'Unknown'));
      return MoodLog.fromJson(e, mood);
    }).toList();
  }
} 