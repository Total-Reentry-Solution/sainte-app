import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/ui/components/app_bar.dart';
import 'package:reentry/ui/components/container/box_container.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/modules/activities/bloc/activity_cubit.dart';
import 'package:reentry/ui/modules/activities/bloc/activity_state.dart';
import 'package:reentry/ui/modules/activities/components/activity_component.dart';
import 'package:reentry/ui/modules/activities/create_activity_screen.dart';
import 'package:reentry/ui/modules/goals/bloc/goals_cubit.dart';
import 'package:reentry/ui/modules/goals/bloc/goals_state.dart';
import 'package:reentry/ui/modules/goals/components/goal_item_component.dart';
import '../../components/buttons/app_button.dart';
import 'package:reentry/ui/components/error_component.dart';
import 'package:reentry/ui/components/loading_component.dart';
import 'package:reentry/ui/modules/activities/activity_navigation_screen.dart';

class DailyProgressScreen extends StatelessWidget {
  const DailyProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ActivityCubit()..fetchActivities()),
        BlocProvider(create: (context) => GoalCubit()..fetchGoals()),
      ],
      child: BaseScaffold(
        appBar: const CustomAppbar(
          title: 'Personal Growth',
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activities Section
              BlocBuilder<ActivityCubit, ActivityCubitState>(
                builder: (context, state) {
                  if (state is ActivityLoading) {
                    return const LoadingComponent();
                  }
                  if (state.state is ActivitySuccess) {
                    final completed = state.activity.where((a) => a.progress == 100).toList();
                    final incomplete = state.activity.where((a) => a.progress != 100).toList();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label("Activities"),
                        5.height,
                        if (incomplete.isNotEmpty)
                          BoxContainer(
                            horizontalPadding: 10,
                            radius: 10,
                            child: ListView(
                              shrinkWrap: true,
                              children: incomplete.map((activity) {
                                return ActivityComponent(activity: activity);
                              }).toList(),
                            ),
                          )
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                'No active activities',
                                style: TextStyle(color: AppColors.gray2),
                              ),
                            ),
                          ),
                        10.height,
                        Align(
                          alignment: Alignment.centerRight,
                          child: AppOutlineButton(
                            title: 'Create new activity',
                            onPress: () {
                              context.pushRoute(const CreateActivityScreen());
                            },
                          ),
                        ),
                        20.height,
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
              
              // Goal History Section
              BlocBuilder<GoalCubit, GoalCubitState>(
                builder: (context, goalState) {
                  if (goalState.state is GoalsLoading) {
                    return const LoadingComponent();
                  }
                  if (goalState.state is GoalSuccess) {
                    final completedGoals = goalState.history;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label("Goal History"),
                        5.height,
                        if (completedGoals.isNotEmpty)
                          BoxContainer(
                            horizontalPadding: 10,
                            radius: 10,
                            child: ListView(
                              shrinkWrap: true,
                              children: completedGoals.map((goal) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: GoalItemComponent(goal: goal),
                                );
                              }).toList(),
                            ),
                          )
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 20, bottom: 40),
                              child: Text(
                                'No completed goals yet',
                                style: TextStyle(color: AppColors.gray2),
                              ),
                            ),
                          ),
                        20.height,
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget label(String text) {
  return Builder(builder: (context) {
    return Text(
      text,
      style: context.textTheme.titleSmall?.copyWith(fontSize: 16),
    );
  });
}
