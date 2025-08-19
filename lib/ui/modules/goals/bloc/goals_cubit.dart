import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/data/model/goal_dto.dart';
import 'package:reentry/data/repository/goals/goals_repository.dart';
import 'package:reentry/ui/modules/goals/bloc/goals_state.dart';

final _repo = GoalRepository();

class GoalCubit extends Cubit<GoalCubitState> {
  GoalCubit() : super(GoalCubitState.init());

  Future<void> fetchGoals({String? personId}) async {
    try {
      emit(state.loading());
      final goals = await _repo.fetchActiveGoals(personId: personId);
      final history = await _repo.fetchGoalHistory(personId: personId);
      emit(state.success(goals: goals, history: history));
    } catch (e) {
      emit(state.error(e.toString()));
    }
  }

  Future<void> fetchHistory({String? personId}) async {
    try {
      emit(state.loading());
      final history = await _repo.fetchGoalHistory(personId: personId);
      emit(state.success(history: history));
    } catch (e) {
      emit(state.error(e.toString()));
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      emit(state.loading());
      await _repo.deleteGoals(goalId);
      final goals = await _repo.fetchActiveGoals();
      final history = await _repo.fetchGoalHistory();
      emit(state.success(goals: goals, history: history));
    } catch (e) {
      emit(state.error(e.toString()));
    }
  }

  Future<void> updateGoal(GoalDto goal) async {
    try {
      emit(state.loading());
      await _repo.updateGoal(goal);
      final goals = await _repo.fetchActiveGoals(personId: goal.personId);
      final history = await _repo.fetchGoalHistory(personId: goal.personId);
      emit(state.success(goals: goals, history: history));
    } catch (e) {
      emit(state.error(e.toString()));
    }
  }

  Future<void> createGoal(GoalDto goal) async {
    try {
      emit(state.loading());
      await _repo.createGoal(goal);
      final goals = await _repo.fetchActiveGoals(personId: goal.personId);
      final history = await _repo.fetchGoalHistory(personId: goal.personId);
      emit(state.success(goals: goals, history: history));
    } catch (e) {
      emit(state.error(e.toString()));
    }
  }
}