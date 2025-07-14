import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/data/repository/activities/activity_repository.dart';
import 'activity_state.dart';

final _repo = ActivityRepository();

class ActivityCubit extends Cubit<ActivityCubitState> {
  ActivityCubit() : super(ActivityCubitState.init());

  Future<void> fetchActivities({String? userId}) async {
    try {
      emit(state.loading());
      final activities = await _repo.fetchAllUsersActivity(userId: userId);
      final now = DateTime.now().millisecondsSinceEpoch;
      final active = activities.where((e) => e.progress < 100 && e.endDate > now).toList();
      final history = activities.where((e) => e.progress >= 100 || e.endDate <= now).toList();
      emit(state.success(activity: active, history: history));
    } catch (e) {
      emit(state.error(e.toString()));
    }
  }

  Future<void> fetchHistory({String? userId}) async {
    try {
      emit(state.loading());
      final history = await _repo.fetchActivityHistory(userId: userId);
      emit(state.success(history: history));
    } catch (e) {
      emit(state.error(e.toString()));
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      emit(state.loading());
      await _repo.deleteActivity(id);
      final updatedActivities = state.activity.where((item) => item.id != id).toList();
      emit(state.success(activity: updatedActivities));
    } catch (e) {
      emit(state.error(e.toString()));
    }
  }
}
