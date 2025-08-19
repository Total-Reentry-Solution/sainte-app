import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/ui/modules/activities/bloc/activity_cubit.dart';
import 'activity_screen.dart';

class ActivityNavigationScreen extends StatelessWidget {
  const ActivityNavigationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ActivityCubit()..fetchActivities(),
      child: const ActivityScreen(),
    );
  }
} 