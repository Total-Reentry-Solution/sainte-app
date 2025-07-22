import 'package:reentry/data/model/activity_dto.dart';
import 'package:reentry/exception/app_exceptions.dart';
import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/model/progress_stats.dart';

class ActivityRepository {
  Future<List<ActivityDto>> fetchAllUsersActivity({required String personId}) async {
    final response = await SupabaseConfig.client
        .from('person_activities')
        .select()
        .eq('person_id', personId)
        .order('startDate');
    return (response as List).map((e) => ActivityDto.fromJson(e)).toList();
  }

  Future<List<ActivityDto>> fetchActivityHistory({required String personId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final response = await SupabaseConfig.client
        .from('person_activities')
        .select()
        .eq('person_id', personId)
        .lt('endDate', now)
        .order('startDate', ascending: false);
    return (response as List).map((e) => ActivityDto.fromJson(e)).toList();
  }

  Future<ActivityDto> createActivity(ActivityDto activity) async {
    final response = await SupabaseConfig.client
        .from('person_activities')
        .insert(activity.toJson())
        .select()
        .single();
    return ActivityDto.fromJson(response);
  }

  Future<void> deleteActivity(String id) async {
    await SupabaseConfig.client
        .from('person_activities')
        .delete()
        .eq('id', id);
  }

  Future<void> updateActivity(ActivityDto activity) async {
    await SupabaseConfig.client
        .from('person_activities')
        .update(activity.toJson())
        .eq('id', activity.id);
  }

  Future<ProgressStats> fetchActivityStats({required String personId}) async {
    final all = await SupabaseConfig.client
        .from('person_activities')
        .select('progress')
        .eq('person_id', personId);
    final total = (all as List).length;
    final completed = (all as List).where((e) => (e['progress'] ?? 0) == 100).length;
    return ProgressStats(completed: completed, total: total);
  }
}
