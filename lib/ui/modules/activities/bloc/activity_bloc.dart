import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/data/repository/activities/activity_repository.dart';
import 'package:reentry/ui/modules/activities/bloc/activity_state.dart';
import 'activity_event.dart';
import 'package:reentry/data/model/activity_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  ActivityBloc() : super(ActivityInitial()) {
    on<CreateActivityEvent>(_createActivity);
    on<UpdateActivityEvent>(_updateActivity);
    on<DeleteActivityEvent>(_deleteActivity);
  }

  final _repo = ActivityRepository();

  Future<void> _deleteActivity(
      DeleteActivityEvent event, Emitter<ActivityState> emit) async {
    emit(ActivityLoading());
    try {
      await _repo.deleteActivity(event.id);
      emit(DeleteActivitySuccess());
    } catch (e) {
      emit(CreateActivityError(e.toString()));
    }
  }

  Future<void> _createActivity(
      CreateActivityEvent event, Emitter<ActivityState> emit) async {
    emit(ActivityLoading());
    try {
      print('Creating activity with user_id: ${event.userId}');
      if (event.userId.isEmpty) {
        emit(CreateActivityError('User ID is missing. Please log in again.'));
        return;
      }
      final result = await _repo.createActivity(event.toActivityDto());
      emit(CreateActivitySuccess(result));
    } catch (e, stack) {
      if (e is PostgrestException) {
        final errorMsg = '''
Could not create activity. Reason: ${e.message ?? 'Unknown error'}

---
Error Code: ${e.code}
Details: ${e.details}
Hint: ${e.hint}
User ID: ${event.userId}
Activity Payload: ${event.toActivityDto().toJson()}
---
If this is a UUID or constraint error, please check that all required fields are valid and not empty.
''';
        print(errorMsg);
        emit(CreateActivityError(errorMsg));
      } else if (e.toString().contains('PostgrestException')) {
        final errorMsg = '''
Could not create activity. Reason: ${e.toString()}

User ID: ${event.userId}
Activity Payload: ${event.toActivityDto().toJson()}
---
If this is a UUID or constraint error, please check that all required fields are valid and not empty.
''';
        print(errorMsg);
        emit(CreateActivityError(errorMsg));
      } else {
        print('Unexpected error: ${e.toString()}\n\nStack trace:\n$stack');
        emit(CreateActivityError('Unexpected error: ${e.toString()}\n\nStack trace:\n$stack'));
      }
    }
  }

  Future<void> _updateActivity(
      UpdateActivityEvent event, Emitter<ActivityState> emit) async {
    emit(ActivityLoading());
    try {
      await _repo.updateActivity(event.data);
      emit(ActivityUpdateSuccess());
    } catch (e) {
      emit(CreateActivityError(e.toString()));
    }
  }
}
