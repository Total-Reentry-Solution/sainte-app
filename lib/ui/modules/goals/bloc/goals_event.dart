import 'package:reentry/data/model/activity_dto.dart';
import 'package:reentry/data/model/goal_dto.dart';

sealed class GoalsAndActivityEvent {}

class CreateGoalEvent extends GoalsAndActivityEvent {
  final String title;
  final int startDate;
  final int endDate;
  final String duration;
  final String personId;
  final String description;

  CreateGoalEvent(this.title, this.startDate, this.endDate, this.duration, this.personId, {required this.description});

  GoalDto toGoalDto() {
    return GoalDto(
      personId: personId,
      goalDescription: description, // Use description for goalDescription
      title: title,
      description: description,
      duration: duration,
      createdAt: DateTime.fromMillisecondsSinceEpoch(startDate),
      endDate: DateTime.fromMillisecondsSinceEpoch(endDate),
      progressPercentage: 0,
      status: 'active',
    );
  }
}



class UpdateGoalEvent extends GoalsAndActivityEvent {
  GoalDto goal;

  UpdateGoalEvent(this.goal);
}
class DeleteGoalEvent extends GoalsAndActivityEvent{
  final String goalId;
  DeleteGoalEvent(this.goalId);
}