import 'package:reentry/data/model/activity_dto.dart';
import 'package:reentry/exception/app_exceptions.dart';
import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/model/progress_stats.dart';

class ActivityRepository {
  Future<List<ActivityDto>> fetchAllUsersActivity({String? userId}) async {
    final id = userId ?? SupabaseConfig.currentUser?.id;
    if (id == null) throw BaseExceptions('User not found');
    final response = await SupabaseConfig.client
        .from('person_activities')
        .select()
        .eq('user_id', id)
        .order('startDate');
    return (response as List).map((e) => ActivityDto.fromJson(e)).toList();
  }

  Future<List<ActivityDto>> fetchActivityHistory({String? userId}) async {
    final id = userId ?? SupabaseConfig.currentUser?.id;
    if (id == null) throw BaseExceptions('User not found');
    final now = DateTime.now().millisecondsSinceEpoch;
    final response = await SupabaseConfig.client
        .from('person_activities')
        .select()
        .eq('user_id', id)
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

  Future<ProgressStats> fetchActivityStats({String? userId}) async {
    final id = userId ?? SupabaseConfig.currentUser?.id;
    if (id == null) throw BaseExceptions('User not found');
    final all = await SupabaseConfig.client
        .from('person_activities')
        .select('progress')
        .eq('user_id', id);
    final total = (all as List).length;
    final completed = (all as List).where((e) => (e['progress'] ?? 0) == 100).length;
    return ProgressStats(completed: completed, total: total);
  }
}
