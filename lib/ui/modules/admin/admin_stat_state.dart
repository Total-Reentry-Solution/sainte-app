import 'package:reentry/ui/modules/shared/cubit_state.dart';

sealed class AdminStatCubitState {

}
class AdminStatLoading extends AdminStatCubitState{}
class AdminStatError extends AdminStatCubitState{
  final String error;
  AdminStatError(this.error);
}
class AdminStatSuccess extends AdminStatCubitState{
  final AdminStatEntity data;
  AdminStatSuccess(this.data);
}
class AdminStatInitial extends AdminStatCubitState{}
class AdminStatEntity {
  final int totalCitizens;
  final int careTeam;
  final int appointments;
  final int goals;
  final int milestones;
  final int incidents;

  const AdminStatEntity({
    required this.appointments,
    required this.careTeam,
    required this.totalCitizens,
    required this.goals,
    required this.milestones,
    required this.incidents,
  });

  AdminStatEntity copyWith({
    int? totalCitizens,
    int? careTeam,
    int? appointments,
    int? goals,
    int? milestones,
    int? incidents,
  }) {
    return AdminStatEntity(
      totalCitizens: totalCitizens ?? this.totalCitizens,
      careTeam: careTeam ?? this.careTeam,
      appointments: appointments ?? this.appointments,
      goals: goals ?? this.goals,
      milestones: milestones ?? this.milestones,
      incidents: incidents ?? this.incidents,
    );
  }
}
