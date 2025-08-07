import 'package:reentry/data/model/goal_dto.dart';
import 'package:reentry/exception/app_exceptions.dart';
import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/model/progress_stats.dart';

class GoalRepository {
  Future<List<GoalDto>> fetchActiveGoals({String? personId}) async {
    final id = personId ?? SupabaseConfig.currentUser?.id;
    if (id == null) throw BaseExceptions('User not found');
    final response = await SupabaseConfig.client
        .from('person_goals')
        .select()
        .eq('person_id', id)
        .neq('progress_percentage', 100) // Exclude 100% completed goals
        .order('created_at', ascending: false);
    return (response as List).map((e) => GoalDto.fromJson(e)).toList();
  }

  Future<List<GoalDto>> fetchAllUserGoals(String personId) async {
    final response = await SupabaseConfig.client
        .from('person_goals')
        .select()
        .eq('person_id', personId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => GoalDto.fromJson(e)).toList();
  }

  Future<List<GoalDto>> fetchGoalHistory({String? personId}) async {
    final id = personId ?? SupabaseConfig.currentUser?.id;
    if (id == null) throw BaseExceptions('User not found');
    final response = await SupabaseConfig.client
        .from('person_goals')
        .select()
        .eq('person_id', id)
        .eq('progress_percentage', 100)
        .order('created_at', ascending: false);
    return (response as List).map((e) => GoalDto.fromJson(e)).toList();
  }

  Future<GoalDto> createGoal(GoalDto goal) async {
    final response = await SupabaseConfig.client
        .from('person_goals')
        .insert(goal.toJson())
        .select()
        .single();
    return GoalDto.fromJson(response);
  }

  Future<void> deleteGoals(String goalId) async {
    await SupabaseConfig.client
        .from('person_goals')
        .delete()
        .eq('goal_id', goalId ?? '');
  }

  Future<void> updateGoal(GoalDto goal) async {
    await SupabaseConfig.client
        .from('person_goals')
        .update(goal.toJson())
        .eq('goal_id', goal.goalId ?? '');
  }

  Future<ProgressStats> fetchGoalStats({String? personId}) async {
    final id = personId ?? SupabaseConfig.currentUser?.id;
    if (id == null) throw BaseExceptions('User not found');
    final all = await SupabaseConfig.client
        .from('person_goals')
        .select('progress_percentage')
        .eq('person_id', id);
    final total = (all as List).length;
    final completed = (all as List).where((e) => (e['progress_percentage'] ?? 0) == 100).length;
    return ProgressStats(completed: completed, total: total);
  }
}
