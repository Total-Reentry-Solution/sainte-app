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
      print('Creating activity with person_id: \'${event.personId}\'');
      if (event.personId.isEmpty) {
        emit(CreateActivityError('Person ID is missing. Please log in again.'));
        return;
      }
      final result = await _repo.createActivity(event.toActivityDto());
      emit(CreateActivitySuccess(result));
    } catch (e, stack) {
      if (e is PostgrestException) {
        final errorMsg = '''
PostgrestException: Could not create activity.

Message: ${e.message}
Code: ${e.code}
Details: ${e.details}
Hint: ${e.hint}

personId used: ${event.personId}

Stack trace:
$stack
''';
        print(errorMsg);
        emit(CreateActivityError(errorMsg));
      } else if (e.toString().contains('PostgrestException')) {
        final errorMsg = '''
PostgrestException: Could not create activity.

Details:
${e.toString()}

personId used: ${event.personId}

Stack trace:
$stack
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
