import 'package:reentry/data/model/activity_dto.dart';

sealed class ActivityEvent {}

class CreateActivityEvent extends ActivityEvent {
  final int startDate;
  final int endDate;
  final String title;
  final String goalId;
  final Frequency frequency;
  final String userId; // was personId

  CreateActivityEvent({
    required this.endDate,
    required this.startDate,
    required this.goalId,
    required this.title,
    required this.frequency,
    required this.userId, // was personId
  });

  ActivityDto toActivityDto() {
    return ActivityDto(
      frequency: frequency,
      title: title,
      progress: 0,
      endDate: endDate,
      startDate: startDate,
      timeLine: [],
      userId: userId, // was personId
    );
  }
}

class UpdateActivityEvent extends ActivityEvent{
  final ActivityDto data;
  UpdateActivityEvent(this.data);
}
class DeleteActivityEvent extends ActivityEvent{
  final String id;
  DeleteActivityEvent(this.id);
}