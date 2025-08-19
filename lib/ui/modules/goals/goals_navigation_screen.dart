import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/ui/modules/goals/bloc/goals_cubit.dart';
import 'goals_screen.dart';

class GoalsNavigationScreen extends StatelessWidget {
  const GoalsNavigationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GoalCubit()..fetchGoals(),
      child: const GoalsScreen(),
    );
  }
} 